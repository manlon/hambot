defmodule Hambot.Puzzle.Response do
  use Ecto.Schema
  import Ecto.Changeset

  schema "puzzle_responses" do
    field :type, :string
    field :response, :string
    field :user_id, :string
    field :score, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(response, attrs) do
    response
    |> cast(attrs, [:user_id, :type, :response, :score])
    |> validate_required([:user_id, :type, :response, :score])
  end
end
