defmodule Hambot.CommandsTest do
  use Hambot.DataCase

  describe "parsers" do
    test "domain add" do
      Hambot.Commands.respond_to_mention("U123", "C123", "<@U123> domain add https://example.com")
    end
  end
end
