defmodule HexFaktor.HelpController do
  use HexFaktor.Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def badge(conn, _params) do
    render(conn, "badge.html")
  end
end
