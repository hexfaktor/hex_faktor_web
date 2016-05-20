defmodule TestOutputJob do
  @behaviour Refaktor.Job

  def language, do: "shell"
  def intent, do: "testing"
  def image_to_run, do: "faktor-test-image"
  def script_to_run, do: "test-output"
  def handle_success(_job_id, _hub_dir, _output, _meta), do: {}
  def handle_error(_job_id, _hub_dir, output, exit_code, _meta), do: {exit_code, output}
  def handle_timeout(_job_id, _hub_dir, _summary, _meta), do: {}
end

defmodule TestErrorJob do
  @behaviour Refaktor.Job

  def language, do: "shell"
  def intent, do: "testing"
  def image_to_run, do: "faktor-test-image"
  def script_to_run, do: "test-error"
  def handle_success(_job_id, _hub_dir, _output, _meta), do: {}
  def handle_error(_job_id, _hub_dir, output, exit_code, _meta), do: {exit_code, output}
  def handle_timeout(_job_id, _hub_dir, _summary, _meta), do: {}
end

defmodule TestCommandNotFoundJob do
  @behaviour Refaktor.Job

  def language, do: "shell"
  def intent, do: "testing"
  def image_to_run, do: "faktor-test-image"
  def script_to_run, do: "test-error-this-command-does-not-exist"
  def handle_success(_job_id, _hub_dir, _output, _meta), do: {}
  def handle_error(_job_id, _hub_dir, output, exit_code, _meta), do: {exit_code, output}
  def handle_timeout(_job_id, _hub_dir, _summary, _meta), do: {}
end

defmodule TestCommandProducesBadJSONJob do
  @behaviour Refaktor.Job

  def language, do: "shell"
  def intent, do: "testing"
  def image_to_run, do: "faktor-test-image"
  def script_to_run, do: "test-produce-bad-result-json"
  def handle_success(_job_id, hub_dir, output, _meta) do
    case Refaktor.Job.read_result(hub_dir) do
      {:error, _, _} = error_tuple -> error_tuple
      map -> {map, output}
    end
  end
  def handle_error(_job_id, _hub_dir, output, exit_code, _meta), do: {exit_code, output}
  def handle_timeout(_job_id, _hub_dir, _summary, _meta), do: {}
end
