defmodule Hambot.Puzzle.Result do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Hambot.Repo
  alias Hambot.Slack.Team

  schema "puzzle_results" do
    field :type, :string
    field :puzzle_id, :string
    field :result, :string
    field :user_id, :string
    field :score, :integer
    belongs_to :team, Team

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(result, attrs) do
    result
    |> cast(attrs, [:user_id, :type, :puzzle_id, :result, :score])
    |> validate_required([:user_id, :type, :puzzle_id, :result, :score, :team_id])
    |> assoc_constraint(:team)
  end

  def update_null_teams(%Team{id: id}) do
    query = from d in __MODULE__, where: is_nil(d.team_id)
    Repo.update_all(query, set: [team_id: id])
  end
end
