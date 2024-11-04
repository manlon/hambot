defmodule HambotWeb.WikifyController do
  use HambotWeb, :controller

  def index(conn, params) do
    words =
      if Map.has_key?(params, "words") do
        params["words"]
        |> split_words
        |> Enum.uniq()
      else
        []
      end

    render(conn, :index, words: words, layout: false)
  end

  defp split_words(string) do
    # Regex pattern to match CJK Han characters and whitespace boundaries
    Regex.scan(~r/[^\p{Han}\s]+|\p{Han}/u, string)
    |> Enum.map(&hd/1)
  end
end
