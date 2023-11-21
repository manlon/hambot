defmodule Hambot.Archive.Domain do
  use Ecto.Schema
  import Ecto.Changeset
  alias Hambot.Repo
  alias Hambot.Archive.Domain

  @domain_regex ~r/^([a-z0-9-]+\.)+[a-z]{2,}$/

  schema "archive_domains" do
    field :domain, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(domain, attrs) do
    domain
    |> cast(attrs, [:domain])
    |> validate_required([:domain])
    |> validate_format(:domain, @domain_regex)
  end

  def err_message(cs) do
    if cs.valid? do
      nil
    else
      [{field, {msg, _}} | _] = cs.errors
      "#{field} #{msg}"
    end
  end

  def list_domains do
    Repo.all(Domain)
    |> Enum.map(& &1.domain)
  end

  def add_domain(domain) do
    changeset(%Domain{}, %{domain: domain})
    |> Repo.insert()
  end
end
