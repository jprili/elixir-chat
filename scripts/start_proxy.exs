System.cmd("epmd", ["-daemon"])

[name, server_name | _] = System.argv()
Node.start(
  String.to_atom(name),
  name_domain: :shortnames
)

Chat.Proxy.start(
  String.to_atom(server_name)
)

IO.write("Proxy #{name} to #{server_name} ")
IO.puts("started at #{inspect self()}")
Process.sleep(:infinity)
