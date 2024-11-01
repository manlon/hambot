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
    |> cast(attrs, [:domain, :team_id])
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

  def list_domains(team = %Team{}) do
    Team.with_domains(team).domains
    |> Enum.map(& &1.domain)
    |> Enum.sort()
  end

  def add_domain(%Team{id: id}, domain) do
    changeset(%__MODULE__{}, %{team_id: id, domain: domain})
    |> Repo.insert()
  end

  def update_null_teams(%Team{id: id}) do
    query = from d in __MODULE__, where: is_nil(d.team_id)
    Repo.update_all(query, set: [team_id: id])
  end
end
