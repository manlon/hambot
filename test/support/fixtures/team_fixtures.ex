defmodule Hambot.TeamFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Hambot.Slack.Team` context.
  """

  alias Hambot.Slack.Team

  @doc """
  Generate a domain.
  """
  def team_fixture(attrs \\ %{}) do
    {:ok, team} =
      attrs
      |> Enum.into(%{
        name: "my_team",
        scope: "lots,of,scopes",
        team_id: "T#{:rand.uniform(100_000_000)}",
        access_token: "xox-token-abc123"
      })
      |> then(&Team.changeset(%Team{}, &1))
      |> Hambot.Repo.insert()

    team
  end
end
