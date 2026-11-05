# Chat

A small, concurrent chat system in Elixir.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `chat` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:chat, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/chat>.

# Operation

There are three scripts in the `scripts/`
directory. To run each, do 

```bash
mix run scripts/start_server.exs [server_name]
mix run scripts/start_proxy.exs  [proxy_name]  [server_name]
mix run scripts/start_client.exs [client_name] [proxy_host]
```

Client commands:

These commands are available without setting
the nickname.
```
/l - list all server nicknames
/n [nickname] - set nickname
```

These are available after setting the nickname
```
/g [group_name] [user/group list] - assign users to a group
/d [user/group list] - assign to a default group
/b [message] - broadcast message to default group
/m [user/group list] [msg] - send message to recipients.
```

Valid user nicknames start with a lowercase letter and
can be followed by _, lowercase letters, and digits.

Valid group names start with an uppercase letter and
can be followed by _, lowercase letters, and digits.

Lists can be composed of nicknames and groups simultaneously.

Example:
```
/g Children bart,lisa,maggie
/m Children,marge,ned hello everyone
```

In `lisa`'s client, it would show:
```
homer: hello everyone.
```
