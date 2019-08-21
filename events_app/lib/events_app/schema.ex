defmodule EventsApp.Schema do
  use Absinthe.Schema

  import_sdl(path: __DIR__ |> Path.join("../../event_types.graphql") |> Path.expand())

  import_sdl("""
  type Query {
    events: [Event]
    eventByYear(year: Int!): Event
    eventsByName(names: [String!]!): [Event]
    eventsSearch(search: EventSearch!): Event
    eventsFilter(filter: MultiEventSearch!): [Event]
    nextEventLocation: Continent
  }

  type Mutation {
    createEvent(name: String!, year: Int! hostLocation: String): Event
  }
  """)

  def hydrate(%{identifier: :event}, _) do
    {:resolve_type, &__MODULE__.resolve_type/2}
  end

  def resolve_type(%{round_of_sixteen: _}, _) do
    :world_cup
  end

  def resolve_type(%{age_requirement: _}, _) do
    :olympics
  end

  def resolve_type(_, _) do
    :generic_event
  end

  def hydrate(%{identifier: :events}, [%{identifier: :query} | _]) do
    {:resolve, &EventsApp.Resolvers.get_events/3}
  end

  def hydrate(%{identifier: :events_by_name}, [%{identifier: :query} | _]) do
    {:resolve, &EventsApp.Resolvers.get_events_by_name/3}
  end

  def hydrate(%{identifier: :events_search}, [%{identifier: :query} | _]) do
    {:resolve, &EventsApp.Resolvers.get_events_search/3}
  end

  def hydrate(%{identifier: :events_filter}, [%{identifier: :query} | _]) do
    {:resolve, &EventsApp.Resolvers.get_events_filter/3}
  end

  def hydrate(%{identifier: :event_by_year}, [%{identifier: :query} | _]) do
    {:resolve, &EventsApp.Resolvers.get_event/3}
  end

  def hydrate(%{identifier: :next_event_location}, [%{identifier: :query} | _]) do
    {:resolve, &EventsApp.Resolvers.next_event_location/3}
  end

  def hydrate(%{identifier: :create_event}, [%{identifier: :mutation} | _]) do
    {:resolve, &EventsApp.Resolvers.create_event/3}
  end

  def hydrate(_node, _ancestors) do
    []
  end
end
