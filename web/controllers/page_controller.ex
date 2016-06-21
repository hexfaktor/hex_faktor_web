defmodule HexFaktor.PageController do
  use HexFaktor.Web, :controller
  require Logger

  alias HexFaktor.Auth

  def index(conn, _params) do
    if Auth.current_user(conn) do
      redirect conn, to: project_path(conn, :index)
    else
      render conn, "index.html"
    end
  end

  def about(conn, _params) do
    render conn, "about.html"
  end

  def status_404(conn, _params) do
    render conn, "404.html"
  end

  def status_500(conn, _params) do
    1 / 0
    render conn, "500.html"
  end
end
