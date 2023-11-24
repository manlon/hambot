defmodule HambotWeb.ApiJSON do
  require Logger
  def render("index.json", _assigns) do
    %{data: %{message: "Welcome to Hambot"}}
  end

  def render("url_verification.json", %{challenge: challenge}) do
    %{challenge: challenge}
  end

  def render("message.json", _) do
    %{}
  end

  def render("unknown_event.json", _assigns) do
    %{data: %{message: "Unknown received"}}
  end

  def render("403.json", _assigns) do
    %{}
  end
end
