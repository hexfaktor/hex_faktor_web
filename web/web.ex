defmodule HexFaktor.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use HexFaktor.Web, :controller
      use HexFaktor.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query, only: [from: 1, from: 2]
    end
  end

  def controller do
    quote do
      use Phoenix.Controller

      alias HexFaktor.Repo
      import Ecto
      import Ecto.Query, only: [from: 1, from: 2]

      import HexFaktor.Router.Helpers
      import HexFaktor.Gettext

      defp access_denied(conn) do
        conn
        |> put_status(403)
        |> render(HexFaktor.ErrorView, "403.html", [])
        |> halt
      end

      defp redirect_for_html(conn, redirect_url \\ "/", template_name \\ "ok.json") do
        if get_format(conn) == "html" do
          conn |> redirect(to: redirect_url)
        else
          conn |> render(template_name)
        end
      end

      defp nil_if_empty(""), do: nil
      defp nil_if_empty(val), do: val
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "web/templates"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import HexFaktor.Router.Helpers
      import HexFaktor.ErrorHelpers
      import HexFaktor.Gettext

      import HexFaktor.Auth

      use HexFaktor.ViewHelpers

    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias HexFaktor.Repo
      import Ecto
      import Ecto.Query, only: [from: 1, from: 2]
      import HexFaktor.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
