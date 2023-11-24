defmodule Hambot.Archive.Server do
  use GenServer
  alias Hambot.Archive.Domain
  require Logger

  def is_archive?(domain) when is_binary(domain) do
    GenServer.call(__MODULE__, {:is_archive?, domain})
  end

  def add_domain(domain) when is_binary(domain) do
    GenServer.call(__MODULE__, {:add_domain, domain})
  end

  def list_domains() do
    GenServer.call(__MODULE__, :list_domains)
  end

  def reinitialize() do
    GenServer.cast(__MODULE__, :initialize_state)
  end

  def start_link(_ \\ nil) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, initialize_state()}
  end

  def initialize_state() do
    Domain.list_domains() |> MapSet.new()
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
    {:reply, is_archive?(state, domain), state}
  end

  def handle_call(:list_domains, _from, state) do
    {:reply, Enum.to_list(state), state}
  end

  def handle_cast(:initialize_state, _state) do
    {:noreply, initialize_state()}
  end

  defp is_archive?(state, domain) do
    if domain in state do
      true
    else
      case String.split(domain, ".", parts: 2) do
        [_first, rest] ->
          is_archive?(state, rest)

        _ ->
          false
      end
    end
  end
end
