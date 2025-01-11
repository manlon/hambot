defmodule Hambot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Hambot.Release.migrate()

    children = [
      HambotWeb.Telemetry,
      Hambot.Repo,
      {Oban, Application.fetch_env!(:hambot, Oban)},
      {DNSCluster, query: Application.get_env(:hambot, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Hambot.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Hambot.Finch},
      # Start a worker by calling: Hambot.Worker.start_link(arg)
      # {Hambot.Worker, arg},
      {Adbc.Database, driver: :duckdb, process_options: [name: Hambot.DuckDB]},
      {Adbc.Connection, database: Hambot.DuckDB, process_options: [name: Hambot.DuckConn]},
      {Task.Supervisor, name: Hambot.CodebroTaskSupervisor},
      {Hambot.Codebro, []},
      # Start to serve requests, typically the last entry
      HambotWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hambot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HambotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
