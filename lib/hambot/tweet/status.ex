defmodule Hambot.Tweet.Status do
  @moduledoc """
  A tweet as rendered by the viewer page, parsed from FxTwitter's JSON.
  """

  @type author :: %{
          name: String.t(),
          handle: String.t(),
          url: String.t(),
          avatar_url: String.t() | nil
        }
  @type photo :: %{
          url: String.t(),
          width: integer() | nil,
          height: integer() | nil,
          alt: String.t() | nil
        }
  @type video :: %{
          url: String.t(),
          poster: String.t() | nil,
          width: integer() | nil,
          height: integer() | nil,
          gif?: boolean()
        }

  @type t :: %__MODULE__{
          id: String.t(),
          url: String.t(),
          text: String.t(),
          created_at: DateTime.t() | nil,
          author: author(),
          photos: [photo()],
          videos: [video()],
          quote: t() | nil
        }

  defstruct [:id, :url, :text, :created_at, :author, :quote, photos: [], videos: []]

  @spec from_fxtwitter(map()) :: t()
  def from_fxtwitter(tweet) when is_map(tweet) do
    media = tweet["media"] || %{}

    %__MODULE__{
      id: tweet["id"],
      url: tweet["url"],
      text: tweet["text"] || "",
      created_at: parse_timestamp(tweet["created_timestamp"]),
      author: parse_author(tweet["author"] || %{}),
      photos: Enum.map(media["photos"] || [], &parse_photo/1),
      videos: Enum.map(media["videos"] || [], &parse_video/1),
      quote: if(is_map(tweet["quote"]), do: from_fxtwitter(tweet["quote"]))
    }
  end

  defp parse_timestamp(ts) when is_integer(ts), do: DateTime.from_unix!(ts)
  defp parse_timestamp(_), do: nil

  defp parse_author(author) do
    %{
      name: author["name"] || author["screen_name"] || "",
      handle: author["screen_name"] || "",
      url: author["url"] || "",
      avatar_url: author["avatar_url"]
    }
  end

  defp parse_photo(photo) do
    %{
      url: photo["url"],
      width: photo["width"],
      height: photo["height"],
      alt: photo["altText"]
    }
  end

  defp parse_video(video) do
    best_mp4 =
      (video["variants"] || [])
      |> Enum.filter(&(&1["content_type"] == "video/mp4" and is_binary(&1["url"])))
      |> Enum.max_by(&(&1["bitrate"] || 0), fn -> nil end)

    %{
      url: (best_mp4 && best_mp4["url"]) || video["url"],
      poster: video["thumbnail_url"],
      width: video["width"],
      height: video["height"],
      gif?: video["type"] == "gif"
    }
  end
end
