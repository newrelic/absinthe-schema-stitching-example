# Copyright (c) New Relic Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

defmodule SoccerTeamApp.Schema do
  use Absinthe.Schema

  # Import the types from the External GraphQL server
  import_sdl(
    path: __DIR__ |> Path.join("../../../events_app/event_types.graphql") |> Path.expand()
  )

  # Define the top-level schema
  #   Note: will be able to use `extend` once that is supported in Absinthe

  import_sdl("""
  type Query {
    players: [Player]
    player(number: Int!): Player

    # Pull in schema stitched fields:
    events: [Event]
    eventByYear(year: Int!): Event
    eventsByName(names: [String!]!): [Event]
    eventsSearch(search: EventSearch!): Event
    eventsFilter(filter: MultiEventSearch!): [Event]
    nextEventLocation: Continent
  }

  type Mutation {
    # Pull in schema stitched mutations:
    createEvent(name: String!, year: Int!, winner: String, hostLocation: String): Event
  }

  type Player {
    name: String
    number: Int
    position: Position
  }

  enum Position {
    GOALKEEPER
    DEFENDER
    MIDFIELDER
    FORWARD
  }
  """)

  def middleware(middleware, field, object) do
    Absinthe.Schema.replace_default(
      middleware,
      {SchemaStitch.Middleware.Default, field.identifier},
      field,
      object
    )
  end

  # Standard resolver hydration:
  #

  def hydrate(%{identifier: :players}, [%{identifier: :query} | _]) do
    {:resolve, &SoccerTeamApp.Resolvers.get_players/3}
  end

  def hydrate(%{identifier: :player}, [%{identifier: :query} | _]) do
    {:resolve, &SoccerTeamApp.Resolvers.get_player/3}
  end

  # Schema Stitched resolver hydration:
  #
  @schema_stitch_config %{url: "http://localhost:3001/graphql"}

  # Query stitch points
  def hydrate(%{identifier: identifier}, [%{identifier: :query} | _])
      when identifier in [
             :events,
             :event_by_year,
             :events_by_name,
             :events_search,
             :events_filter,
             :next_event_location
           ] do
    [
      {:meta, schema_stitch_config: @schema_stitch_config},
      {:resolve, &SchemaStitch.resolver/3}
    ]
  end

  # Mutation stitch points
  def hydrate(%{identifier: identifier}, [%{identifier: :mutation} | _])
      when identifier in [
             :create_event
           ] do
    [
      {:meta, schema_stitch_config: @schema_stitch_config},
      {:resolve, &SchemaStitch.resolver/3}
    ]
  end

  # Interfaces need a resolve type function
  def hydrate(%Absinthe.Blueprint.Schema.InterfaceTypeDefinition{}, _ancestors) do
    {:resolve_type, &SchemaStitch.interface_resolve_type/2}
  end

  def hydrate(_node, _ancestors) do
    []
  end
end
