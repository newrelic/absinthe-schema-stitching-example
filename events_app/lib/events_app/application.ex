defmodule EventsApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(scheme: :http, plug: EventsApp.Router, options: [port: 3001])
    ]

    opts = [strategy: :one_for_one, name: EventsApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
