defmodule HexFaktor.ProjectProvider do
  alias Refaktor.Job.Elixir.Deps.Persistence

  alias Refaktor.Persistence.BuildJob
  alias HexFaktor.Persistence.Project
  alias HexFaktor.DepsObjectFilter
  alias HexFaktor.ProjectAccess
  alias HexFaktor.ProjectBuilder
  alias HexFaktor.ProjectSyncer
  alias HexFaktor.Persistence.ProjectUserSettings

  @default_branch "master"

  @filter_outdated "outdated"
  @filter_unknown "unknown"
  @trigger_http_request "http_request"

  def user_projects(current_user) do
    project_user_settings = ProjectUserSettings.find_by_user_id(current_user.id)

    all_projects =
      current_user
      |> Project.all_for([:git_repo_branches, :project_hooks])
      |> mark_outdated_projects(project_user_settings)

    active_projects =
      all_projects
      |> Enum.filter(&(&1.active))
    outdated_projects =
      active_projects
      |> Enum.filter(&(&1.outdated_deps |> Enum.any?))

    {all_projects, active_projects, outdated_projects}
  end

  def mark_outdated_projects(projects, project_user_settings) do
    branch_ids =
      projects
      |> Enum.flat_map(&get_active_branches(&1, project_user_settings))
      |> Enum.map(&(&1.id))

    build_job_ids =
      branch_ids
      |> Refaktor.Persistence.BuildJob.latest_ids_with_status("success")

    deps_objects =
      build_job_ids
      |> Refaktor.Job.Elixir.Deps.Persistence.find_by_job_ids()

    projects
    |> Enum.map(&Task.async(fn -> inject_outdated_field!(&1, deps_objects) end))
    |> Enum.map(&Task.await(&1, 30_000))
  end

  defp get_active_branches(project, project_user_settings) when is_list(project_user_settings) do
    settings =
      project_user_settings
      |> Enum.find(&(&1.project_id == project.id))
    get_active_branches(project, settings)
  end
  defp get_active_branches(project, nil) do
    []
  end
  defp get_active_branches(project, settings) do
    project.git_repo_branches
    |> Enum.filter(fn(branch) ->
        settings.notification_branches |> Enum.member?(branch.name)
      end)
  end

  defp inject_outdated_field!(project, all_deps_objects) do
    deps_objects =
      all_deps_objects
      |> Enum.filter(&(&1.project_id == project.id))
      |> DepsObjectFilter.filter_outdated(project.use_lock_file)

    %HexFaktor.Project{project | outdated_deps: deps_objects}
  end

  def project_and_branch(%{"provider" => provider, "name" => name} = params) do
    project = find_by_provider_or_create_via_api(provider, name, [:git_repo, :git_repo_branches, :project_hooks])
    branch_name = nil_if_empty(params["branch"]) || project.default_branch || @default_branch

    branch =
      project.git_repo_branches
      |> Enum.find(&(&1.name == branch_name))

    {project, branch}
  end

  def find_by_provider_or_create_via_api(provider, name, preload_list) do
    Project.find_by_provider_and_name(provider, name, preload_list)
    |> case do
        nil -> create_by_provider_and_name(provider, name, preload_list)
        project -> project
      end
  end

  def create_by_provider_and_name("github", name, preload_list) do
    project =
      GitHubAuth.access_token
      |> ProjectSyncer.sync_project_via_github!(name)
    Project.find_by_id(project.id, preload_list)
  end

  @doc "Returns Build, BuildJob, DepsObjects for the last build."
  def latest_evaluation(nil), do: {nil, nil, []}
  def latest_evaluation(branch) do
    build_job = BuildJob.latest(branch.id, [:build])
    {get_build(build_job), build_job, get_deps_objects(build_job)}
  end

  @doc "Returns Build, BuildJob, DepsObjects for the last successful build."
  def latest_successful_evaluation(nil), do: {nil, nil, []}
  def latest_successful_evaluation(branch) do
    build_job = BuildJob.latest_with_status(branch.id, "success", [:build])
    {get_build(build_job), build_job, get_deps_objects(build_job)}
  end

  defp get_build(nil), do: nil
  defp get_build(build_job), do: build_job.build

  defp get_deps_objects(nil), do: []
  defp get_deps_objects(build_job), do: Persistence.find_by_job_id(build_job.id)

  defp nil_if_empty(""), do: nil
  defp nil_if_empty(val), do: val

  @doc """

  """
  def assigns_for(current_user, %{"provider" => provider, "name" => name} = params) do
    {project, branch} = project_and_branch(params)

    current_mix_env = params["env"] |> nil_if_empty
    current_deps_filter = params["filter"] |> nil_if_empty

    assigns_for(current_user, project, branch, current_mix_env, current_deps_filter)
  end
  def assigns_for(_current_user, project, nil, current_mix_env, current_deps_filter) do
    [
      project: project,
      user_can_edit?: false,
      branch: nil,
      build: nil,
      build_job: nil,
      current_mix_env: current_mix_env,
      current_deps_filter: current_deps_filter,
      mix_envs: [],
      deps_objects: [],
      deps_total_count: 0,
      deps_outdated_count: 0,
      deps_unknown_count: 0,
      enqueued_build?: false,
      unsynced_project?: unsynced_project?(project),
      github_hook_active?: project.project_hooks |> Enum.any?(&(&1.active))
    ]
  end
  def assigns_for(current_user, project, branch, current_mix_env, current_deps_filter) do
    {build, build_job, all_deps_objects} = latest_successful_evaluation(branch)

    run_pid = ProjectBuilder.run_if_was_never_built(build, project, branch, @trigger_http_request, current_user)

    # if the latest succesful (!) build is empty, then load the latest
    # potentially failed build
    if build_job |> is_nil do
      {_, build_job, _} = latest_evaluation(branch)
    end


    project = project |> inject_outdated_field!(all_deps_objects)
    deps_outdated = project.outdated_deps

    deps_unknown =
      all_deps_objects
      |> DepsObjectFilter.filter_unknown()

    deps_total_count = Enum.count(all_deps_objects)
    deps_outdated_count = Enum.count(deps_outdated)
    deps_unknown_count = Enum.count(deps_unknown)

    mix_envs =
      all_deps_objects
      |> Enum.flat_map(&(&1.mix_envs))
      |> Enum.uniq
      |> Enum.sort

    if all_deps_objects |> Enum.any?(&DepsObjectFilter.current_mix_env?(&1.mix_envs, "prod")) do
      mix_envs = ["prod" | mix_envs]
    end

    deps_objects =
      case current_deps_filter do
        @filter_outdated -> deps_outdated
        @filter_unknown -> deps_unknown
        _ -> all_deps_objects
      end

    if !is_nil(current_mix_env) do
      deps_objects =
        deps_objects
        |> Enum.filter(&DepsObjectFilter.current_mix_env?(&1.mix_envs, current_mix_env))
    end

    user_can_edit? =
      current_user && ProjectAccess.granted?(project.id, current_user)

    [
      project: project,
      user_can_edit?: user_can_edit?,
      branch: branch,
      build: build,
      build_job: build_job,
      current_mix_env: current_mix_env,
      current_deps_filter: current_deps_filter,
      mix_envs: mix_envs,
      deps_objects: deps_objects,
      deps_total_count: deps_total_count,
      deps_outdated_count: deps_outdated_count,
      deps_unknown_count: deps_unknown_count,
      enqueued_build?: !is_nil(run_pid),
      unsynced_project?: unsynced_project?(project),
      github_hook_active?: project.project_hooks |> Enum.any?(&(&1.active))
    ]
  end

  @doc "Returns true if the project has not been synced with GitHub yet."
  def unsynced_project?(project) do
    project.last_github_sync |> is_nil()
  end
end
