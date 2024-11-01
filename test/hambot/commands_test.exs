defmodule Hambot.CommandsTest do
  use Hambot.DataCase
  import Hambot.TeamFixtures

  import Mox
  setup :verify_on_exit!

  describe "domain commands" do
    test "domain add" do
      team = team_fixture()

      Hambot.MockSlackApi
      |> expect(:send_message_text, fn team_arg, "C123", "added example.com" <> _, _opts ->
        assert team_arg == team.access_token
        :ok
      end)

      Hambot.Commands.respond_to_mention(
        team,
        "U123",
        "C123",
        "<@U123> domain add https://example.com"
      )
    end

    test "domain list" do
      alias Hambot.Archive
      team = team_fixture()
      Hambot.Repo.delete_all(Hambot.Archive.Domain)
      Archive.add_domain(team, "zoop.com")
      Archive.add_domain(team, "zeep.com")

      Hambot.MockSlackApi
      |> expect(:send_message_text, fn team_arg, "C123", msg, _opts ->
        assert team_arg == team.access_token
        assert String.contains?(msg, "zeep.com\nzoop.com")
        :ok
      end)

      Hambot.Commands.respond_to_mention(team, "U123", "C123", "<@U123> domain list")
    end
  end
end
