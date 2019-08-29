# Copyright (c) New Relic Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

defmodule SoccerTeamApp.Resolvers do
  @player13 %{name: "Alex Morgan", number: 13, position: :forward}
  @player15 %{name: "Megan Rapinoe", number: 15, position: :midfielder}
  @player17 %{name: "Tobin Heath", number: 17, position: :midfielder}
  @players [@player13, @player15, @player17]

  def get_players(_, _, _) do
    {:ok, @players}
  end

  def get_player(_, %{number: 13}, _) do
    {:ok, @player13}
  end

  def get_player(_, %{number: 15}, _) do
    {:ok, @player15}
  end

  def get_player(_, %{number: 17}, _) do
    {:ok, @player17}
  end

  def get_player(_, _, _) do
    {:ok, nil}
  end
end
