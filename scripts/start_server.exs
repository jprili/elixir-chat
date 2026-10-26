System.cmd("epmd", ["-daemon"])

[server_name | _] = System.argv()
Node.start(
  String.to_atom(server_name),
  name_domain: :shortnames
)
Chat.DynamicSupervisor.start_link(nil)
Chat.DynamicSupervisor.start_server()
IO.puts("Server #{inspect node()} started at #{inspect self()}")
Process.sleep(:infinity)
