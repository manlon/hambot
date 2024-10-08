defmodule Hambot.Codebro do
  use GenServer

  # Client API

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # Send codebro a message
  def send_chat(message) do
    GenServer.call(__MODULE__, {:message, message})
  end

  # Server (callbacks)

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_call({:message, message}, _from, state) do
    # Handle the prompt using the Markov chain (to be implemented)
    reply =
      if message do
        "I'm sorry, I can't do that."
      else
        "I'm sorry, Dave. I'm afraid I can't do that."
      end

    {:reply, reply, state}
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
  def tokenize_string(text) do
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

  def tokens_stream(file) do
    File.stream!(file)
    |> Stream.flat_map(&tokenize_string/1)
  end

  def triples(tokens) do
    with_delims =
      Stream.concat([:start, :start], tokens)
      |> Stream.concat([:stop])

    Stream.chunk_every(with_delims, 3, 1, :discard)
  end

  def markov_stream(file) do
    tokens_stream(file)
    |> Stream.flat_map(&triples/1)
  end

  def triples_to_graph(triples) do
    Enum.reduce(triples, %{}, fn
      [word1, word2, word3], graph ->
        Map.update(graph, {word1, word2}, MapSet.new([word3]), &MapSet.put(&1, word3))
    end)
  end
end
