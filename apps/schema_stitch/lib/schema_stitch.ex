# Copyright (c) New Relic Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaStitch do
  def middleware(middleware, field, object) do
    Absinthe.Schema.replace_default(
      middleware,
      {SchemaStitch.DefaultMiddleware, field.identifier},
      field,
      object
    )
  end

  def resolver(
        _source,
        _args,
        %{
          schema: schema,
          definition: %{
            name: name,
            schema_node: %{__private__: private, type: type}
          }
        } = resolution
      ) do
    %{url: url} = get_in(private, [:meta, :schema_stitch_config])
    {query, variables} = SchemaStitch.QueryGenerator.render(resolution)

    with {:ok, results} <- SchemaStitch.GraphQLClient.request(url, query, variables) do
      {:ok, SchemaStitch.ExternalField.tag_or_extract_value(schema, type, name, results)}
    end
  end

  def interface_resolve_type({:external, %{"__typename" => typename}}, _) do
    typename
    |> Absinthe.Adapter.LanguageConventions.to_internal_name(nil)
    |> String.to_atom()
  end
end
