defmodule HexFaktor.Deps do
  defstruct name: nil,
            source: nil,
            source_url: nil,
            toplevel: nil,
            locked_version: nil,
            required_version: nil,
            available_versions: nil,
            mix_envs: nil

  alias HexFaktor.MixExsLoader
  alias HexFaktor.MixLockLoader

  @lockfile "mix.lock"
  @projectfile "mix.exs"

  def compile(top_deps, all_deps, hex_service \\ HexFaktor.Service.HexService) do
    top_names =
      top_deps
      |> Enum.map(&name/1)

    all_deps =
      all_deps
      |> Enum.map(&to_struct(&1, top_deps, top_names))
      |> Enum.reject(&is_nil/1)
      |> Enum.filter(&(&1.toplevel)) # TODO: do we need the lowlevel deps?
      |> Enum.map(&add_available_versions(&1, hex_service))

    no_available_versions_loaded =
      all_deps
      |> Enum.flat_map(&(&1.available_versions |> List.wrap))
      |> Enum.empty?

    if all_deps |> Enum.any? && no_available_versions_loaded do
      {:error, :could_not_reach_hex_server}
    else
      {:ok, all_deps}
    end
  end

  defp to_struct({_name, {:package, _locked_version}}, _top, _top_names) do
    nil
  end
  defp to_struct({name, {:hex, name, locked_version, _locked_sha1, _build_tools, _opts}}, top, top_names) do
    to_struct({name, {:hex, name, locked_version}}, top, top_names)
  end
  defp to_struct({name, {:hex, name, locked_version}}, top, top_names) do
    %__MODULE__{
      name: name,
      toplevel: top_names |> Enum.member?(name),
      source: :hex,
      locked_version: locked_version
    }
    |> add_version_requirement(top)
    |> add_mix_envs(top)
  end
  defp to_struct({name, {:git, git_url, locked_sha1, _opts}}, top, top_names) do
    %__MODULE__{
      name: name,
      toplevel: top_names |> Enum.member?(name),
      source: :git,
      source_url: git_url,
      locked_version: locked_sha1
    }
    |> add_version_requirement(top)
    |> add_mix_envs(top)
  end

  def toplevel(project_dir) do
    filename = project_dir |> Path.join(@projectfile)
    case File.read(filename) do
      {:ok, contents} ->
        {:ok, MixExsLoader.parse(contents)}
      _ ->
        {:error, "file_not_found: mix.lock"}
    end
  end

  def all(project_dir) do
    filename = project_dir |> Path.join(@lockfile)
    case File.read(filename) do
      {:ok, contents} ->
        {:ok, MixLockLoader.parse(contents)}
      _ ->
        {:error, "file_not_found: mix.lock"}
    end
  end

  def name(tuple) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list
    |> List.first
  end

  defp add_version_requirement(%__MODULE__{name: name} = dep, top) do
    requirement =
      top
      |> Enum.find_value(&find_version_requirement(&1, name))
    %__MODULE__{dep | required_version: requirement}
  end

  def find_version_requirement({name, requirement}, name) when is_binary(requirement) do
    requirement
  end
  def find_version_requirement({name, requirement, _}, name) when is_binary(requirement) do
    requirement
  end
  def find_version_requirement(_, _name), do: nil

  defp add_available_versions(%__MODULE__{source: :hex, name: name} = dep, hex_service) do
    %__MODULE__{dep | available_versions: hex_service.available_versions(name)}
  end
  defp add_available_versions(%__MODULE__{} = dep, _hex_service) do
    dep
  end

  defp add_mix_envs(%__MODULE__{name: name} = dep, top) do
    options =
      top
      |> Enum.find_value(&find_options(&1, name))
    %__MODULE__{dep | mix_envs: options[:only] |> List.wrap}
  end

  def find_options({name, options}, name) when is_list(options) do
    options
    |> Enum.into(%{})
  end
  def find_options({name, _requirement, options}, name) when is_list(options) do
    options
    |> Enum.into(%{})
  end
  def find_options(_, _name), do: nil


  def outdated(version, locked_version, required_version) do
    comp = Version.compare(version, locked_version)
    match = Version.match?(version, required_version)
    classify(comp, match)
  end

  def classify(:lt, _), do: :older
  def classify(:eq, _), do: :current
  def classify(:gt, true), do: :newer_match
  def classify(:gt, false), do: :newer_nomatch

end
