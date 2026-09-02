defmodule HambotWeb.TweetHTML do
  use HambotWeb, :html

  alias Hambot.Tweet.Status

  embed_templates "tweet_html/*"

  attr :status, Status, required: true
  attr :quoted, :boolean, default: false

  def tweet(assigns) do
    ~H"""
    <article class={["tweet", @quoted && "quoted"]}>
      <header>
        <img :if={@status.author.avatar_url} class="avatar" src={@status.author.avatar_url} alt="" />
        <div class="who">
          <span class="name">{@status.author.name}</span>
          <a class="handle" href={@status.author.url}>@{@status.author.handle}</a>
        </div>
      </header>
      <p :if={@status.text != ""} class="text">{@status.text}</p>
      <div :if={@status.photos != []} class="media photos">
        <img
          :for={photo <- @status.photos}
          src={photo.url}
          alt={photo.alt || ""}
          width={photo.width}
          height={photo.height}
          loading="lazy"
        />
      </div>
      <div :for={video <- @status.videos} class="media">
        <video
          controls
          playsinline
          preload="metadata"
          src={video.url}
          poster={video.poster}
          width={video.width}
          height={video.height}
          loop={video.gif?}
          muted={video.gif?}
          autoplay={video.gif?}
        >
        </video>
      </div>
      <.tweet :if={@status.quote} status={@status.quote} quoted={true} />
      <footer :if={@status.created_at}>
        <a href={@status.url}>
          <time datetime={DateTime.to_iso8601(@status.created_at)}>
            {format_time(@status.created_at)}
          </time>
        </a>
      </footer>
    </article>
    """
  end

  defp format_time(dt), do: Calendar.strftime(dt, "%b %-d, %Y · %H:%M UTC")
end
