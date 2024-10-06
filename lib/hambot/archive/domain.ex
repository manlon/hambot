defmodule Hambot.Archive.Domain do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias Hambot.Repo
  alias Hambot.Slack.Team

  @domain_regex ~r/^([a-z0-9-]+\.)+[a-z]{2,}$/

  schema "archive_domains" do
    field :domain, :string
    belongs_to :team, Team

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(domain, attrs) do
    domain
    |> cast(attrs, [:domain])
    |> validate_required([:domain, :team_id])
    |> validate_format(:domain, @domain_regex)
    |> assoc_constraint(:team)
  end

  def err_message(cs) do
    if cs.valid? do
      nil
    else
      [{field, {msg, _}} | _] = cs.errors
      "#{field} #{msg}"
    end
  end

  def list_domains() do
    Repo.all(__MODULE__)
    |> Enum.map(& &1.domain)
  end

  def list_domains(team_id) do
    Team.find_by_team_id_with_domains(team_id).domains
    |> Enum.map(& &1.domain)
  end


  def add_domain(team_id, domain) do
    changeset(%__MODULE__{}, %{team_id: team_id, domain: domain})
    |> Repo.insert()
  end

  def update_null_teams(%Team{id: id}) do
    query = from d in __MODULE__, where: is_nil(d.team_id)
    Repo.update_all(query, set: [team_id: id])
  end
end
