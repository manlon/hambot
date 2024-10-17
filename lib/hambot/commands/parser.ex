defmodule Hambot.Commands.Parser do
  import NimbleParsec

  space = ignore(times(string(" "), min: 1))
  arg = utf8_string([{:not, ?\s}, {:not, ?\n}], min: 1)

  l_angle = string("<")
  r_angle = string(">")
  at = string("@")

  uname =
    ignore(l_angle) |> ignore(at) |> ascii_string([?A..?Z, ?0..?9], min: 1) |> ignore(r_angle)

  flat_link =
    ascii_string([{:not, ?\s}, {:not, ?\n}, {:not, ?<}, {:not, ?>}, {:not, ?|}], min: 1)
    |> post_traverse(:map_uri)

  fancy_link =
    ignore(l_angle)
    |> concat(flat_link)
    |> optional(
      ignore(string("|"))
      |> concat(flat_link)
    )
    |> ignore(r_angle)
    |> post_traverse(:map_uri)

  defparsec(:parse_command, arg |> repeat(space |> concat(arg)))
  defparsec(:parse_mention, uname |> repeat(space |> concat(arg)))
  defparsec(:parse_link, choice([flat_link, fancy_link]))

  def map_uri(rest, [url], context, _line, _offset), do: map_uri(rest, url, context)
  def map_uri(rest, [_, url], context, _line, _offset), do: map_uri(rest, url, context)

  def map_uri(rest, url, context) do
    case URI.new(url) do
      {:ok, uri} ->
        {rest, [uri.host || uri.path], context}

      {:error, _} ->
        {:error, "bad url"}
    end
  end
end
