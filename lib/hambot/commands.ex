defmodule Hambot.Commands do
  alias Hambot.Commands.Parser
  alias Hambot.Slack
  alias Hambot.Slack.Team
  alias Hambot.Archive

  def respond_to_mention(team_id, user_id, channel, text) do
    text = String.trim(text)

    case Parser.parse_mention(text) do
      {:ok, [^user_id | rest], _, _, _, _} ->
        do_command(rest, team_id, channel)

      _ ->
        respond_to_unknown(team_id, channel)
    end
  end

  def respond_to_dm(team_id, channel, text) do
    case Parser.parse_command(text) do
      {:ok, args, _, _, _, _} ->
        do_command(args, team_id, channel)
    end
  end

  def do_command(["domain", "add", domain], team_id, channel) do
    case Parser.parse_link(domain) do
      {:ok, [domain], _, _, _, _} ->
        case Archive.add_domain(team_id, domain) do
          {:ok, _} ->
            send_message(team_id, channel, "added #{domain} to the archive list :ham:")

          {:error, msg} ->
            send_message(team_id, channel, "couldn't add domiain #{domain}: #{msg}")
        end

      _ ->
        send_message(team_id, channel, "couldn't parse domain #{domain}")
    end
  end

  def do_command(["domain", "list"], team_id, channel) do
    domains = Archive.list_domains(team_id)
    msgs = ["here are the domains :ham: knows about" | domains]
    send_message(team_id, channel, Enum.join(msgs, "\n"))
  end

  def do_command(other_args, team_id, channel) do
    msgs = ["don't know how to" | other_args]
    send_message(team_id, channel, Enum.join(msgs, " "))
  end

  def respond_to_unknown(team_id, channel) do
    send_message(team_id, channel, "ham")
  end

  defp send_message(team_id, channel, msg) do
    token = Team.get_access_token(team_id)
    Slack.send_message(token, channel, msg)
  end
end
