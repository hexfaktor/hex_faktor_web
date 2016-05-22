defmodule HexFaktor.PackageView do
  use HexFaktor.Web, :view

  def render("ok.json", _), do: %{ok: true}
  def render("error.json", _), do: %{error: true}
end
