defmodule Hambot.Slack.Team do
  use Ecto.Schema
  import Ecto.Changeset
  alias Hambot.Repo
  alias Hambot.Archive.Domain
  alias Hambot.Puzzle.Result

  schema "slack_teams" do
    field :name, :string
    field :scope, :string
    field :team_id, :string
    field :access_token, :string

    timestamps(type: :utc_datetime)

    has_many :domains, Hambot.Archive.Domain
    has_many :prefs, Hambot.Slack.TeamPref
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :team_id, :access_token, :scope])
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
  end

  def find_by_team_id!(team_id) do
    case find_by_team_id(team_id) do
      nil ->
        raise "No team found with team_id: #{team_id}"

      team ->
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
end
