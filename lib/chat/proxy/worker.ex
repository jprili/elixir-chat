defmodule Chat.Proxy.Worker do
  use GenServer
  require Logger

  @server { :global, Chat.Server }
  @groups Chat.Proxy.Worker.Groups

  def start(socket) do
    GenServer.start(
      __MODULE__, {socket, nil})
  end

  defp parse(tokens) do
    case tokens do
      ["/" <> command | rest] -> 
        [command |> String.first |> String.downcase | rest]
      _ -> tokens
    end
  end

  defp validate(
    [command | _rest] = tokens, {nick, table}, next
  ) do
    if nick != nil || command in ["l", "n"] do
      next.(tokens, {nick, table})
    else
      { "Nickname not set", nick }
    end
  end

  defp valid_name_length?(name) do
    String.length(name) >= 2 and String.length(name) <= 20
  end

  defp nick_free?(nick) do
    GenServer.call(@server, { :nick_free?, nick })
  end

  defp valid_nick?(name) do
    valid_name_length?(name) 
      and String.match?(name, ~r/^[a-z][_a-z0-9]*$/)
  end

  defp group_name?(name) do
    valid_name_length?(name) 
      and String.match?(name, ~r/^[A-Z][_a-z0-9]*$/)
  end

  defp fetch_users_in_group(table, group) do
    case :ets.lookup(table, group) do
      [{_, users}] -> users
      _ -> []
    end
  end

  defp parse_names(names, table, acc \\ []) do
    case names do
      [name | rest] ->
        cond do 
          group_name?(name) ->
            users = fetch_users_in_group(table, name) 
              |> Enum.filter(&(&1 not in acc))
            parse_names(rest, table, users ++ acc)
          not valid_nick?(name) ->
            parse_names(rest, table, acc)
          true ->
            parse_names(rest, table, [name | acc])
        end
      [] -> acc |> Enum.sort |> Enum.dedup
    end
  end

  defp route(["b" | message], {nick, table}) do
    GenServer.cast(@server, 
      { 
        :msg, 
        self(),
        fetch_users_in_group(table, :default),
        Enum.join(message, " ") 
      }
    )
    {"Sent", nick}
  end

  defp route(["d", names | _], {nick, table}) do
    :ets.insert(table, 
      { :default, parse_names(String.split(names, ","), table) }
    )
    {"Default group set", nick}
  end

  defp route(["g", group_name, names | _], {nick, table}) do
    if group_name?(group_name) do
      :ets.insert(table, 
        { 
          group_name, 
          parse_names(String.split(names, ","), table) 
        }
      )
      {"Group set", nick}
    else
      {"Invalid group name", nick}
    end
  end

  defp route(["l" | _], {nick, _table}) do
    result = GenServer.call(@server, :list_current_users)
    {Enum.join(result, "\n"), nick}
  end

  defp route(["m", names | message], {nick, table}) do
    GenServer.cast(@server, 
      { 
        :msg, 
        self(),
        parse_names(String.split(names, ","), table),
        Enum.join(message, " ") 
      }
    )
    {"Message to #{names} sent", nick}
  end

  defp route(["n", new_nick], {nick, _table}) do
    cond do
      not valid_nick?(new_nick) -> 
        {"Nickname invalid", nick}
      not nick_free?(new_nick) ->
        {"Nickname already in use", nick}
      true -> 
        GenServer.cast(@server, 
          { :set_nick, self(), nick, new_nick }
        )
        { "Nickname set", new_nick }
    end
  end

  defp route(_, {nick, _table}) do
    {"Invalid command", nick}
  end

  @impl GenServer
  def init({socket, nil}) do
    table = :ets.new(@groups, [:set, :private])
    {:ok, {socket, nil, table}}
  end

  @impl GenServer
  def handle_info({:tcp, socket, data}, {socket, nick, table}) do
    log(socket, "received #{inspect data}")
    :inet.setopts(socket, active: :once)
    {result, nick} = data 
      |> String.trim
      |> String.split(" ") 
      |> parse 
      |> validate({nick, table}, &route/2)
    :gen_tcp.send(socket, result <> "\n")
    {:noreply, {socket, nick, table}}
  end

  @impl GenServer
  def handle_info({:tcp_closed, socket}, {socket, nick, table}) do
    :gen_tcp.close(socket)
    log(socket, "closed connection")
    {:stop, :normal, {socket, nick, table}}
  end

  @impl GenServer
  def handle_cast({:sent, nick, msg}, {socket, _, _} = s) do
    :inet.setopts(socket, active: :once)
    :gen_tcp.send(socket, "#{nick}: #{msg}\n")
    {:noreply, s}
  end

  @impl GenServer
  def terminate(_reason, {_, nick, table}) do
    :ets.delete(table)
    GenServer.cast(@server, { :remove_nick, self(), nick })
  end

  defp log(socket, msg) do
    Logger.info("#{inspect self()}: #{msg} #{inspect socket}")
  end
end
