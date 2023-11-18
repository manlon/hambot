defmodule Hambot.Repo.Migrations.CreatePuzzleResults do
  use Ecto.Migration

  def change do
    create table(:puzzle_results) do
      add :user_id, :string
      add :type, :string
      add :puzzle_id, :string
      add :result, :string
      add :score, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
