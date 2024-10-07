defmodule Hambot.CommandsTest do
  use Hambot.DataCase
  import Hambot.TeamFixtures

  import Mox
  setup :verify_on_exit!

  describe "domain commands" do
    test "domain add" do
      team = team_fixture()

      Hambot.MockSlackApi
      |> expect(:send_message, fn team_token, "C123", "added example.com" <> _ ->
        assert team_token == team.access_token
        :ok
      end)

      Hambot.Commands.respond_to_mention(
        team.team_id,
        "U123",
        "C123",
        "<@U123> domain add https://example.com"
      )
    end

    test "domain list" do
      alias Hambot.Archive
      team = team_fixture()
      Hambot.Repo.delete_all(Hambot.Archive.Domain)
      Archive.add_domain(team.team_id, "zoop.com")
      Archive.add_domain(team.team_id, "zeep.com")

      Hambot.MockSlackApi
      |> expect(:send_message, fn team_token, "C123", msg ->
        assert team_token == team.access_token
        assert String.contains?(msg, "zeep.com\nzoop.com")
        :ok
      end)

      Hambot.Commands.respond_to_mention(team.team_id, "U123", "C123", "<@U123> domain list")
    end
  end
end
