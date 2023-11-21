defmodule Hambot.Archive.Server do
  use GenServer
  alias Hambot.Archive.Domain

  def is_archive?(domain) when is_binary(domain) do
    GenServer.call(__MODULE__, {:is_archive?, domain})
  end

  def add_domain(domain) when is_binary(domain) do
    GenServer.call(__MODULE__, {:add_domain, domain})
  end

  def start_link(_ \\ nil) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    domains =
      Domain.list_domains() |> MapSet.new()

    {:ok, domains}
  end

  def handle_call({:add_domain, domain}, _from, state) when is_binary(domain) do
    if domain in state do
      {:reply, :ok, state}
    else
      case Domain.add_domain(domain) do
        {:ok, _} ->
          {:reply, :ok, MapSet.put(state, domain)}

        {:error, cs} ->
          {:reply, {:error, Domain.err_message(cs)}, state}
      end
    end
  end

  def handle_call({:is_archive?, domain}, _from, state) when is_binary(domain) do
    {:reply, domain in state, state}
  end
end
