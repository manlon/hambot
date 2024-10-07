defmodule Hambot.DomainFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Hambot.Archive.Domain` context.
  """

  alias Hambot.Archive.Domain

  @doc """
  Generate a domain.
  """
  def domain_fixture(team, attrs \\ %{}) do
    {:ok, domain} =
      attrs
      |> Enum.into(%{
        domain: "exmaple.com",
        team_id: team.id
      })
      |> then(&Domain.changeset(%Domain{}, &1))
      |> Hambot.Repo.insert()

    domain
  end
end
