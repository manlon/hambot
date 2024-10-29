defmodule Hambot.Slack.TeamPref do
  use Ecto.Schema
  import Ecto.Changeset
  alias Hambot.Slack.Team
  alias Hambot.Repo

  defmodule Prefs do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field :archive_link_mode, Ecto.Enum,
        values: [:reply, :thread, :context, :none],
        default: :thread
    end

    def changeset(prefs, attrs) do
      prefs
      |> cast(attrs, [:archive_link_mode])
    end

    # @thefields __MODULE__.__schema__(:fields)
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

  def get(_tp = %__MODULE__{prefs: prefs}, key) do
    get_in(prefs, [Access.key!(key)])
  end

  @pref_fields Prefs.__struct__()
               |> Map.from_struct()
               |> Enum.map(fn {k, v} -> {to_string(k), v} end)
               |> Enum.into(%{})

  def update_pref(uprefs = %__MODULE__{}, key, val) when is_binary(key) do
    cs =
      uprefs
      |> changeset(%{prefs: %{key => val}})

    cs =
      if cs.valid? and !Map.has_key?(@pref_fields, key) do
        Ecto.Changeset.add_error(cs, :key, "unknown: #{key}")
      else
        cs
      end

    Repo.update(cs)
  end
end
