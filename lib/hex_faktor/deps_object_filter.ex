defmodule HexFaktor.DepsObjectFilter do
  @doc "Returns all outdated deps out of a given list."
  def filter_outdated(deps, nil), do: filter_outdated(deps, false)
  def filter_outdated(deps, true) do
    reject_severities(deps, ["none"])
  end
  def filter_outdated(deps, false) do
    reject_severities(deps, ["none", "new_release_within_req"])
  end

  defp reject_severities(deps, rejected_severities) do
    deps
    |> Enum.filter(&(&1.toplevel && !(&1.severity in rejected_severities)))
  end


  def filter_unknown(deps) do
    deps
    |> Enum.filter(&unknown_dep?/1)
  end

  # unknown in this context means "unknown severity status"
  # TODO: maybe we should have :unknown as actual severity value?
  defp unknown_dep?(dep) do
    dep.available_versions |> Enum.empty?
  end

  def current_mix_env?([], "prod"), do: true
  def current_mix_env?([], _current), do: false
  def current_mix_env?(list, current) when is_list(list) do
    list |> Enum.any?(&current_mix_env?(&1, current))
  end
  def current_mix_env?(a, a), do: true
  def current_mix_env?(_env, nil), do: true
  def current_mix_env?(nil, _current), do: false
  def current_mix_env?(_env, _current), do: false
end
