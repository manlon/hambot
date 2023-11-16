defmodule Hambot.Repo do
  use Ecto.Repo,
    otp_app: :hambot,
    adapter: Ecto.Adapters.Postgres
end
