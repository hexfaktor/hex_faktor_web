defmodule HexFaktor.ComponentView do
  use HexFaktor.Web, :view

  alias HExFaktor.VersionHelper

  @human_readable_severities %{
      # dep.project.use_lock_file == true
      true: %{
        "none" => "up-to-date",
      },
      # dep.project.use_lock_file == false
      false: %{
        "none" => "up-to-date",
        "new_release_within_req" => "up-to-date",
      }
    }
  @default_human_readable_severity "update"

  def human_readable_severity(dep, project) do
    @human_readable_severities[project.use_lock_file][dep.severity] ||
      @default_human_readable_severity
  end

  def matching_or_not(dep, release_version) do
    if dep |> VersionHelper.matching?(release_version) do
      "matching"
    else
      "not-matching"
    end
  end

  def prod_or_not(dep) do
    if dep.mix_envs |> Enum.empty? || dep.mix_envs == ["prod"] do
      "prod"
    else
      "not-prod"
    end
  end

  def use_lock_file_or_not(project) do
    if project.use_lock_file do
      "use_lock_file"
    else
      "not-use_lock_file"
    end
  end

  def outdated_or_not(dep, project) do
    if outdated?(dep.severity, project.use_lock_file) do
      "outdated"
    else
      "not-outdated"
    end
  end

  defp outdated?("none", _), do: false
  defp outdated?("new_release_within_req", false), do: false
  defp outdated?(_severity, _use_lock_file), do: true


  def newest_matching_version(versions, requirement) do
    versions
    |> reject_pre_versions()
    |> Enum.reverse
    |> Enum.find(&Version.match?(&1, requirement))
  end

  def newest_version(versions, include_pre_versions \\ false)
  def newest_version(versions, false) do
    versions
    |> reject_pre_versions()
    |> List.last
  end
  def newest_version(versions, true) do
    versions
    |> List.last
  end

  def newest_version_matches_requirement?(dep) do
    include_pre_versions = pre_version?(dep.locked_version)
    dep.available_versions
    |> newest_version(include_pre_versions)
    |> case do
        nil -> true
        val -> val |> Version.match?(dep.required_version)
      end
  end

  defp reject_pre_versions(versions) do
    versions
    |> Enum.reject(&pre_version?/1)
  end

  def pre_version?(version) do
    case Version.parse(version) do
      {:ok, %Version{pre: []}} -> false # no pre version
      {:ok, _} -> true
      _ -> false
    end
  end

  def pre_requirement?(nil), do: false
  def pre_requirement?(requirement) do
    versions =
      requirement
      |> String.split(~r/\s+(and|or)\s+/)
      |> Enum.map(&requirement_to_version/1)
      |> Enum.any?(&pre_version?/1)
  end

  defp requirement_to_version(requirement) do
    requirement
    |> String.replace(~r/[=~><\s]/, "")
  end



  def shorten_or_placeholder(string, placeholder \\ "-") do
    case string do
      nil -> placeholder
      val -> val |> String.slice(0..7)
    end
  end

  def project_list_item_classes(%HexFaktor.Project{outdated_deps: nil}) do
    require Logger
    Logger.warn "Project has unset `outdated_deps`!"
    nil
  end
  def project_list_item_classes(project) do
    outdated_mix_envs =
      project.outdated_deps
      |> Enum.flat_map(fn(deps_object) ->
          case deps_object.mix_envs do
            nil -> ["prod"]
            [] -> ["prod"]
            list -> list
          end
        end)

    env_class = project_list_item_class_for_envs(outdated_mix_envs)
    active_class =
      if project.active do
        "project-list-item--active"
      else
        "project-list-item--not-active"
      end

    "#{active_class} #{env_class}"
  end

  defp project_list_item_class_for_envs([]) do
    "project-list-item--up-to-date"
  end
  defp project_list_item_class_for_envs(outdated_mix_envs) do
    if outdated_mix_envs |> Enum.any?(&(&1 == "prod")) do
      "project-list-item--outdated--prod"
    else
      "project-list-item--outdated--not-prod"
    end
  end

end
