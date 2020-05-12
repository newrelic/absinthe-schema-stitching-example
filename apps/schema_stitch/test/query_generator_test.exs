# Copyright (c) New Relic Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaStitch.QueryGeneratorTest do
  use ExUnit.Case
  require Logger

  defmodule Schema do
    use Absinthe.Schema

    object :elected_official do
      field(:id, :id)
      field(:name, :string)
      field(:office, :office)
    end

    object :office do
      field(:name, :string)
      field(:phone, :string)

      field(:address, :address) do
        arg(:type, :string)
      end
    end

    object :address do
      field(:street, :string)
      field(:city, :string)
      field(:state, :string)
      field(:zipcode, :string)
    end

    input_object :school_input_object do
      field(:grade_levels, list_of(:integer))
      field(:zipcode, non_null(:string), default_value: "90210")
    end

    input_object :farmers_market_input_object do
      field(:neighborhood, :string)
      field(:day_of_the_week, :string)
    end

    query do
      field :city_name, :string do
        resolve(fn _, _, _ ->
          {:ok, "Portland!"}
        end)
      end

      field(:emergency_phone_number, :string) do
        resolve(&send_resolution/2)
      end

      field(:neighborhoods, list_of(:string)) do
        resolve(&send_resolution/2)
      end

      field :mayor, :elected_official do
        resolve(&send_resolution/2)
      end

      field :city_council, list_of(:elected_official) do
        resolve(&send_resolution/2)
      end

      field :county_name, :string do
        arg(:zipcode, non_null(:string))
        resolve(&send_resolution/2)
      end

      field :food_cart_names, list_of(:string) do
        arg(:neighborhoods, non_null(list_of(:string)))
        resolve(&send_resolution/2)
      end

      field :schools, list_of(:string) do
        arg(:school_input_object, non_null(:school_input_object))
        resolve(&send_resolution/2)
      end

      field :farmers_markets, list_of(:string) do
        arg(:farmers_market_input, non_null(list_of(:farmers_market_input_object)))
        resolve(&send_resolution/2)
      end
    end

    mutation do
      field :update_food_cart_name, :string do
        arg(:new_name, non_null(:string))

        resolve(&send_resolution/2)
      end
    end

    defp send_resolution(_, resolution) do
      send(self(), {:resolution, resolution})
      {:ok, nil}
    end
  end

  describe "field selection" do
    test "accessing a scalar" do
      {generated_query, _used_vars} =
        """
        {
          emergencyPhoneNumber
        }
        """
        |> externalize()

      assert generated_query ==
               """
               query {
                 emergencyPhoneNumber
               }
               """
               |> String.trim()
    end

    test "accessing an object" do
      {generated_query, _used_vars} =
        """
        {
          mayor {
            id
            name
          }
        }
        """
        |> externalize()

      assert generated_query ==
               """
               query {
                 mayor {
                   __typename
                   id
                   name
                 }
               }
               """
               |> String.trim()
    end
  end

  describe "field arguments" do
    test "with scalar argument" do
      {generated_query, _used_vars} =
        """
        {
          countyName(zipcode: "97214")
        }
        """
        |> externalize()

      assert generated_query ==
               """
               query {
                 countyName(zipcode: "97214")
               }
               """
               |> String.trim()
    end

    test "with scalar argument supplied via variable" do
      variables = %{"zipcode" => "97214"}

      {generated_query, used_vars} =
        """
        query($zipcode: String!) {
          countyName(zipcode: $zipcode)
        }
        """
        |> externalize(variables)

      assert generated_query ==
               """
               query($zipcode: String!) {
                 countyName(zipcode: $zipcode)
               }
               """
               |> String.trim()

      assert used_vars == variables
    end

    test "with list of scalars argument" do
      {generated_query, _used_vars} =
        """
        {
          foodCartNames(neighborhoods: [ "Alberta Arts", "Hawthorne" ])
        }
        """
        |> externalize()

      assert generated_query ==
               """
               query {
                 foodCartNames(neighborhoods: [ "Alberta Arts", "Hawthorne" ])
               }
               """
               |> String.trim()
    end

    test "with an inline input object argument" do
      {generated_query, _used_vars} =
        """
        {
          schools(schoolInputObject: { gradeLevels: [ 1, 2 ], zipcode: "97211" })
        }
        """
        |> externalize()

      assert generated_query ==
               """
               query {
                 schools(schoolInputObject: { gradeLevels: [ 1, 2 ], zipcode: "97211" })
               }
               """
               |> String.trim()
    end

    test "with list of inline input objects argument" do
      {generated_query, _used_vars} =
        """
        {
          farmersMarkets(farmersMarketInput: [{ neighborhood: "Sellwood", dayOfTheWeek: "Monday" }, { neighborhood: "Multnomah Village", dayOfTheWeek: "Saturday" }])
        }
        """
        |> externalize()

      assert generated_query ==
               """
               query {
                 farmersMarkets(farmersMarketInput: [ { neighborhood: "Sellwood", dayOfTheWeek: "Monday" }, { neighborhood: "Multnomah Village", dayOfTheWeek: "Saturday" } ])
               }
               """
               |> String.trim()
    end

    test "with input object as variable" do
      variables = %{
        "farmersMarketInputObject" => [
          %{
            "neighborhood" => "Sellwood",
            "dayOfTheWeek" => "Monday"
          },
          %{
            "neighborhood" => "Multnomah Village",
            "dayOfTheWeek" => "Saturday"
          }
        ]
      }

      {generated_query, used_vars} =
        """
         query($farmersMarketInputObject: [FarmersMarketInputObject!]) {
          farmersMarkets(farmersMarketInput: $farmersMarketInputObject)
        }
        """
        |> externalize(variables)

      assert generated_query ==
               """
               query($farmersMarketInputObject: [FarmersMarketInputObject!]) {
                 farmersMarkets(farmersMarketInput: $farmersMarketInputObject)
               }
               """
               |> String.trim()

      assert used_vars == %{
               "farmersMarketInputObject" => [
                 %{day_of_the_week: "Monday", neighborhood: "Sellwood"},
                 %{day_of_the_week: "Saturday", neighborhood: "Multnomah Village"}
               ]
             }
    end

    test "with input object relying on defaults" do
      {generated_query, _used_vars} =
        """
        {
          schools(schoolInputObject: { gradeLevels: [ 1, 2 ] })
        }
        """
        |> externalize()

      assert generated_query ==
               """
               query {
                 schools(schoolInputObject: { gradeLevels: [ 1, 2 ] })
               }
               """
               |> String.trim()
    end
  end

  describe "query fragments" do
    test "with inline fragment" do
      {generated_query, _used_vars} =
        """
        {
          mayor {
            ... on ElectedOfficial {
              name
            }
          }
        }
        """
        |> externalize()

      assert generated_query ==
               """
               query {
                 mayor {
                   __typename
                   ... on ElectedOfficial {
                     name
                   }
                 }
               }
               """
               |> String.trim()
    end

    test "with named fragment" do
      {generated_query, _used_vars} =
        """
        {
          mayor {
            ... on ElectedOfficial {
              name
              ...officeFragment
            }
          }
        }

        fragment officeFragment on ElectedOfficial {
          office {
            name
          }
        }
        """
        |> externalize()

      assert generated_query ==
               """
               query {
                 mayor {
                   __typename
                   ... on ElectedOfficial {
                     name
                     ...officeFragment
                   }
                 }
               }

               fragment officeFragment on ElectedOfficial {
                 office {
                   __typename
                   name
                 }
               }
               """
               |> String.trim()
    end

    test "with nested fragments" do
      {generated_query, _used_vars} =
        """
        {
          mayor {
            ... on ElectedOfficial {
              name
              ...officeFragment
            }
          }
        }

        fragment officeFragment on ElectedOfficial {
          office {
            name
            ...addressFragment
          }
        }

        fragment addressFragment on Office {
          address {
            street
            state
            zipcode
          }
        }
        """
        |> externalize()

      assert generated_query ==
               """
               query {
                 mayor {
                   __typename
                   ... on ElectedOfficial {
                     name
                     ...officeFragment
                   }
                 }
               }

               fragment addressFragment on Office {
                 address {
                   __typename
                   street
                   state
                   zipcode
                 }
               }

               fragment officeFragment on ElectedOfficial {
                 office {
                   __typename
                   name
                   ...addressFragment
                 }
               }
               """
               |> String.trim()
    end

    test "with nested argument" do
      variables = %{"type" => "work"}

      {generated_query, used_vars} =
        """
        query($type: String) {
          mayor {
            ... on ElectedOfficial {
              name
              ...officeFragment
            }
          }
        }

        fragment officeFragment on ElectedOfficial {
          office {
            name
            ...addressFragment
          }
        }

        fragment addressFragment on Office {
          address(type: $type) {
            street
            state
            zipcode
          }
        }
        """
        |> externalize(variables)

      assert generated_query ==
               """
               query($type: String) {
                 mayor {
                   __typename
                   ... on ElectedOfficial {
                     name
                     ...officeFragment
                   }
                 }
               }

               fragment addressFragment on Office {
                 address(type: $type) {
                   __typename
                   street
                   state
                   zipcode
                 }
               }

               fragment officeFragment on ElectedOfficial {
                 office {
                   __typename
                   name
                   ...addressFragment
                 }
               }
               """
               |> String.trim()

      assert variables == used_vars
    end
  end

  test "a mutation" do
    {generated_query, _used_vars} =
      """
      mutation {
        updateFoodCartName(newName: "Matt's BBQ")
      }
      """
      |> externalize()

    assert generated_query ==
             """
             mutation {
               updateFoodCartName(newName: "Matt's BBQ")
             }
             """
             |> String.trim()
  end

  test "query non-forwarded field" do
    {generated_query, _used_vars} =
      """
      {
        cityName
        emergencyPhoneNumber
      }
      """
      |> externalize()

    assert generated_query ==
             """
             query {
               emergencyPhoneNumber
             }
             """
             |> String.trim()
  end

  defp externalize(query_document, variables \\ nil) do
    {:ok, response} = Absinthe.run(query_document, Schema, variables: variables)

    assert response[:errors] == nil
    assert_receive({:resolution, resolution})

    SchemaStitch.QueryGenerator.render(resolution)
  end
end
