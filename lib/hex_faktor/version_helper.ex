defmodule HexFaktor.VersionHelper do
  @doc """
  Returns the kind of update for the newest release.
  """
  def kind_of_release(%{releases: releases}) do
    releases
    |> newest_version
    |> kind_of_release
  end
  def kind_of_release(latest_version) do
    case Version.parse(latest_version) do
      {:ok, v} ->
        kind_of_release(v.major, v.minor, v.patch, v.pre)
      _ ->
        nil
    end
  end
  def kind_of_release(_, 0, 0, []), do: :major
  def kind_of_release(_, _, 0, []), do: :minor
  def kind_of_release(_, _, _, []), do: :patch
  def kind_of_release(_, _, _, _), do: :pre

  @doc """
  Returns the version number of the latest release (in terms of `updated_at`).
  """
  def newest_version(%{releases: releases}) do
    newest_version(releases)
  end
  def newest_version(releases) when is_list(releases) do
    hash =
      releases
      |> Enum.sort_by(&(&1["updated_at"]))
      |> List.last
    hash["version"]
  end

  def matching?(nil, _), do: false
  def matching?(_, nil), do: false
  def matching?(%{required_version: requirement}, version) do
    matching?(requirement, version)
  end
  def matching?(requirement, version) do
    version
    |> Version.parse_requirement
    |> case do
      {:ok, requirement} -> Version.matches?(requirement, version)
      _ -> false
    end
  end
end
