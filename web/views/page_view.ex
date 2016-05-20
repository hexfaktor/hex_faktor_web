defmodule HexFaktor.PageView do
  use HexFaktor.Web, :view

  def render("ok.json", _) do
    %{ok: true}
  end
end
