defmodule Hambot.Puzzle.Result do
  use Ecto.Schema
  import Ecto.Changeset

  schema "puzzle_results" do
    field :type, :string
    field :puzzle_id, :string
    field :result, :string
    field :user_id, :string
    field :score, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(result, attrs) do
    result
    |> cast(attrs, [:user_id, :type, :puzzle_id, :result, :score])
    |> validate_required([:user_id, :type, :puzzle_id, :result, :score])
  end
end
