defmodule Hambot.GameChat.Kraken do
  alias Hambot.Slack.Team
  use Oban.Worker, queue: :default
  require Ecto.Query

  @nhl_schedule_file "priv/datasets/kraken_schedule_2526.csv"
  def nhl_schedule_data do
    fname = Application.app_dir(:hambot, @nhl_schedule_file)

    query = """
    select * from '#{fname}'
    where start at time zone 'utc' >= now() - interval 1 hour
    order by start
    """

    Explorer.DataFrame.from_query!(Hambot.DuckConn, query, [])
    |> Explorer.DataFrame.to_rows()
  end

  def cancel_all_scheduled do
    mod = Module.split(__MODULE__) |> Enum.join(".")

    Oban.Job
    |> Ecto.Query.where(worker: ^mod)
    |> Oban.cancel_all_jobs()
  end

  def rebuild_schedule do
    IO.puts("rebuilding game schedule")
    cancel_all_scheduled()

    # TODO don't know why prune doesn't work
    Hambot.Repo.delete_all(Oban.Job)

    games = nhl_schedule_data()

    jobs =
      for game <- games,
          time = DateTime.from_naive!(game["start"], "UTC"),
          remind_time = DateTime.add(time, -15, :minute) do
        new(%{desc: game["summary"], time: time}, scheduled_at: remind_time)
      end

    Oban.insert_all(jobs)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"desc" => desc, "time" => time}}) do
    channels = Application.get_env(:hambot, __MODULE__)[:channels]

    Enum.map(channels, fn {team_id, channel_id} ->
      start_game_thread(team_id, channel_id, desc, time)
    end)

    :ok
  end

  defp start_game_thread(team_id, channel_id, desc, _time) do
    case Team.find_by_team_id(team_id) do
      nil ->
        nil

      team ->
        message = "🏒🦑🏒🦑 #{desc} 🦑🏒🦑🏒"

        case Hambot.Slack.send_message_text(team, channel_id, message) do
          {:ok, ts} ->
            Hambot.Slack.reply_in_thread(team, channel_id, ts, "Let's go!")

          _ ->
            nil
        end
    end
  end
end
