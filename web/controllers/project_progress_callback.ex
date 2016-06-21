defmodule HexFaktor.ProjectProgressCallback do
  # `progress_callback_data` is the struct put into the :progress_callback key
  # of the `meta` struct during the build process
  def cast(progress_callback_data) do
    current_user_id = progress_callback_data["current_user_id"]
    project_id = progress_callback_data["project_id"]
    branch_name = progress_callback_data["branch_name"]
    event_name = progress_callback_data["event_name"]

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
end
