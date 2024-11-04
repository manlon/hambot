defmodule HambotWeb.Router do
  use HambotWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HambotWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HambotWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/slack_auth", SlackAuthController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", HambotWeb do
    pipe_through :api
    get "/", ApiController, :index
    post "/event", ApiController, :event
    get "/event", ApiController, :event
  end

  scope "/wikify", HambotWeb do
    pipe_through :browser
    get "/", WikifyController, :index
    post "/", WikifyController, :index
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:hambot, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HambotWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
