defmodule Refaktor.Worker.ProgressCallback do
  @callback_converter Application.get_env(:hex_faktor, :progress_callback_converter, __MODULE__.NoopCallback)

  def cast(progress_callback_data) do
    @callback_converter.cast(progress_callback_data)
  end

  defmodule NoopCallback do
    def cast(progress_callback_data) do
      fn(status) ->
        IO.inspect {status, progress_callback_data}
      end
    end
  end
end
