# Copyright (c) New Relic Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaStitch.MixProject do
  use Mix.Project

  def project do
    [
      app: :schema_stitch,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:absinthe, github: "binaryseed/absinthe", branch: "hydrate-meta", override: true},
      {:absinthe_plug, "~> 1.5.0-alpha.0"},
      {:jason, "~> 1.1.0"},
      {:httpoison, "~> 1.0"}
    ]
  end
end
