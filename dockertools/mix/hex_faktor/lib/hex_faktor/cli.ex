defmodule HexFaktor.CLI do
  alias HexFaktor.Deps

  @edge "|"

  def main(nil) do
    HexFaktor.Dummy.project[:ok]
  end
  def main([]) do
    IO.puts "Usage: hex_faktor <path> <options>"
  end
  def main(args) when is_list(args) do
    HTTPoison.start()

    {switches, files, []} =
      OptionParser.parse(args, switches: [:json])

    dir = files |> List.first

    load_mix_exs(dir, switches)
  end

  def load_mix_exs(dir, switches) do
    case Deps.toplevel(dir) do
      {:ok, []} ->
        compile_and_output_deps(switches, [], [])
      {:ok, nil} ->
        fail_and_output_error(switches, "unable_to_identify_deps")
      {:ok, top_deps} ->
        load_mix_lock(dir, switches, top_deps)
      {:error, error} ->
        fail_and_output_error(switches, error)
    end
  end

  def load_mix_lock(dir, switches, top_deps) do
    case Deps.all(dir) do
      {:ok, all_deps} ->
        compile_and_output_deps(switches, top_deps, all_deps)
      {:error, error} ->
        fail_and_output_error(switches, error)
    end
  end

  def compile_and_output_deps(switches, top_deps, all_deps) do
    case Deps.compile(top_deps, all_deps) do
      {:ok, result} ->
        result =
          result
          |> Enum.sort_by(&(&1.source))
          |> Enum.sort_by(&(&1.toplevel))

        if switches[:json] do
          result
          |> wrap_result_with_metadata
          |> Poison.encode!(pretty: true)
          |> IO.puts
        else
          print_separator

          result
          |> Enum.each(&print_row/1)

          print_separator
        end
      {:error, error} ->
        fail_and_output_error(switches, error)
    end
  end
  def fail_and_output_error(switches, error) do
    if switches[:json] do
      error
      |> wrap_error_with_metadata
      |> Poison.encode!(pretty: true)
      |> IO.puts
    else
      print_separator

      IO.puts "Error: #{error}"

      print_separator
    end
  end

  defp wrap_error_with_metadata(error) do
    %{
      :metadata => metadata,
      :error => error
    }
  end
  defp wrap_result_with_metadata(deps) do
    %{
      :metadata => metadata,
      :objects => deps
    }
  end

  defp metadata do
    %{tool_name: :hex_faktor, tool_version: HexFaktor.version}
  end

  @col_width_name 30
  @col_width_req_version 8
  @col_width_locked_version 6
  @col_width_newest_version 6

  defp print_row(%Deps{toplevel: true, source: :hex, name: name, locked_version: locked_version, required_version: required_version} = info) do
    available_versions =
      info.available_versions
      |> List.wrap
      |> Enum.sort
      |> Enum.reverse

    versions =
      available_versions
      |> Enum.map(fn(version) ->
          {version, HexFaktor.Deps.outdated(version, locked_version, required_version)}
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

    [
      @edge, " ", color(locked_version, newest_version_meeting_req, newest_version),
        name |> to_string |> String.ljust(@col_width_name), " ", IO.ANSI.reset,
      @edge, " ", color(locked_version, newest_version_meeting_req, newest_version),
        required_version |> to_string |> String.rjust(@col_width_req_version), " ", IO.ANSI.reset,
      @edge, " ", color(locked_version, newest_version_meeting_req, newest_version),
        locked_version |> to_string |> String.slice(0..@col_width_locked_version-1) |> String.ljust(@col_width_locked_version), " ", IO.ANSI.reset,
      @edge, " ", color(locked_version, newest_version_meeting_req, newest_version),
        newest_version_meeting_req |> to_string |> String.ljust(@col_width_newest_version), " ", IO.ANSI.reset,
      @edge, " ",
        newest_version |> to_string |> String.ljust(@col_width_newest_version), " ", IO.ANSI.reset,
      @edge
    ]
    |> IO.puts
  end
  defp print_row(%Deps{toplevel: true, source: :git, name: name, locked_version: locked_version, required_version: required_version}) do
    newest_version_meeting_req = "vX"
    newest_version = "vY"
    [
      @edge, " ", name |> to_string |> String.ljust(@col_width_name), " ",
      @edge, " ", required_version |> to_string |> String.rjust(@col_width_req_version), " ",
      @edge, " ", locked_version |> to_string |> String.slice(0..@col_width_locked_version-1) |> String.ljust(@col_width_locked_version), " ",
      @edge, " ", newest_version_meeting_req |> to_string |> String.ljust(@col_width_newest_version), " ",
      @edge, " ", newest_version |> to_string |> String.ljust(@col_width_newest_version), " ",
      @edge
    ]
    |> IO.puts
  end
  defp print_row(%Deps{toplevel: false}) do
  end

  defp print_separator do
    [
      "+", "-" |> String.duplicate(@col_width_name+2),
      "+", "-" |> String.duplicate(@col_width_req_version+2),
      "+", "-" |> String.duplicate(@col_width_locked_version+2),
      "+", "-" |> String.duplicate(@col_width_newest_version+2),
      "+", "-" |> String.duplicate(@col_width_newest_version+2),
      "+"
    ]
    |> IO.puts
  end

  def color(a, a, a) do
    IO.ANSI.green
  end
  def color(a, a, _newest_version) do
    IO.ANSI.green
  end
  def color(_locked_version, a, a) do
    IO.ANSI.yellow
  end
  def color(_locked_version, _newest_version_meeting_req, _newest_version) do
    IO.ANSI.white
  end

end
