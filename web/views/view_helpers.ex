defmodule HexFaktor.ViewHelpers do
  defmacro __using__(_) do
    quote do
      @base_url Application.get_env(:hex_faktor, :base_url)
      @hex_faktor_repo_url Application.get_env :hex_faktor, :hex_faktor_repo_url

      def class_with_error(form, field, base_class) do
        if error_on_field?(form, field) do
          "#{base_class} error"
        else
          base_class
        end
      end

      def error_on_field?(form, field) do
        Enum.map(form.errors, fn({attr, _message}) -> attr end)
        |> Enum.member?(field)
      end

      def hex_faktor_repo_url, do: @hex_faktor_repo_url
      def hex_faktor_issues_url, do: "#{hex_faktor_repo_url}/issues"

      def link_project(project) do
        link project.name, to: project_url(project)
      end

      def badge_url(project, type) do
        "#{@base_url}/badge/#{type}/#{project.provider}/#{project.name}.svg"
      end

      def project_url(project) do
        "#{@base_url}/#{project.provider}/#{project.name}"
      end

      def build_job_duration(build_job) do
        if build_job.finished_at do
          secs =
            Timex.Date.diff(
              build_job.inserted_at |> Ecto.DateTime.to_erl |> Timex.Date.from,
              build_job.finished_at |> Ecto.DateTime.to_erl |> Timex.Date.from,
              :secs)
          "#{secs} secs"
        end
      end

      def mix_envs_for_notifications(notifications) do
        notifications
        |> Enum.map(&(&1.deps_object))
        |> Enum.reject(&is_nil/1)
        |> Enum.map(&(&1.mix_envs))
        |> Enum.flat_map(fn(envs) ->
            if envs == [] do
              ["prod"]
            else
              envs
            end
          end)
        |> Enum.uniq
        |> Enum.sort
        |> HexFaktor.SortHelper.ensure_order(["prod"], ["test"])
      end

      def time_ago_in_words(nil), do: nil
      def time_ago_in_words(time1) do
        case time_elapsed(time1) do
          nil -> nil
          seconds ->
            in_words =
              {0, seconds, 0}
              |> Timex.Format.Time.Formatters.Humanized.format
              |> String.replace(~r/(\d+ (day|hour|minute|second)s)(\,\ .+)$/, "\\1")
              #|> String.replace(~r/(\,\ \d+ (day|hour|minute|second))s$/, "")
              |> String.replace(~r/(1 (day|hour|minute|second))s/, "\\1")

            "#{in_words} ago"
        end
      end

      def time_elapsed(time1) do
        {_, seconds, _} =
          try do
              time1
              |> Ecto.DateTime.to_erl
              |> Timex.Date.from
              |> Timex.Date.to_timestamp
              |> Timex.Time.elapsed
          rescue
            _ ->
              {nil, nil, nil}
          end

        seconds
      end

    end
  end
end
