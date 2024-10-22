defmodule Hambot.Slack.TeamPref do
  use Ecto.Schema
  import Ecto.Changeset
  alias Hambot.Slack.Team

  defmodule Prefs do
    use Ecto.Schema

    embedded_schema do
      field :archive_link_mode, Ecto.Enum, values: [:reply, :thread, :none]
    end

    def changeset(prefs, attrs) do
      prefs
      |> cast(attrs, [:archive_link_mode])
    end
  end

  schema "slack_team_prefs" do
    belongs_to :team, Team
    embeds_one :prefs, Prefs, on_replace: :update

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(team_pref, %{team: team = %Team{}}) do
    changeset(team_pref, %{team_id: team.id})
  end

  def changeset(team_pref, attrs) do
    team_pref
    |> cast(attrs, [:team_id])
    |> validate_required([:team_id])
    |> assoc_constraint(:team)
    |> cast_embed(:prefs)
  end
end
