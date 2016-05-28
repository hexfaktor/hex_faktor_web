defmodule HexFaktor.PackageView do
  use HexFaktor.Web, :view

  def current_version([%{"version" => version}|tail]), do: version
  def current_version(_), do: nil

  def render("ok.json", _), do: %{ok: true}
  def render("error.json", _), do: %{error: true}

  def render("404.html", _), do: "Not found"
end
