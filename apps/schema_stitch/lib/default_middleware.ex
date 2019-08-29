# Copyright (c) New Relic Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaStitch.DefaultMiddleware do
  @moduledoc """
  This is a modified version of the default MapGet middleware
  that can also handle responses from external graphql services.
  """

  @behaviour Absinthe.Middleware

  @impl true
  def call(%{source: {:external, _source}} = resolution, _key) do
    SchemaStitch.ExternalField.tag_or_extract_resolution_field(resolution)
  end

  @impl true
  def call(resolution, key) do
    Absinthe.Middleware.MapGet.call(resolution, key)
  end
end
