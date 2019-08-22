defmodule SoccerTeamApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :soccer_team_app,
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
      mod: {SoccerTeamApp.Application, []}
    ]
  end

  defp deps do
    [
      {:absinthe, github: "binaryseed/absinthe", branch: "hydrate-meta", override: true},
      {:absinthe_plug, "~> 1.5.0-alpha.0"},
      {:jason, "~> 1.1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:schema_stitch, in_umbrella: true}
    ]
  end
end
