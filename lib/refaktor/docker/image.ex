defmodule Refaktor.Docker.Image do
  def exists?(image, opts \\ []) do
    case run(image, opts) do
      {output, 0} -> {:ok, output}
      {output, x} -> {:error, output, x}
    end
  end

  defp run(image, opts) do
    System.cmd("docker", List.flatten(["build", opts, image]))
  end
end
