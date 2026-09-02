defmodule Hambot.TweetTest do
  use ExUnit.Case, async: true

  import Mox
  import Hambot.FxTwitterFixtures

  alias Hambot.Tweet
  alias Hambot.Tweet.Status

  setup :verify_on_exit!

  describe "status_id/1" do
    test "matches status links on x.com and twitter.com hosts" do
      for url <- [
            "https://x.com/DPD_/status/2095117900965130416",
            "https://twitter.com/DPD_/status/2095117900965130416",
            "https://www.x.com/DPD_/status/2095117900965130416",
            "https://mobile.twitter.com/DPD_/status/2095117900965130416?s=20",
            "https://X.com/DPD_/status/2095117900965130416/photo/1",
            "https://x.com/i/web/status/2095117900965130416",
            "https://twitter.com/DPD_/statuses/2095117900965130416",
            "https://fxtwitter.com/DPD_/status/2095117900965130416",
            "https://fixupx.com/DPD_/status/2095117900965130416"
          ] do
        assert Tweet.status_id(url) == "2095117900965130416", url
      end
    end

    test "ignores non-status links and other hosts" do
      for url <- [
            "https://x.com/DPD_",
            "https://x.com/DPD_/with_replies",
            "https://x.com/search?q=status",
            "https://x.com/DPD_/status/notanid",
            "https://notx.com/DPD_/status/2095117900965130416",
            "https://example.com/x.com/DPD_/status/2095117900965130416",
            "https://x.com.evil.example/DPD_/status/2095117900965130416",
            "not a url"
          ] do
        assert Tweet.status_id(url) == nil, url
      end
    end
  end

  describe "status_links/1" do
    test "keeps order, pairs ids with the original url, and dedupes by id" do
      a = "https://x.com/a/status/1"
      b = "https://twitter.com/b/status/2?s=20"
      a_again = "https://x.com/a/status/1/photo/1"

      assert Tweet.status_links([a, "https://example.com", b, a_again]) == [{"1", a}, {"2", b}]
    end
  end

  describe "fetch/1" do
    test "parses a plain tweet" do
      Hambot.MockFxTwitter
      |> expect(:fetch, fn "20" -> {:ok, fxtwitter_tweet(:plain)} end)

      assert {:ok, %Status{} = status} = Tweet.fetch("20")
      assert status.id == "20"
      assert status.url == "https://x.com/jack/status/20"
      assert status.text == "just setting up my twttr"
      assert status.author.handle == "jack"
      assert status.author.name == "jack"
      assert status.author.avatar_url =~ "pbs.twimg.com"
      assert status.created_at == ~U[2006-03-21 20:50:14Z]
      assert status.photos == []
      assert status.videos == []
      assert status.quote == nil
    end

    test "parses a quoted tweet with video, picking the highest-bitrate mp4" do
      Hambot.MockFxTwitter
      |> expect(:fetch, fn "2095117900965130416" ->
        {:ok, fxtwitter_tweet(:quote_with_video)}
      end)

      assert {:ok, %Status{} = status} = Tweet.fetch("2095117900965130416")
      assert status.author.handle == "DPD_"
      assert status.videos == []

      assert %Status{author: %{handle: "PostOpinions"}, videos: [video]} = status.quote
      assert video.url =~ "/720x1280/"
      assert video.url =~ ~r{\Ahttps://video\.twimg\.com/.*\.mp4}
      assert video.poster =~ "pbs.twimg.com"
      assert video.gif? == false
      assert status.quote.quote == nil
    end

    test "passes through not found" do
      Hambot.MockFxTwitter
      |> expect(:fetch, fn "1" -> {:error, :not_found} end)

      assert {:error, :not_found} = Tweet.fetch("1")
    end
  end

  describe "Status.from_fxtwitter/1" do
    test "parses photos and gif media" do
      raw = %{
        "id" => "5",
        "url" => "https://x.com/u/status/5",
        "text" => "pics",
        "author" => %{"screen_name" => "u"},
        "media" => %{
          "photos" => [
            %{
              "url" => "https://pbs.twimg.com/media/a.jpg",
              "width" => 10,
              "height" => 20,
              "altText" => "alt"
            }
          ],
          "videos" => [
            %{
              "url" => "https://video.twimg.com/g.mp4",
              "thumbnail_url" => "https://pbs.twimg.com/t.jpg",
              "type" => "gif"
            }
          ]
        }
      }

      status = Status.from_fxtwitter(raw)
      assert status.author == %{name: "u", handle: "u", url: "", avatar_url: nil}
      assert status.created_at == nil

      assert [%{url: "https://pbs.twimg.com/media/a.jpg", width: 10, height: 20, alt: "alt"}] =
               status.photos

      assert [%{url: "https://video.twimg.com/g.mp4", gif?: true}] = status.videos
    end
  end
end
