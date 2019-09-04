# Absinthe Schema Stitching Example

### Support Statement

**This is an unsupported example. This project is provided AS-IS WITHOUT
WARRANTY OR SUPPORT.**

This repository contains three example Absinthe-GraphQL applications. The primary Soccer Team application and the secondary Events application are both independent GraphQL APIs. The Schema Stitch application demonstrates the process of stitching the Events application GraphQL schema into the main Soccer Team application GraphQL schema. Through this automated schema-stitching process, schemas from any downstream GraphQL application can be seamlessly integrated into upstream schemas with little manual interaction.

## Code Example

The main Soccer Team schema originally contains two fields: 
```graphql
  player(number: Int!): Player
  players: [Player]
```

After the Events application schema is stitched in, the Soccer Team schema contains six additional fields:
```graphql
  events: [Event]
  eventByYear(year: Int!): Event
  eventsByName(names: [String!]!): [Event]
  eventsSearch(search: EventSearch!): Event
  eventsFilter(filter: MultiEventSearch!): [Event]
  nextEventLocation: Continent
```

The resulting Soccer Team schema with stitched in Events fields will contain all eight fields: 

```graphql
  player(number: Int!): Player
  players: [Player]
  events: [Event]
  eventByYear(year: Int!): Event
  eventsByName(names: [String!]!): [Event]
  eventsSearch(search: EventSearch!): Event
  eventsFilter(filter: MultiEventSearch!): [Event]
  nextEventLocation: Continent
```
## Requirements

* `elixir: "~> 1.8"`
* `absinthe: "1.5"`

## Building and Schema Stitching

1. Clone this repository and install the necessary dependencies by running `mix deps.get`. 
2. Serve all three applications from the main `Schema-Stitching` application directory by running `iex -S mix`. The Events application will be served at `http://localhost:3001/graphql` and the Soccer Team application at `http://localhost:8080/graphql`.
4. During the resolution of a query to the Soccer Team application, fields belonging to the Event schema will be resolved by generating a GraphQL request to the Events app and transforming its response within the Soccer Team app.
3. Events will then be queryable from the Soccer Team application schema at `http://localhost:8080/graphql`.

## Testing

Run the following mix task from the main project directory:
```
mix test
```

## License

The Absinthe-GraphQL Schema Stitching Example is licensed under the Apache 2.0 License.
