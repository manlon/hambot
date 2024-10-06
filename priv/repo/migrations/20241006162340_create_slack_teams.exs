defmodule Hambot.Repo.Migrations.CreateSlackTeams do
  use Ecto.Migration

  def change do
    create table(:slack_teams) do
      add :name, :string
      add :team_id, :string
      add :access_token, :string
      add :scope, :string

      timestamps(type: :utc_datetime)
    end

    alter table(:archive_domains) do
      add :team_id, references(:slack_teams)
    end
  end
end
