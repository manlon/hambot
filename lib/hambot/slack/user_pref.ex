defmodule Hambot.Slack.UserPref do
  use Ecto.Schema
  import Ecto.Changeset
  alias Hambot.Slack.Team

  defmodule Prefs do
    use Ecto.Schema

    embedded_schema do
    end

    def changeset(prefs, attrs) do
      prefs
      |> cast(attrs, [])
    end
  end

  schema "slack_user_prefs" do
    belongs_to :team, Team
    field :user_id, :string
    embeds_one :prefs, Prefs, on_replace: :update

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_pref, attrs) do
    user_pref
    |> cast(attrs, [:user_id, :team_id, :prefs])
    |> validate_required([:user_id, :team_id])
  end
end
