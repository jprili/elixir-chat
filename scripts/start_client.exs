System.cmd("epmd", ["-daemon"])

[name, proxy_host | _] = System.argv()
Node.start(
  String.to_atom(name),
  name_domain: :shortnames
)

IO.puts(
  "Started client #{name} pointing to proxy at #{proxy_host}"
)
Chat.Client.connect(
  String.to_atom(proxy_host)
)
