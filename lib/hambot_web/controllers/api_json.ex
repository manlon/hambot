defmodule HambotWeb.ApiJSON do
  def render("index.json", _assigns) do
    %{data: %{message: "Welcome to Hambot"}}
  end
end
