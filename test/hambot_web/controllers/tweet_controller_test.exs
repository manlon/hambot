defmodule HambotWeb.TweetControllerTest do
  use HambotWeb.ConnCase

  import Mox
  import Hambot.FxTwitterFixtures

  alias HambotWeb.TweetLink

  setup :verify_on_exit!

  test "renders a tweet and its quoted video without a referrer", %{conn: conn} do
    Hambot.MockFxTwitter
    |> expect(:fetch, fn "2095117900965130416" -> {:ok, fxtwitter_tweet(:quote_with_video)} end)

    conn = get(conn, ~p"/t/2095117900965130416")
    html = html_response(conn, 200)
    doc = Floki.parse_document!(html)

    assert Floki.attribute(doc, ~s(meta[name="referrer"]), "content") == ["no-referrer"]
    assert html =~ "<title>Daniel D&#39;Addario (@DPD_) on X</title>"
    refute html =~ "app.css"

    assert [main, quoted] = Floki.find(doc, "article.tweet")
    assert Floki.text(Floki.find(main, ".text")) =~ "just making sure I understand the premise"
    assert Floki.text(Floki.find(quoted, ".handle")) == "@PostOpinions"

    assert [src] = Floki.attribute(doc, "video", "src")
    assert src =~ ~r{\Ahttps://video\.twimg\.com/.*\.mp4}
    assert [poster] = Floki.attribute(doc, "video", "poster")
    assert poster =~ "pbs.twimg.com"
    assert Floki.attribute(doc, "video", "autoplay") == []

    assert "https://x.com/DPD_/status/2095117900965130416" in Floki.attribute(doc, "a", "href")
  end

  test "renders a plain tweet", %{conn: conn} do
    Hambot.MockFxTwitter
    |> expect(:fetch, fn "20" -> {:ok, fxtwitter_tweet(:plain)} end)

    html = conn |> get(~p"/t/20") |> html_response(200)
    assert html =~ "just setting up my twttr"
    refute html =~ "<video"
  end

  test "404s for a missing tweet", %{conn: conn} do
    Hambot.MockFxTwitter
    |> expect(:fetch, fn "1234567890" -> {:error, :not_found} end)

    assert conn |> get(~p"/t/1234567890") |> html_response(404) =~ "Not Found"
  end

  test "404s for a malformed id without calling the API", %{conn: conn} do
    assert conn |> get(~p"/t/not-an-id") |> html_response(404) =~ "Not Found"
  end

  test "502s when the API is unavailable", %{conn: conn} do
    Hambot.MockFxTwitter
    |> expect(:fetch, fn "20" -> {:error, %Req.TransportError{reason: :timeout}} end)

    assert conn |> get(~p"/t/20") |> html_response(502)
  end

  test "viewer_url/1 points at the viewer route", %{conn: _conn} do
    assert TweetLink.viewer_url("20") =~ ~r{\Ahttp://localhost(:\d+)?/t/20\z}
    assert TweetLink.status_id("20") == {:ok, "20"}
    assert TweetLink.status_id("20x") == {:error, :invalid}
  end
end
