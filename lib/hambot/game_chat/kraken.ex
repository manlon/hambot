defmodule Hambot.GameChat.Kraken do
  alias Hambot.Slack.Team
  use Oban.Worker, queue: :default
  require Ecto.Query

  defmodule TimeParser do
    import NimbleParsec

    time =
      integer(min: 1, max: 2)
      |> ignore(string(":"))
      |> integer(2)
      |> ignore(string(" "))
      |> choice([string("AM"), string("PM")])

    defparsec(:parse, time)

    def parse_time(str) do
      case parse(str) do
        {:ok, [h, m, ap], _, _, _, _} ->
          h = if ap == "PM" and h != 12, do: h + 12, else: h
          Time.new!(h, m, 0)

        _ ->
          nil
      end
    end
  end

  @eastern_time "America/New_York"
  @nhl_schedule_file "priv/datasets/nhl_schedule_2425.csv"
  def nhl_schedule_data do
    fname = Application.app_dir(:hambot, @nhl_schedule_file)

    query = """
    select * from '#{fname}'
    where START_DATE >= now() - interval 1 day
    and SUBJECT like '%Seattle%'
    order by START_DATE
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
          time = nhl_game_to_date_time(game),
          remind_time = DateTime.add(time, -15, :minute) do
        new(%{desc: game["SUBJECT"], time: time}, scheduled_at: remind_time)
      end

    Oban.insert_all(jobs)
  end

  def nhl_game_to_date_time(%{"START_DATE" => dt, "START_TIME_ET" => t}) do
    case TimeParser.parse_time(t) do
      nil ->
        nil

      time ->
        NaiveDateTime.new!(dt, time)
        |> DateTime.from_naive!(@eastern_time)
    end
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
