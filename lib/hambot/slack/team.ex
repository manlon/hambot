defmodule Hambot.Slack.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "slack_teams" do
    field :name, :string
    field :scope, :string
    field :team_id, :string
    field :access_token, :string

    timestamps(type: :utc_datetime)

    has_many :domains, Hambot.Archive.Domain
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :team_id, :access_token, :scope])
    |> validate_required([:name, :team_id, :access_token, :scope])
  end
end
