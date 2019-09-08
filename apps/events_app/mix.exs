# Copyright (c) New Relic Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

defmodule EventsApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :events_app,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {EventsApp.Application, []}
    ]
  end

  defp deps do
    [
      {:absinthe, github: "absinthe-graphql/absinthe", branch: "master", override: true},
      {:absinthe_plug, "~> 1.5.0-alpha.0"},
      {:jason, "~> 1.1.0"},
      {:plug_cowboy, "~> 2.0"}
    ]
  end
end
