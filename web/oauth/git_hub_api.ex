defmodule GitHubAPI do
  @base_url Application.get_env(:hex_faktor, :base_url)
  @hook_rebuild_url "#{@base_url}/api/rebuild_via_hook"

  require Logger

  def user(token) do
    case OAuth2.AccessToken.get!(token, "/user") do
      %OAuth2.Response{body: user_info} -> user_info
      _ -> nil
    end
  end

  def project(token, project_name) do
    project_info =
      case OAuth2.AccessToken.get!(token, "/repos/#{project_name}") do
        %OAuth2.Response{body: info} -> info
        _ -> nil
      end
    branch_names =
      case OAuth2.AccessToken.get!(token, "/repos/#{project_name}/branches") do
        %OAuth2.Response{body: info} -> info
        _ -> []
      end
      |> Enum.map(fn(info) -> info["name"] end)
    {project_info, branch_names}
  end

  def get_hook(token, project_name, nil, active) do
    create_hook(token, project_name, active)
  end
  def get_hook(token, project_name, hook_id, active) do
    update_hook(token, project_name, hook_id, active)
  end

  def set_hook(token, project_name, nil, active) do
    result = create_hook(token, project_name, active)
    case result do
      %{"errors" => [%{"code" => "custom", "message" => "Hook already exists on this repository", "resource" => "Hook"}], "message" => "Validation Failed"} ->
        repair_hook_id(token, project_name, active)
      %{"active" => _} ->
        result
    end
  end
  def set_hook(token, project_name, hook_id, active) do
    Logger.info "SET_HOOK for #{project_name}, hook_id: #{hook_id}, active: #{active}"
    update_hook(token, project_name, hook_id, active)
  end

  # called when there is a GitHub hook installed but our system thought there wasn't
  defp repair_hook_id(token, project_name, active) do
    case get_hook_id(token, project_name) do
      nil -> nil
      hook_id -> repair_hook_id(token, project_name, hook_id, active)
    end
  end
  defp repair_hook_id(token, project_name, hook_id, active) do
    case set_hook(token, project_name, hook_id, active) do
      %{"active" => active, "id" => uid} ->
        %{"active" => active, "id" => uid}
      %{"errors" => [%{"code" => "custom", "message" => "Hook already exists on this repository", "resource" => "Hook"}], "message" => "Validation Failed"} ->
        %{"active" => active, "id" => hook_id}
    end
  end

  def get_hook_id(token, project_name) do
    all_hooks =
      case OAuth2.AccessToken.get!(token, "/repos/#{project_name}/hooks") do
        %OAuth2.Response{body: info} -> info
        _ -> []
      end

    result =
      all_hooks
      |> Enum.find_value(&find_hook_with_url(&1, @hook_rebuild_url))

    IO.inspect {:GET_HOOK_ID, result}
    result
  end

  defp find_hook_with_url(%{"id" => id, "config" => %{"url" => url}}, hook_url) do
    if url == hook_url, do: id
  end
  defp find_hook_with_url(_, _), do: nil

  defp update_hook(token, project_name, hook_id, active) do
    Logger.info "UPDATE_HOOK for #{project_name}, hook_id: #{hook_id}, active: #{active}"

    payload = hook_settings(active)
    case OAuth2.AccessToken.patch!(token, "/repos/#{project_name}/hooks/#{hook_id}", payload) do
      %OAuth2.Response{body: body} -> body
      _ -> nil
    end
    |> IO.inspect
  end

  defp create_hook(token, project_name, active) do
    payload = hook_settings(active)

    result = OAuth2.AccessToken.post!(token, "/repos/#{project_name}/hooks", payload)
    case result do
      %OAuth2.Response{body: body} -> body
      _ -> nil
    end
  end

  defp hook_settings(active) do
    %{
      "name" => "web",
      "active" => active,
      "events" => ["push"],
      "config" => %{
        "url" => @hook_rebuild_url,
        "content_type" => "json"
      }
    }
  end
end
