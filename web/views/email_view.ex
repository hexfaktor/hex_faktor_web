defmodule HexFaktor.EmailView do
  use HexFaktor.Web, :view

  def button_link(text, url) do
    ~s(<a href="#{url}" class="btn-primary" style="font-family: 'Helvetica Neue',Helvetica,Arial,sans-serif; box-sizing: border-box; font-size: 14px; color: #FFF; text-decoration: none; line-height: 2em; font-weight: bold; text-align: center; cursor: pointer; display: inline-block; border-radius: 5px; text-transform: capitalize; background-color: #87AE10; margin: 0; border-color: #87AE10; border-style: solid; border-width: 10px 20px;">#{text}</a>)
  end

  def highlight_after_slash(project_name) do
    parts = project_name |> String.split("/")
    raw "#{parts |> List.first}/<strong>#{parts |> List.last}</strong>"
  end

  def mix_env_colors("prod"), do: "color: #fff; background: #F9BE33;"
  def mix_env_colors(_env), do: "color: #bf616a; background: #FFF184;"


  def project_style(%HexFaktor.Project{outdated_deps: nil}) do
    require Logger
    Logger.warn "Project has unset `outdated_deps`!"
    nil
  end
  def project_style(project) do
    outdated_mix_envs =
      project.outdated_deps
      |> Enum.flat_map(fn(deps_object) ->
          case deps_object.mix_envs do
            nil -> ["prod"]
            [] -> ["prod"]
            list -> list
          end
        end)

    env_class = project_style_for_envs(outdated_mix_envs)
    active_class =
      if project.active do
        "active"
      else
        "not-active"
      end

    "padding: 10px; border: 1px solid #fff; border-left: 2px solid #eee; #{active_class |> inline_style()} #{env_class |> inline_style()}"
  end

  defp project_style_for_envs([]) do
    "up-to-date"
  end
  defp project_style_for_envs(outdated_mix_envs) do
    if outdated_mix_envs |> Enum.any?(&(&1 == "prod")) do
      "outdated--prod"
    else
      "outdated--not-prod"
    end
  end

  def inline_style("up-to-date"), do: "border-left-color: #8c3;"
  def inline_style("outdated--prod") do
    "border-left-color: #FF911D; background: #fff4e9;"
  end
  def inline_style("outdated--not-prod") do
    "border-left-color: #FFE100; background: #fffad6;"
  end
  def inline_style(_), do: ""

end
