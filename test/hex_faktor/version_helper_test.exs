defmodule HexFaktor.VersionHelperTest do
  use HexFaktor.ModelCase

  alias HexFaktor.Persistence.Package

  alias HexFaktor.VersionHelper

  defp test_package do
    %HexFaktor.Package{
       description: "A static code analysis tool for the Elixir language with a focus on code consistency and teaching.",
       id: 1,
       language: nil,
       name: "credo",
       project_id: 12,
       releases: [
        %{"updated_at" => "2015-11-16T20:46:19Z", "version" => "0.1.2"},
        %{"updated_at" => "2015-11-16T19:08:47Z", "version" => "0.1.1"},
        %{"updated_at" => "2015-11-16T19:03:57Z", "version" => "0.1.0"},
        %{"updated_at" => "2015-11-09T12:38:50Z", "version" => "0.0.1-dev"}],
       source: "hex", source_url: "https://github.com/rrrene/credo",}
  end

  test "kind_of_release pure" do
    assert :major == "2.0.0" |> VersionHelper.kind_of_release
    assert :minor == "2.1.0" |> VersionHelper.kind_of_release
    assert :patch == "2.1.1" |> VersionHelper.kind_of_release
    assert :pre == "2.0.0-dev" |> VersionHelper.kind_of_release
  end

  test "kind_of_release with a package" do
    assert :patch == VersionHelper.kind_of_release(test_package)
  end

  test "newest_version with a package" do
    assert "0.1.2" == VersionHelper.newest_version(test_package)
  end

  test "newest_version with a list /1" do
    releases = [
        %{"updated_at" => "2015-12-07T14:50:05Z", "version" => "0.2.1"},
        %{"updated_at" => "2015-12-07T14:25:52Z", "version" => "0.2.0"},
        %{"updated_at" => "2015-11-16T20:46:19Z", "version" => "0.1.2"},
        %{"updated_at" => "2015-11-16T19:08:47Z", "version" => "0.1.1"},
        %{"updated_at" => "2015-11-16T19:03:57Z", "version" => "0.1.0"},
        %{"updated_at" => "2015-11-09T12:38:50Z", "version" => "0.0.1-dev"}
      ]
    assert "0.2.1" == VersionHelper.newest_version(releases)
  end

  test "newest_version with a list /2" do
    releases = [
        %{"updated_at" => "2016-01-16T20:46:19Z", "version" => "0.1.3"},
        %{"updated_at" => "2015-12-07T14:50:05Z", "version" => "0.2.1"},
        %{"updated_at" => "2015-12-07T14:25:52Z", "version" => "0.2.0"},
        %{"updated_at" => "2015-11-16T20:46:19Z", "version" => "0.1.2"},
        %{"updated_at" => "2015-11-16T19:08:47Z", "version" => "0.1.1"},
        %{"updated_at" => "2015-11-16T19:03:57Z", "version" => "0.1.0"},
        %{"updated_at" => "2015-11-09T12:38:50Z", "version" => "0.0.1-dev"}
      ]
    assert "0.1.3" == VersionHelper.newest_version(releases)
  end

end
