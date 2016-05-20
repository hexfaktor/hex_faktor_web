defmodule Mix.Tasks.Docker.Build do
  use Mix.Task

  @shortdoc  "Build all Docker images"
  @moduledoc @shortdoc

  @dockerfile_dir "dockerfiles"

  def run(argv \\ nil) do
    case argv do
      [] -> all_image_names
      list -> list
    end
    |> build_images
  end

  defp all_image_names do
    @dockerfile_dir
    |> Path.join("*")
    |> Path.wildcard
    |> Enum.filter(&File.dir?/1)
    |> Enum.map(&Path.basename/1)
  end

  defp build_images([]), do: nil
  defp build_images([name|tail]) do
    IO.puts "Building #{name} ..."
    build_image(name)
    build_images(tail)
  end

  defp build_image(name) do
    Path.join(@dockerfile_dir, name)
    |> Refaktor.Docker.build(["-t", name])
  end
end
