# Copyright (c) New Relic Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

defmodule EventsApp.Router do
  use Plug.Router

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json, Absinthe.Plug.Parser],
    pass: ["*/*"],
    json_decoder: Jason

  plug :match
  plug :dispatch

  match "/graphql",
    to: Absinthe.Plug,
    init_opts: [schema: EventsApp.Schema]

  match "/graphiql",
    to: Absinthe.Plug.GraphiQL,
    init_opts: [schema: EventsApp.Schema]

  match _ do
    send_resp(conn, 404, "Oops!")
  end
end