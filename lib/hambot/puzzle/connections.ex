defmodule Hambot.Puzzle.Connections do
  defmodule Parser do
    import NimbleParsec

    @colors ["yellow", "green", "blue", "purple"]

    prefix =
      ignore(
        string("Connections")
        |> optional(string(" "))
        |> string("\n")
        |> string("Puzzle #")
      )

    puzznum = integer(min: 1)
    emoji_start = string(":large_")
    emoji_end = string("_square:")
    squares = for c <- @colors, do: ignore(emoji_start) |> string(c) |> ignore(emoji_end)
    square = choice(squares)
    line = ignore(string("\n")) |> wrap(times(square, 4))
    grid = wrap(times(line, min: 4))

    defparsec(:parse, prefix |> concat(puzznum) |> concat(grid))

    def parse_number_and_grid(input) do
      case parse(input) do
        {:ok, [num, grid], _, _, _, _} -> {:ok, num, grid}
        err -> err
      end
    end
  end

  def score(result) do
    case Parser.parse_number_and_grid(result) do
      {:ok, _num, grid} ->
        {:ok, score_grid(grid)}

      err ->
        err
    end
  end

  @ranks %{
    "yellow" => 1,
    "green" => 2,
    "blue" => 3,
    "purple" => 4
  }

  defp score_grid(grid) do
    sets = Enum.map(grid, &Enum.uniq/1) |> Enum.filter(&(length(&1) == 1)) |> Enum.map(&hd/1)
    num_wrong = length(grid) - length(sets)
    score_set_order(sets) - 2 * num_wrong
  end

  defp score_set_order([top | rest]) do
    Enum.count(rest, &(@ranks[&1] < @ranks[top])) + score_set_order(rest)
  end

  defp score_set_order(_), do: 0
end
