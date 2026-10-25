defmodule Chat.DynamicSupervisor do
  use DynamicSupervisor
  @name  {:global, __MODULE__}

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, nil, name: @name)
  end

  def start_server() do
    DynamicSupervisor.start_child(@name, Chat.Server)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
