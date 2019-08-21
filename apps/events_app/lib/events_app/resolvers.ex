defmodule EventsApp.Resolvers do
  @event_2019 %{
    name: "FIFA World Cup",
    year: 2019,
    results: %{first_place: "USA", second_place: "Netherlands", third_place: "Sweden"},
    host_location: :europe,
    round_of_sixteen: ["Lots of folks"]
  }
  @event_2016 %{
    name: "Summer Olympics",
    year: 2016,
    results: %{first_place: "Germany", second_place: "Sweden", third_place: "Canada"},
    host_location: :south_america,
    age_requirement: 23
  }
  @event_2015 %{
    name: "FIFA World Cup",
    year: 2015,
    results: %{first_place: "USA", second_place: "Japan", third_place: "England"},
    host_location: :north_america,
    round_of_sixteen: ["Lots of folks"]
  }
  @event_2011 %{
    name: "FIFA World Cup",
    year: 2011,
    results: %{first_place: "Japan", second_place: "USA", third_place: "Sweden"},
    host_location: :europe,
    round_of_sixteen: ["Lots of folks"]
  }
  @name_search_event %{name: "Name Search Event", year: 2011, host_location: :europe}
  @filter_event %{name: "Multisearch Result Event", year: 2015, host_location: :africa}
  @single_search_event %{name: "Singlesearch Result Event", year: 2016, host_location: :asia}

  @events [
    @event_2019,
    @event_2015,
    @event_2011,
    @event_2016,
    @name_search_event,
    @filter_event,
    @single_search_event
  ]

  def get_events_by_name(_, _, _) do
    {:ok, @name_search_event}
  end

  def get_events_search(_, _, _) do
    {:ok, @single_search_event}
  end

  def get_events_filter(_, _, _) do
    {:ok, [@filter_event]}
  end

  def get_event(_, %{year: 2019}, _) do
    {:ok, @event_2019}
  end

  def get_event(_, %{year: 2015}, _) do
    {:ok, @event_2015}
  end

  def get_event(_, %{year: 2011}, _) do
    {:ok, @event_2011}
  end

  def get_events(_, _, _) do
    {:ok, @events}
  end

  def next_event_location(_, _, _) do
    {:ok, :antarctica}
  end

  def create_event(_, args, _) do
    {:ok,
     %{
       name: args[:name],
       year: args[:year],
       winner: args[:winner],
       host_location: args[:host_location]
     }}
  end
end
