defmodule Hambot.Repo.Migrations.CreateSlackUserPrefs do
  use Ecto.Migration

  def change do
    create table(:slack_user_prefs) do
      add :user_id, :string
      add :team_id, references(:slack_teams)
      add :prefs, :map, default: %{}
      timestamps(type: :utc_datetime)
    end

    create unique_index(:slack_user_prefs, [:user_id])
  end
end
