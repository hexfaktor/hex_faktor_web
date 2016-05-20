defmodule HexFaktor.BadgeController do
  use HexFaktor.Web, :controller

  alias HexFaktor.DepsObjectFilter
  alias HexFaktor.ProjectBuilder
  alias HexFaktor.ProjectProvider
  alias HexFaktor.BadgeView

  @trigger_badge_request "badge_request"
  @bar_width  40
  @grades     ["A", "D", "B", "C"]
  @valid_styles ["default", "flat-square"]

  def all_deps_github(conn, %{"owner" => owner, "name" => name} = params) do
    name = name |> String.replace(~r/\.svg$/, "")
    all_deps(conn, %{"provider" => "github", "name" => "#{owner}/#{name}", "branch" => params["branch"], "style" => params["style"]})
  end

  def all_deps(conn, %{"provider" => provider, "name" => name, "branch" => branch, "style" => style}) do
    #badge_source = nil # TODO: load from cache
    #if is_nil(badge_source) do
      badge_source = perform_all_deps(conn, %{"provider" => provider, "name" => name, "branch" => branch, "style" => style})
      # TODO: put into cache
    #end

    conn
    |> put_resp_content_type("image/svg+xml")
    |> send_resp(200, badge_source)
  end

  defp perform_all_deps(_conn, %{"provider" => _, "name" => _, "branch" => _, "style" => style} = params) do
    {project, branch} = ProjectProvider.project_and_branch(params)
    {build, _, deps_objects} = ProjectProvider.latest_successful_evaluation(branch)

    ProjectBuilder.run_if_was_never_built(build, project, branch, @trigger_badge_request)

    prod_deps = deps_objects |> Enum.filter(&prod_dep?/1)
    not_prod_deps = deps_objects |> Enum.filter(&not_prod_dep?/1)

    outdated_prod_deps =
      prod_deps
      |> DepsObjectFilter.filter_outdated(project.use_lock_file)
    outdated_not_prod_deps =
      not_prod_deps
      |> DepsObjectFilter.filter_outdated(project.use_lock_file)

    total_count = Enum.count(deps_objects)
    counts =
      [
        Enum.count(prod_deps) - Enum.count(outdated_prod_deps),
        Enum.count(outdated_prod_deps),
        Enum.count(not_prod_deps) - Enum.count(outdated_not_prod_deps),
        Enum.count(outdated_not_prod_deps),
      ]
    percentages_and_grades =
      if total_count == 0 do
        nil
      else
        counts
        |> Enum.map(&(&1/total_count))
        |> Enum.with_index
        |> Enum.map(fn({percentage, index}) ->
            {percentage, Enum.at(@grades, index)}
          end)
        |> add_x_positions(@bar_width, [], 0)
      end

    assigns = [
      bar_width: @bar_width,
      percentages_and_grades: percentages_and_grades
    ]
    render_badge_to_string(:all_deps, to_style(style), assigns)
  end

  #
  #
  #

  def prod_deps_github(conn, %{"owner" => owner, "name" => name} = params) do
    name = name |> String.replace(~r/\.svg$/, "")
    prod_deps(conn, %{"provider" => "github", "name" => "#{owner}/#{name}", "branch" => params["branch"], "style" => params["style"]})
  end

  def prod_deps(conn, %{"provider" => provider, "name" => name, "branch" => branch, "style" => style}) do
    #badge_source = nil # TODO: load from cache
    #if is_nil(badge_source) do
      badge_source = perform_prod_deps(conn, %{"provider" => provider, "name" => name, "branch" => branch, "style" => style})
      # TODO: put into cache
    #end

    conn
    |> put_resp_content_type("image/svg+xml")
    |> send_resp(200, badge_source)
  end

  defp perform_prod_deps(_conn, %{"provider" => _, "name" => _, "branch" => _, "style" => style} = params) do
    {project, branch} = ProjectProvider.project_and_branch(params)
    {build, _, deps_objects} = ProjectProvider.latest_successful_evaluation(branch)

    ProjectBuilder.run_if_was_never_built(build, project, branch, @trigger_badge_request)

    prod_deps = deps_objects |> Enum.filter(&prod_dep?/1)
    not_prod_deps = []
    deps_objects = prod_deps

    outdated_prod_deps =
      prod_deps
      |> DepsObjectFilter.filter_outdated(project.use_lock_file)
    outdated_not_prod_deps =
      not_prod_deps
      |> DepsObjectFilter.filter_outdated(project.use_lock_file)

    total_count = Enum.count(deps_objects)
    counts =
      [
        Enum.count(prod_deps) - Enum.count(outdated_prod_deps),
        Enum.count(outdated_prod_deps),
        Enum.count(not_prod_deps) - Enum.count(outdated_not_prod_deps),
        Enum.count(outdated_not_prod_deps),
      ]
    percentages_and_grades =
      if total_count == 0 do
        nil
      else
        counts
        |> Enum.map(&(&1/total_count))
        |> Enum.with_index
        |> Enum.map(fn({percentage, index}) ->
            {percentage, Enum.at(@grades, index)}
          end)
        |> add_x_positions(@bar_width, [], 0)
      end

    assigns = [
      bar_width: @bar_width,
      percentages_and_grades: percentages_and_grades
    ]
    render_badge_to_string(:prod_deps, to_style(style), assigns)
  end

  #
  #
  #

  def add_x_positions([], _bar_width, acc_list, _acc_x) do
    acc_list |> Enum.reverse
  end
  def add_x_positions([{percentage, grade}|tail], bar_width, acc_list, acc_x) do
    add_x_positions(tail, bar_width, [{percentage, grade, acc_x}|acc_list], acc_x + bar_width * percentage)
  end

  def prod_dep?(dep) do
    Enum.member?(dep.mix_envs, "prod") || Enum.count(dep.mix_envs) == 0
  end

  def not_prod_dep?(dep) do
    !prod_dep?(dep)
  end

  #
  # /hex badge
  #

  def hex_github(conn, %{"owner" => owner, "name" => name} = params) do
    name = name |> String.replace(~r/\.svg$/, "")
    hex(conn, %{"provider" => "github", "name" => "#{owner}/#{name}", "branch" => params["branch"]})
  end

  def hex(conn, %{"provider" => provider, "name" => name, "branch" => branch}) do
    #badge_source = nil # TODO: load from cache
    #if is_nil(badge_source) do
      badge_source = perform_hex(conn, %{"provider" => provider, "name" => name, "branch" => branch})
      # TODO: put into cache
    #end

    conn
    |> put_resp_content_type("image/svg+xml")
    |> send_resp(200, badge_source)
  end

  defp perform_hex(_conn, _) do
    style = "default"
    render_badge_to_string(:hex, style, [])
  end

  defp render_badge_to_string(type, style, assigns) do
    Phoenix.View.render_to_string(BadgeView, "#{type}--#{style}.svg", assigns)
  end

  defp to_style(nil), do: "default"
  defp to_style(style) when style in @valid_styles, do: style
  defp to_style(_), do: to_style(nil)
end
