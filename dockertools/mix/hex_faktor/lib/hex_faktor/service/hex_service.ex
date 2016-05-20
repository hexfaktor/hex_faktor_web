defmodule HexFaktor.Service.HexService do
  alias HexFaktor.Util.JSON

  @servers Application.get_env(:hex_faktor, :hex_servers)
  @url ":server/api/packages/:name"

  def available_versions(name) do
    case load_json(name) do
      {:error, _error} ->
        []
      list ->
        list
        |> Enum.map(fn(%{"version" => version}) -> version end)
    end
  end

  defp load_json(name) do
    case load(name, @servers) do
      {:ok, map} -> map["releases"]
      {:error, error} ->
        IO.puts :stderr, inspect({:error, error})
        {:error, error}
    end
  end

  defp load(name, list, failed_servers \\ [])

  defp load(_name, [], _) do
    {:error, "All servers failed."}
  end
  defp load(name, [server|tail], failed_servers) do
    url =
      @url
      |> String.replace(":server", server |> to_string)
      |> String.replace(":name", name |> to_string)

    #IO.puts "Getting url: #{url}"

    result =
      case HTTPoison.get(url) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          {:ok, JSON.parse(body)}
        {:ok, %HTTPoison.Response{status_code: 404}} ->
          {:error, 404}
        {:ok, %HTTPoison.Response{status_code: 500}} ->
          {:error, 500}
        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end

    case result do
      {:ok, value} ->
        {:ok, value}
      {:error, _} ->
        :timer.sleep 1000
        load(name, tail, failed_servers ++ [server])
    end
  end
end
