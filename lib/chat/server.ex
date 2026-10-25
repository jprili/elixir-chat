defmodule Chat.Server do
  use GenServer
  require Logger

  @users Chat.Users
  @name { :global, __MODULE__ }

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: @name)
  end

  defp get_nick(pid) do
    case :ets.match_object(@users, {:_, pid}) do
      [{nick, _}] -> nick
      _ -> nil
    end
  end

  @impl true
  def init(nil) do
    for {_, _, node} <- :ets.tab2list(@users) do
      Node.connect(node)
    end
    {:ok, nil}
  end

  @impl true
  def handle_call({ :nick_free?, nick } = msg, {pid, _}, nil) do
    log("#{inspect msg} #{inspect pid}")
    {:reply, [] == :ets.lookup(@users, nick), nil}
  end 

  @impl true
  def handle_call(:list_current_users = msg, {pid, _}, nil) do
    log("#{inspect msg} #{inspect pid}")
    result = 
      :ets.tab2list(@users) |> Enum.map(fn {n, _} -> n end)
    {:reply, result, nil}
  end 

  @impl true
  def handle_cast(
    {:set_nick, from, from_node, nick, new_nick} = msg, 
    nil
  ) do
    log("#{inspect msg}")
    if nick != nil do
      :ets.delete(@users, nick)
    end
    :ets.insert(@users, {new_nick, from, from_node})
    {:noreply,  nil}
  end 

  @impl true
  def handle_cast({:remove_nick, pid, nick} = msg, nil) do
    log("#{inspect msg}")
    [{^nick, ^pid, _}] = :ets.match_object(@users, {nick, pid, :_})
    :ets.delete(@users, nick)
    {:noreply, nil}
  end 

  @impl true
  def handle_cast({ :msg, from, names, body } = msg, nil) do
    log("#{inspect msg}")
    Enum.each(names, 
      fn name -> 
        case :ets.lookup(@users, name) do
          [{_, pid}] when pid != from -> 
            GenServer.cast(
                pid,
                { :sent, get_nick(from), body }
              )
          _ -> nil 
        end
      end
    )
    {:noreply, nil}
  end 
  
  defp log(msg) do
    Logger.info("#{inspect self()}: #{msg}")
  end
end
