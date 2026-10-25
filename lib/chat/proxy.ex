defmodule Chat.Proxy do
  use GenServer
  require Logger

  def start(host, port \\ 6666) do
    GenServer.start(__MODULE__, {host, port})
  end

  @impl true
  def init({host, port}) do
    opts = [:binary, packet: :line, active: true, reuseaddr: true]
    {:ok, listen} = :gen_tcp.listen(port, opts)
    send(self(), :accept)
    {:ok, {host, listen}}
  end

  @impl true
  def handle_info(:accept, {host, listen}) do
    {:ok, socket} = :gen_tcp.accept(listen)
    log(socket, "accepted connection")
    {:ok, pid}    = Chat.Proxy.Worker.start(host, socket)
    # handoff socket to worker
    :gen_tcp.controlling_process(socket, pid)
    send(self(), :accept)
    {:noreply, {host, listen}}
  end

  defp log(socket, msg) do
    Logger.info("#{inspect self()}: #{msg} #{inspect socket}")
  end
end


