defmodule HexSonar do
  alias Refaktor.Util.JSON

  @server_and_port Application.get_env(:hex_faktor, :hex_server)
  @url "#{@server_and_port}/api/packages/:name"

  def load(name) do
    load_json(name)
  end

  defp load_json(name) do
    url = @url |> String.replace(":name", name |> to_string)
    case load_url(url) do
      {:ok, map} -> map
      {:error, error} -> IO.inspect error
    end
  end

  defp load_url(url) do
    # IO.puts "Getting url: #{url}"
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, JSON.parse(body)}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, 404}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
