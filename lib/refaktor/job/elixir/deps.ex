defmodule Refaktor.Job.Elixir.Deps do
  alias HexFaktor.DepsObjectFilter
  alias HexFaktor.NotificationPublisher
  alias HexFaktor.NotificationResolver
  alias Refaktor.Job
  alias Refaktor.Job.Elixir.Deps.Persistence
  alias Refaktor.Worker.ProgressCallback

  @behaviour Job

  # defined according to /dockertools/bin/run-elixir-deps
  @stderr_log "stderr.log"

  @trigger_web_post "manual"

  def language, do: "elixir"
  def intent, do: "deps"
  def image_to_run, do: "faktor-#{language}"
  def script_to_run, do: "run-#{language}-#{intent}"

  def handle_success(job_id, job_dir, _output, meta) do
    trigger = meta["trigger"]
    project_id = meta["project_id"]
    git_repo_id = meta["git_repo_id"]
    git_branch_id = meta["git_branch_id"]
    use_lock_file = meta["use_lock_file"]
    progress_callback = ProgressCallback.cast(meta["progress_callback_data"])

    case Job.read_result(job_dir) do
      {:error, error, info} ->
        {:error, error, info}
      result_json ->
        case save_job_result!(job_id, project_id, git_repo_id, git_branch_id, result_json) do
          {:ok, deps} ->
            if trigger != @trigger_web_post do
              deps
              |> DepsObjectFilter.filter_outdated(use_lock_file)
              |> NotificationPublisher.handle_new_deps_objects(git_branch_id)
            end

            deps
            |> DepsObjectFilter.filter_outdated(use_lock_file)
            |> NotificationResolver.handle_existing_notifications(job_id, git_branch_id)

            progress_callback.("success")

            # now we have the deps that need to be updated and their
            # "classification", i.e. why they should be
            {}
          {:error, reason} ->
            {:error, reason}
          val ->
            {:save_job_result_failed, val}
        end
    end
  end
  def handle_error(_job_id, _hub_dir, output, exit_code, meta) do
    progress_callback = ProgressCallback.cast(meta["progress_callback_data"])
    progress_callback.("error")
    {exit_code, output}
  end
  def handle_timeout(_job_id, _hub_dir, _summary, meta) do
    progress_callback = ProgressCallback.cast(meta["progress_callback_data"])
    progress_callback.("timeout")
    {}
  end

  defp save_job_result!(_job_id, _project_id, _git_repo_id, _git_branch_id, %{"error" => error}) do
    {:error, error}
  end
  defp save_job_result!(job_id, project_id, git_repo_id, git_branch_id, %{"objects" => objects}) do
    #try do
      objects =
        objects
        |> Enum.map(&update_versions_and_severity/1)
      Persistence.write(job_id, project_id, git_repo_id, git_branch_id, objects)
    #rescue
    #  err -> err
    #end
  end

  def update_versions_and_severity(object) do
    locked_version = object["locked_version"]
    required_version = object["required_version"]

    available_versions =
      object["available_versions"]
      |> sort_versions
      |> Enum.reject(&pre_version?/1)
      |> Enum.reverse # so newer versions are at the beginning

    versions =
      available_versions
      |> Enum.map(fn(version) ->
          {version, outdated(version, locked_version, required_version)}
        end)

    newest_version = available_versions |> List.first
    newest_version_meeting_req =
      versions
      |> Enum.find_value(fn({version, type}) ->
          if type == :newer_match do
            version
          else
            nil
          end
        end)

    if is_nil(newest_version_meeting_req) do
      newest_version_meeting_req = locked_version
    end

    severity =
      severity_for(locked_version, newest_version_meeting_req, newest_version)

    object
    |> Map.update!("available_versions", &sort_versions/1)
    |> Map.put("severity", severity)
  end

  def sort_versions(versions) do
    versions
    |> List.wrap
    |> Enum.sort(fn(a, b) ->
        Enum.member?([:gt, :eq], Version.compare(a, b))
      end)
    |> Enum.reverse
  end

  defp pre_version?(version) do
    case Version.parse(version) do
      {:ok, %Version{pre: []}} -> false # no pre version
      _ -> true
    end
  end

  defp severity_for(a, a, a) do
    :none
  end
  defp severity_for(a, a, nil) do
    # no newest_version probably always means it is a git-dependency
    :none
  end
  defp severity_for(locked_version, locked_version, newest_version) do
    if pre_version?(locked_version) do
      case Version.compare(locked_version, newest_version) do
        :lt ->
          # locked_version is a pre version and the newest regular version
          # is more recent than the locked version
          :newer_major_release
        _ ->
          # locked_version is a pre version and the newest regular version
          # is older than that
          :none
      end
    else
      # there is a newer release outside the specified requirements
      :newer_major_release
    end
  end
  defp severity_for(_locked_version, a, a) do
    # there is a newer release within the specified requirements
    :new_release_within_req
  end
  defp severity_for(_locked_version, _newest_version_meeting_req, _newest_version) do
    # there is a newer release
    :new_release_within_req_and_major
  end

  def outdated(version, locked_version, nil) do
    comp = Version.compare(version, locked_version)
    classify(comp, true)
  end
  def outdated(version, locked_version, required_version) do
    comp = Version.compare(version, locked_version)
    match = Version.match?(version, required_version)
    classify(comp, match)
  end

  defp classify(:lt, _), do: :older
  defp classify(:eq, _), do: :current
  defp classify(:gt, true), do: :newer_match
  defp classify(:gt, false), do: :newer_nomatch
end
