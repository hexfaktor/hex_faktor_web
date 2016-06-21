defmodule HexFaktor.ProjectProgressCallback do
  require Logger

  # `progress_callback_data` is the map put into the `meta` map
  # during the build process
  def cast(%{"current_user_id" => current_user_id, "project_id" => project_id, "branch_name" => branch_name, "event_name" => event_name}) do
    fn(status) ->
      payload = %{
        "project_id" => project_id,
        "branch_name" => branch_name,
        "status" => status,
      }
      HexFaktor.Broadcast.to_project(project_id, event_name, payload)
      if current_user_id do
        HexFaktor.Broadcast.to_user(current_user_id, event_name, payload)
      end
    end
  end
  def cast(nil) do
    fn(_) -> end
  end
  def cast(value) do
    Logger.error "Got ProjectProgressCallback.cast for value: #{inspect value}"
    cast(nil)
  end
end
