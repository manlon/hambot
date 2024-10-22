defmodule Hambot.Repo.Migrations.CreateSlackTeamPrefs do
  use Ecto.Migration

  def change do
    create table(:slack_team_prefs) do
      add :team_id, references(:slack_teams)
      add :prefs, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:slack_team_prefs, [:team_id])
  end
end
