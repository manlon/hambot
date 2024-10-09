defmodule Hambot.Codebro do
  use GenServer
  require Logger

  defstruct brain_file: nil, graph: %{}, tasks: [], learn: true

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Send codebro a message
  def send_chat(message) do
    GenServer.call(__MODULE__, {:message, message})
  end

  # Server (callbacks)

  @impl true
  def init(opts \\ []) do
    state = %__MODULE__{
      brain_file:
        Keyword.get(opts, :brain_file, Application.get_env(:hambot, :codebro)[:brain_file]),
      graph: %{},
      tasks: %{},
      learn: Keyword.get(opts, :learn, true)
    }

    state =
      if state.brain_file && File.exists?(state.brain_file) do
        Logger.debug("Loading codebro brain from #{state.brain_file}")

        {_updated?, graph} =
          file_sentence_stream(state.brain_file)
          |> update_graph_from_sentences(state.graph)

        Map.put(state, :graph, graph)
      else
        state
      end

    {:ok, state}
  end

  @impl true
  def handle_call({:message, message}, _from, state = %__MODULE__{graph: graph}) do
    sentences = string_to_sentence_stream(message)
    words = List.flatten(Enum.to_list(sentences))

    seeds =
      if length(words) > 2 do
        Enum.filter(words, fn w -> Map.has_key?(graph, {:start, w}) end)
      else
        []
      end

    reply = generate_markov_text(graph, Enum.random([{:start, :start} | seeds]))

    state =
      if state.learn do
        {new_sentences, graph} =
          Enum.reduce(sentences, {[], graph}, fn sentence, {acc, graph} ->
            {updated?, graph} = update_graph_from_sentences([sentence], graph)
            acc = if updated?, do: [sentence | acc], else: acc
            {acc, graph}
          end)

        state = put_in(state.graph, graph)

        _state =
          if !Enum.empty?(new_sentences) do
            Logger.debug("Updated codebro brain")

            task =
              Task.Supervisor.async_nolink(Hambot.CodebroTaskSupervisor, fn ->
                write_to_brain(new_sentences, state.brain_file)
              end)

            _state = put_in(state.tasks[task.ref], length(words))
          else
            Logger.debug("no brain update needed")
            state
          end
      else
        state
      end

    {:reply, reply, state}
  end

  # Task message handling
  def handle_info({ref, result}, state) do
    # The task succeed so we can cancel the monitoring and discard the DOWN message
    Process.demonitor(ref, [:flush])
    {_, state} = pop_in(state.tasks[ref])
    IO.puts("Got #{inspect(result)}")
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, _, _, reason}, state) do
    {_, state} = pop_in(state.tasks[ref])
    IO.puts("Writing to brain failed with reason #{inspect(reason)}")
    {:noreply, state}
  end

  def write_to_brain(sentences, file) do
    count =
      Enum.reduce(sentences, 0, fn sentence, c ->
        line = Enum.join(sentence, " ") <> "\n"
        File.write(file, line, [:append])
        c + 1
      end)

    Logger.debug("Wrote #{count} line(s) to brain")
    :ok
  end

  def generate_markov_text(graph) do
    generate_markov_text(graph, {:start, :start}, [])
  end

  def generate_markov_text(graph, seed) when is_binary(seed) do
    if Map.has_key?(graph, {:start, seed}) do
      generate_markov_text(graph, {:start, seed}, [])
    else
      generate_markov_text(graph)
    end
  end

  def generate_markov_text(graph, seed), do: generate_markov_text(graph, seed, [])

  def generate_markov_text(_graph, {word, :stop}, acc) do
    Enum.reverse([word | acc])
    |> Enum.join(" ")
  end

  def generate_markov_text(graph, {word1, word2}, acc) do
    next = Enum.random(Map.get(graph, {word1, word2}))
    acc = if word1 == :start, do: acc, else: [word1 | acc]
    generate_markov_text(graph, {word2, next}, acc)
  end

  @punc [".", "?", "!"]
  def string_to_sentence_stream(text) do
    chunk_fun = fn word, acc ->
      if String.ends_with?(word, @punc) do
        {:cont, Enum.reverse([String.slice(word, 0..-2//1) | acc]), []}
      else
        {:cont, [word | acc]}
      end
    end

    after_fun = fn
      [] -> {:cont, []}
      acc -> {:cont, Enum.reverse(acc), []}
    end

    text
    |> String.split()
    |> Stream.chunk_while([], chunk_fun, after_fun)
  end

  def file_sentence_stream(file) do
    File.stream!(file)
    |> Stream.flat_map(&string_to_sentence_stream/1)
  end

  def triples(tokens) do
    with_delims =
      Stream.concat([:start, :start], tokens)
      |> Stream.concat([:stop])

    Stream.chunk_every(with_delims, 3, 1, :discard)
  end

  def triples_stream(sentence_stream) do
    Stream.flat_map(sentence_stream, &triples/1)
  end

  def triples_to_graph(triples, graph \\ %{}) do
    Enum.reduce(triples, {false, graph}, fn
      [word1, word2, word3], {updated?, graph} ->
        key = {word1, word2}

        if Map.has_key?(graph, key) do
          if MapSet.member?(graph[key], word3) do
            {updated?, graph}
          else
            {true, Map.update!(graph, key, &MapSet.put(&1, word3))}
          end
        else
          {true, Map.put(graph, key, MapSet.new([word3]))}
        end
    end)
  end

  def update_graph_from_sentences(sentences, graph \\ %{}) do
    sentences
    |> triples_stream()
    |> triples_to_graph(graph)
  end
end
