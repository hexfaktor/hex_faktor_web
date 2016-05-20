defmodule HexFaktor.ProjectBuilder do
  use HexFaktor.Web, :controller

  alias HexFaktor.Persistence.Project
  alias HexFaktor.Persistence.ProjectUserSettings
  alias HexFaktor.ProjectProvider

  @event_build "project.build"

  def run_notification_branches(project, trigger) do
    branch_names =
      project.id
      |> ProjectUserSettings.find_by_project_id()
      |> Enum.flat_map(&(&1.notification_branches))
      |> Enum.uniq

    if branch_names |> Enum.empty? do
      branch_names = [project.default_branch]
    end

    notification_branches =
      project.git_repo_branches
      |> Enum.filter(&(Enum.member?(branch_names, &1.name)))

    notification_branches
    |> Enum.each(&run(nil, project, &1.name, trigger))
  end

  @doc "Runs the evaluation if no build has been run."
  def run_if_was_never_built(build, project, branch, trigger, current_user \\ nil)

  def run_if_was_never_built(nil, project, nil, trigger, current_user) do
    branch =
      project.git_repo_branches
      |> Enum.find(&(&1.name == project.default_branch))

    if branch do
      run_if_was_never_built(nil, project, branch, trigger, current_user)
    end
  end
  def run_if_was_never_built(nil, project, branch, trigger, current_user) do
    case ProjectProvider.latest_evaluation(branch) do
      {nil, _, _} ->
        run(current_user, project, branch.name, trigger)
      _ ->
        nil
    end
  end
  def run_if_was_never_built(_build, _project, _branch, _trigger, _current_user), do: nil

  def run(current_user, project, branch_name, trigger) do
    run_rebuild_for(project, branch_name, trigger, fn(status) ->
        payload = %{
          "project_id" => project.id,
          "branch_name" => branch_name,
          "status" => status,
        }
        HexFaktor.Broadcast.to_project(project.id, @event_build, payload)
        if current_user do
          HexFaktor.Broadcast.to_user(current_user.id, @event_build, payload)
        end
      end)
  end

  defp run_rebuild_for(project, branch_name, trigger, progress_callback) do
    progress_callback.("scheduling")

    branch_name = branch_name || project.default_branch

    Project.ensure_repo(project, [branch_name])
    {git_repo, git_branch} = Refaktor.UseCase.Git.get_repo_and_branch(project.clone_url, branch_name)

    opts = [
      trigger: trigger,
      jobs: [Refaktor.Job.Elixir.Deps],
      meta: [
        trigger: trigger,
        project_id: project.id,
        git_repo_id: git_repo.id,
        git_branch_id: git_branch.id,
        use_lock_file: project.use_lock_file,
        progress_callback: progress_callback
      ]
    ]

    spawn fn ->
      Refaktor.Builder.add_and_run_repo(git_repo.url, git_branch.name, opts)
    end
  end
end
