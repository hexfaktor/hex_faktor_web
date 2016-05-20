defmodule HexFaktor.AppEvent do
  alias HexFaktor.Persistence.AppEventLog

  def log(:hex_package_update, name, projects) do
    AppEventLog.create(nil, "package_update", %{
                              "name" => name,
                              "source" => "hex",
                              "dependent_project_ids" => projects |> Enum.map(&(&1.id))
                              })
  end
  def log(:rebuild_via_hook, provider, project, branch_name) do
    AppEventLog.create(nil, "rebuild_via_hook", %{
                              "provider" => provider,
                              "project_id" => project.id,
                              "branch" => branch_name
                              })
  end
  def log(:sign_up, user) do
    AppEventLog.create(user, "sign_up", %{})
  end
  def log(:sign_in, user) do
    AppEventLog.create(user, "sign_in", %{})
  end
  def log(:sign_out, user) do
    AppEventLog.create(user, "sign_out", %{})
  end
end
