defmodule Hambot.Repo.Migrations.CreateArchiveDomains do
  use Ecto.Migration

  def change do
    create table(:archive_domains) do
      add :domain, :string

      timestamps(type: :utc_datetime)
    end
  end
end
