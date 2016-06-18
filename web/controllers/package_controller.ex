defmodule HexFaktor.PackageController do
  use HexFaktor.Web, :controller

  alias HexFaktor.Persistence.Notification
  alias HexFaktor.Persistence.Package
  alias HexFaktor.Persistence.PackageUserSettings
  alias HexFaktor.Persistence.Project

  alias HexFaktor.PackageProvider
  alias HexFaktor.Auth

  @hex_mirror HexSonar
  @shown_release_count 5

  @filter_all "all"
  @filter_search "search"

  def index(conn, params) do
    perform_index(conn, params, "html")
  end

  def index_api(conn, params) do
    perform_index(conn, params, "json")
  end

  defp perform_index(conn, params, format) do
    search_query = params["q"] |> nil_if_empty
    current_package_filter = params["filter"] |> nil_if_empty

    if current_package_filter == @filter_search && is_nil(search_query) do
      current_package_filter = @filter_all
    end

    packages =
      case current_package_filter do
        @filter_search -> Package.all_by_query(search_query)
        _ -> Package.all
      end

    assigns = [
      current_package_filter: current_package_filter,
      packages: packages,
      search: search_query
    ]

    render(conn, "index.#{format}", assigns)
  end

  def rebuild_via_web(conn, %{"id" => package_id} = params) do
    package = Package.find_by_id(package_id)
    update_package_from_hex(package)
    render(conn, "ok.json")
  end

  def show(conn, %{"name" => name}) do
    perform_show(conn, name, "html")
  end

  def show_api(conn, %{"name" => name}) do
    perform_show(conn, name, "json")
  end

  def perform_show(conn, name, format) do
    current_user = Auth.current_user(conn)
    assigns = PackageProvider.assigns_for(current_user, name)

    render(conn, "show.#{format}", assigns)
  end

  #
  # /update_settings
  #

  def update_settings_all(conn, %{"id" => package_id}) do
    update_params = %{
      "notifications_for_major" => true,
      "notifications_for_minor" => true,
      "notifications_for_patch" => true,
      "notifications_for_pre" => false,
    }
    params = %{"id" => package_id, "package_user_settings" => update_params}
    success_message = :follow
    update_settings(conn, params, success_message)
  end

  def update_settings_none(conn, %{"id" => package_id}) do
    update_params = %{
      "notifications_for_major" => false,
      "notifications_for_minor" => false,
      "notifications_for_patch" => false,
      "notifications_for_pre" => false,
    }
    params = %{"id" => package_id, "package_user_settings" => update_params}
    success_message = :unfollow
    update_settings(conn, params, success_message)
  end

  def update_settings(conn, %{"id" => package_id, "package_user_settings" => update_params}, success_message) do
    current_user = Auth.current_user(conn)
    if current_user do
      package = Package.find_by_id(package_id)
      conn |> perform_update_settings(current_user, package, update_params, success_message)
    else
      conn |> access_denied()
    end
  end

  defp perform_update_settings(conn, current_user, package, update_params, success_message) do
    package_user_settings =
      PackageUserSettings.ensure(package.id, current_user.id)
    changeset =
      PackageUserSettings.update_attributes(package_user_settings, update_params)
    if changeset.valid? do
      conn = conn |> put_flash(:info, success_message)
    end
    redirect(conn, to: package_path(conn, :show, package.name))
  end

  defp update_package_from_hex(package) do
    package.name
    |> @hex_mirror.load
    |> Package.update_from_hex(package)
  end

end
