defmodule SoccerTeamAppTest do
  use ExUnit.Case

  describe "queries:" do
    test "nested queries are forwarded" do
      {:ok, data} =
        request("""
          query {
            events {
              name
              hostLocation
            }
          }
        """)

      event_locations =
        Enum.map(get_in(data, ["data", "events"]), fn event -> event["hostLocation"] end)

      assert length(event_locations) == 7
      assert Enum.member?(event_locations, "SOUTH_AMERICA")
    end

    test "top-level field queries are forwarded" do
      {:ok, data} =
        request("""
          query {
            nextEventLocation
          }
        """)

      assert get_in(data, ["data", "nextEventLocation"]), "ANTARCTICA"
    end

    test "interface queries are forwarded" do
      {:ok, data} =
        request("""
          query {
            events {
              name
              ...on WorldCup {
                roundOfSixteen
              }
              ...on Olympics {
                ageRequirement
              }
            }
          }
        """)

      events = get_in(data, ["data", "events"])

      assert Enum.member?(events, %{
               "name" => "FIFA World Cup",
               "roundOfSixteen" => ["Lots of folks"]
             })

      assert Enum.member?(events, %{"ageRequirement" => 23, "name" => "Summer Olympics"})
    end

    test "queries of non-forwarded fields are successful" do
      {:ok, data} =
        request("""
          query {
            player(number: 17) {
              name
            }
          }
        """)

      assert get_in(data, ["data", "player", "name"]), "Tobin Heath"
    end

    test "queries of forwarded and non-forwarded fields are successful" do
      {:ok, data} =
        request("""
          query {
            nextEventLocation
            player(number: 17) {
              name
            }
          }
        """)

      assert get_in(data, ["data", "nextEventLocation"]), "ANTARCTICA"
      assert get_in(data, ["data", "player", "name"]), "Tobin Heath"
    end
  end

  describe "arguments:" do
    test "inline scalar arguments are forwarded" do
      {:ok, data} =
        request("""
          query {
            eventByYear(year: 2019) {
              year
            }
          }
        """)

      assert get_in(data, ["data", "eventByYear", "year"]) == 2019
    end

    test "variable scalar arguments are forwarded" do
      {:ok, data} =
        request(
          """
            query($chosen_year: Int!) {
              eventByYear(year: $chosen_year) {
                year
              }
            }
          """,
          %{chosen_year: 2019}
        )

      assert get_in(data, ["data", "eventByYear", "year"]) == 2019
    end

    test "a list of scalars as argument is forwarded" do
      {:ok, data} =
        request("""
          query {
            eventsByName(names: ["Name Search Event"]) {
              name
            }
          }
        """)

      assert get_in(data, ["data", "eventsByName"]) == [%{"name" => "Name Search Event"}]
    end

    test "an input object as argument is forwarded" do
      {:ok, data} =
        request("""
          query {
            eventsSearch(search: {year: 2011, host_location: "EUROPE"}) {
              name
              year
              hostLocation
            }
          }
        """)

      assert get_in(data, ["data", "eventsSearch", "name"]) == "Singlesearch Result Event"
    end

    test "a list of input objects as argument is forwarded" do
      {:ok, data} =
        request("""
          query {
            eventsFilter(filter: {events: [{year: 2011, hostLocation: "EUROPE"}, {year: 2015, hostLocation: "AFRICA"}]}) {
              name
            }
          }
        """)

      assert get_in(data, ["data", "eventsFilter"]) == [%{"name" => "Multisearch Result Event"}]
    end
  end

  describe "fragments:" do
    test "inline query fragments are forwarded" do
      {:ok, data} =
        request("""
          query {
            eventByYear(year: 2019) {
              ... on Event {
                hostLocation
              }
            }

          }
        """)

      event = get_in(data, ["data", "eventByYear"])
      assert Map.has_key?(event, "hostLocation")
    end

    test "named query fragments are forwarded" do
      {:ok, data} =
        request("""
          query {
            eventByYear(year: 2019) {
              ... eventFragment
            }

          }

          fragment eventFragment on Event {
            hostLocation
          }
        """)

      event = get_in(data, ["data", "eventByYear"])
      assert Map.has_key?(event, "hostLocation")
    end

    test "nested fragments are forwarded" do
      {:ok, data} =
        request("""
          query {
            eventByYear(year: 2019) {
              ... on Event {
                name
                ... eventFragment
              }
            }

          }

          fragment eventFragment on Event {
            name
            results {
              ... resultsFragment
            }
          }

          fragment resultsFragment on EventResult {
            firstPlace
            secondPlace
          }
        """)

      winner = get_in(data, ["data", "eventByYear", "results", "secondPlace"])
      assert winner == "Netherlands"
    end

    test "nested fragments with nested args are forwarded" do
      {:ok, data} =
        request(
          """
            query($foo: String) {
              eventByYear(year: 2019) {
                ... on Event {
                  name
                  ... eventFragment
                }
              }

            }

            fragment eventFragment on Event {
              name
              ... resultsFragment
            }

            fragment resultsFragment on Event {
              results(test_argument: $foo) {
                firstPlace
                secondPlace
              }
            }
          """,
          %{foo: "foo"}
        )

      winner = get_in(data, ["data", "eventByYear", "results", "secondPlace"])
      assert winner == "Netherlands"
    end
  end

  test "mutations are forwarded" do
    {:ok, data} =
      request(
        """
          mutation($name: String!, $year: Int!) {
            createEvent(name: $name, year: $year) {
              name
              year
              hostLocation
            }
          }
        """,
        %{name: "Test event", year: 2019}
      )

    new_event = get_in(data, ["data", "createEvent", "name"])
    assert new_event == "Test event"
  end

  defp request(query, variables \\ %{}) do
    body = Jason.encode!(%{query: query, variables: variables})
    headers = ["Content-Type": "application/json"]

    {:ok, data} =
      HTTPoison.post!("http://localhost:8080/graphiql", body, headers)
      |> parse()
  end

  defp parse(%{body: response_body}) do
    Jason.decode(response_body)
  end
end
