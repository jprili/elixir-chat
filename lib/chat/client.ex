defmodule Chat.Client do
  def connect(host, port \\ 6666) do
    opts = [active: :false, packet: :line]
    {:ok, socket} = :gen_tcp.connect(host, port, opts)
    spawn_link(fn -> loop_recv(socket) end)
    loop_send(socket)
  end

  defp loop_recv(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} -> 
        IO.write(data) 
        loop_recv(socket)
      {:error, _} ->
        :gen_tcp.close(socket)
        # exit the process so
        # no zombies
        System.halt(0) 
    end
  end

  defp loop_send(socket) do
    case IO.gets("") do
      :eof ->
        :gen_tcp.close(socket)
      line -> 
        :gen_tcp.send(socket, line)
        loop_send(socket)
    end
  end
end

