# Copyright (c) New Relic Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

defmodule SoccerTeamApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(scheme: :http, plug: SoccerTeamApp.Router, options: [port: 8080])
    ]

    opts = [strategy: :one_for_one, name: SoccerTeamApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
