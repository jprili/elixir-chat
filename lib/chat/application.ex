defmodule Chat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @registry Chat.Registry
  @users    Chat.Users

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      { Registry, [name: @registry, keys: :unique] }
      # Starts a worker by calling: Chat.Server.start_link(arg)
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    :ets.new(@users, [:set, :named_table, :public])
    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
