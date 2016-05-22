defmodule HexFaktor.ErrorView do
  use HexFaktor.Web, :view

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.html", assigns
  end

  def render("404.json", _), do: %{error: true, reason: 404}
  def render("500.json", _), do: %{error: true, reason: 500}
end
