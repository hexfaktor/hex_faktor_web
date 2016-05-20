defmodule Refaktor.Docker.RunTest do
  use ExUnit.Case

  @moduletag :refaktor

  @test_image "faktor-test-image"

  test "returns echoed output" do
    result = Refaktor.Docker.Run.call(@test_image, ["echo", "this is a mix test run"])
    assert {:ok, "this is a mix test run\n"} == result
  end

  # if this test times out, it means that :kill_after does not work properly
  @tag timeout: 10000
  test "kills container after given period" do
    {_,_,number} = :os.timestamp
    name = "faktor-test-#{number}"
    result = Refaktor.Docker.Run.call(@test_image, ["sleep", "60"], [], [kill_after: 2000, name: name])

    {:timeout, {{output_top, 0}, {output_kill, 0}}} = result
    assert String.length(output_top) > 0
    assert name == String.strip(output_kill)
  end

  test "works when command exits with != 0" do
    result = Refaktor.Docker.Run.call(@test_image, ["bash", "-c \"exit 5\""])
    {:error, _, code} = result
    refute 0 == code
  end
end
