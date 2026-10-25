defmodule Chat.Proxy do
  use GenServer
  require Logger

  def start(host, listen_port \\ 6666) do
    GenServer.start(__MODULE__, {host, listen_port})
  end

  @impl true
  def init({host, port}) do
    opts = [:binary, packet: :line, active: true, reuseaddr: true]
    {:ok, listen} = :gen_tcp.listen(port, opts)
    if Node.connect(host) do
      log(listen, "connected to #{inspect host}")
    end
    send(self(), :accept)
    {:ok, listen}
  end

  @impl true
  def handle_info(:accept, listen) do
    {:ok, socket} = :gen_tcp.accept(listen)
    log(socket, "accepted connection")
    {:ok, pid} = Chat.Proxy.Worker.start(socket)
    # handoff socket to worker
    :gen_tcp.controlling_process(socket, pid)
    send(self(), :accept)
    {:noreply, listen}
  end

  defp log(socket, msg) do
    Logger.info("#{inspect self()}: #{msg} #{inspect socket}")
  end
end


