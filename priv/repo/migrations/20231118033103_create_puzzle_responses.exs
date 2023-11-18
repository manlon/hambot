defmodule Hambot.Repo.Migrations.CreatePuzzleResponses do
  use Ecto.Migration

  def change do
    create table(:puzzle_responses) do
      add :user_id, :string
      add :type, :string
      add :response, :string
      add :score, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
