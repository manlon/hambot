defmodule Hambot.Slack.Team do
  use Ecto.Schema
  import Ecto.Changeset
  alias Hambot.Repo
  alias Hambot.Archive.Domain
  alias Hambot.Puzzle.Result
  alias Hambot.Slack.TeamPref

  schema "slack_teams" do
    field :name, :string
    field :scope, :string
    field :team_id, :string
    field :access_token, :string

    timestamps(type: :utc_datetime)

    has_many :domains, Hambot.Archive.Domain
    has_one :prefs, Hambot.Slack.TeamPref
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :team_id, :access_token, :scope])
    |> cast_assoc(:prefs, with: &TeamPref.changeset/2)
    |> validate_required([:name, :team_id, :access_token, :scope])
  end

  def add_team_auth(team_params = %{team_id: team_id}) do
    {:ok, team} =
      case find_by_team_id(team_id) do
        nil ->
          changeset(%__MODULE__{}, team_params)
          |> Repo.insert()

        team ->
          changeset(team, team_params)
          |> Repo.update()
      end

    # upgrade assocs for existing records if we can
    if Application.get_env(:hambot, :slack)[:upgrade_team_id] == team_id do
      Domain.update_null_teams(team)
      Result.update_null_teams(team)
    end

    team
  end

  def find_by_team_id(team_id) do
    Repo.get_by(__MODULE__, team_id: team_id)
    |> with_prefs
  end

  def find_by_team_id!(team_id) do
    case find_by_team_id(team_id) do
      nil ->
        raise "No team found with team_id: #{team_id}"

      team ->
        team
    end
  end

  def with_prefs(team) do
    team = Repo.preload(team, :prefs)

    case team.prefs do
      nil ->
        TeamPref.changeset(Ecto.build_assoc(team, :prefs), %{}) |> Repo.insert()
        Repo.preload(team, :prefs, force: true)

      _ ->
        team
    end
  end

  def find_by_team_id_with_domains(team_id) do
    find_by_team_id!(team_id)
    |> Repo.preload(:domains)
  end

  def with_domains(team = %__MODULE__{}) do
    Repo.preload(team, :domains)
  end

  def get_access_token(team_id) do
    find_by_team_id!(team_id).access_token
  end

  def add_domain(team = %__MODULE__{}, domain) do
    existing? =
      team
      |> Repo.preload(:domains)
      |> then(& &1.domains)
      |> Enum.any?(&(&1.domain == domain))

    if existing? do
      {:error, "domain is already added"}
    else
      Domain.add_domain(team, domain)
    end
  end

  def update_pref(team, key, val) do
    team.prefs
    |> TeamPref.update_pref(key, val)
  end
end
