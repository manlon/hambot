defmodule Hambot.CommandsTest do
  use Hambot.DataCase
  alias Hambot.Archive.Server

  import Mox
  setup :verify_on_exit!

  describe "domain commands" do
    test "domain add" do
      Hambot.MockSlackApi
      |> expect(:send_message, fn "C123", "added example.com" <> _ -> :ok end)

      Hambot.Commands.respond_to_mention("U123", "C123", "<@U123> domain add https://example.com")
    end

    test "domain list" do
      Hambot.Repo.delete_all(Hambot.Archive.Domain)
      Server.reinitialize()
      Server.add_domain("zoop.com")
      Server.add_domain("zeep.com")

      Hambot.MockSlackApi
      |> expect(:send_message, fn "C123", msg ->
        assert String.contains?(msg, "zeep.com\nzoop.com")
        :ok
      end)

      Hambot.Commands.respond_to_mention("U123", "C123", "<@U123> domain list")
    end
  end
end
