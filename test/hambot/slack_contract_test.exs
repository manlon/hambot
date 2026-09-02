defmodule Hambot.SlackContractTest do
  use Hambot.DataCase
  use ExUnitProperties

  import Hambot.TeamFixtures
  import Mox

  setup :verify_on_exit!

  describe "Slack API contract compliance" do
    property "send_message_text always returns {:ok, timestamp} or {:error, reason}" do
      check all(
              text <- string(:printable, min_length: 1, max_length: 100),
              channel <- string(:alphanumeric, min_length: 5, max_length: 15)
            ) do
        team = team_fixture()

        # Mock the Slack API to return the correct format
        Hambot.MockSlackApi
        |> expect(:send_message_text, fn _token, ^channel, ^text, _opts ->
          # This simulates the real Slack API response
          timestamp = "#{:os.system_time(:millisecond)}.123456"
          {:ok, timestamp}
        end)

        # Call the function
        result = Hambot.Slack.send_message_text(team, channel, text)

        # Verify it matches the contract
        assert match?({:ok, _timestamp}, result) or match?({:error, _reason}, result)

        # For successful responses, verify timestamp format
        case result do
          {:ok, ts} ->
            assert is_binary(ts)
            assert String.contains?(ts, ".")

          {:error, _} ->
            :ok
        end
      end
    end

    test "reply_in_thread returns {:ok, timestamp} format" do
      team = team_fixture()

      Hambot.MockSlackApi
      |> expect(:reply_in_thread, fn _token, "C123", "1234.5678", "test", _opts ->
        timestamp = "#{:os.system_time(:millisecond)}.123456"
        {:ok, timestamp}
      end)

      result = Hambot.Slack.reply_in_thread(team, "C123", "1234.5678", "test")

      assert {:ok, timestamp} = result
      assert is_binary(timestamp)
    end

    test "commands handle Slack API return values correctly" do
      team = team_fixture()

      # This test ensures commands can handle the actual return format
      Hambot.MockSlackApi
      |> expect(:send_message_text, fn _token, "C123", _msg, _opts ->
        # Return the REAL format from the API
        {:ok, "1234567890.123456"}
      end)

      # This should NOT crash with a CaseClauseError
      assert :ok ==
               Hambot.Commands.respond_to_mention(
                 team,
                 "U123",
                 "C123",
                 "<@U123> domain list"
               )
    end

    test "mock behavior matches production behavior" do
      # This test documents the contract - if the real API changes,
      # update both the behavior definition AND this test

      team = team_fixture()

      Hambot.MockSlackApi
      |> expect(:send_message_text, fn _token, "C456", "test", [] ->
        # Production returns {:ok, timestamp}, NOT :ok
        {:ok, "1234567890.123456"}
      end)

      result = Hambot.Slack.send_message_text(team, "C456", "test", [])

      # Explicitly test the contract
      assert {:ok, timestamp} = result
      assert is_binary(timestamp)
      refute result == :ok, "Slack API should return {:ok, timestamp}, not :ok"
    end
  end

  describe "property-based testing for return values" do
    property "all successful Slack API calls return {:ok, timestamp} format" do
      check all(
              text <- string(:printable, min_length: 1, max_length: 50),
              # Generate channel IDs that look realistic
              channel_id <- string([?A..?Z, ?0..?9], length: 9)
            ) do
        team = team_fixture()
        channel = "C" <> channel_id

        Hambot.MockSlackApi
        |> expect(:send_message_text, fn _token, ^channel, ^text, _opts ->
          # All successful responses must match this format
          timestamp = "#{:os.system_time(:millisecond)}.123456"
          {:ok, timestamp}
        end)

        result = Hambot.Slack.send_message_text(team, channel, text)

        # Verify the contract
        assert {:ok, timestamp} = result
        assert is_binary(timestamp)
        assert String.contains?(timestamp, ".")
      end
    end
  end
end
