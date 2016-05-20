defmodule HexFaktorCLI.MixExsLoaderTest do
  use ExUnit.Case

  alias HexFaktor.MixExsLoader

  @no_deps """
defmodule Sample.Mixfile do
  use Mix.Project

  @version File.read!("VERSION") |> String.strip

  def project do
    [app: :sample,
     version: @version,
     elixir: "~> 1.0",
     description: "Just a sample.",
     package: package]
  end
end
  """

  @empty_deps """
defmodule Sample.Mixfile do
  use Mix.Project

  @version File.read!("VERSION") |> String.strip

  def project do
    [app: :sample,
     version: @version,
     elixir: "~> 1.0",
     description: "Just a sample.",
     deps: deps,
     package: package]
  end

  def application do
    [applications: []]
  end

  defp deps do
    []
  end

  defp package do
    [files: ~w(lib mix.exs README.md LICENSE),
     maintainers: ["Someone"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/rrrene/credo"}]
  end
end
  """

  @some_deps """
defmodule Simplex.Mixfile do
  use Mix.Project

  def project do
    [app: :simplex,
     version: version,
     test_coverage: [tool: ExCoveralls],
     elixir: "~> 1.1",
     deps: deps,
     package: [
       maintainers: ["Adam Kittelson"],
       licenses: ["MIT"],
       links: %{ github: "https://github.com/adamkittelson/simplex" },
       files: ["lib/*", "mix.exs", "README.md", "LICENSE.md", "CHANGELOG.md", "VERSION.yml"]
     ],
     description: "An Elixir library for interacting with the Amazon SimpleDB API."]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :httpotion, :tzdata]]
  end

  # Dependencies can be hex.pm packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1"}
  #
  # Type `mix help deps` for more examples and options
  def deps do
    [
      {:timex, "~> 1.0.0-rc4"},
      {:httpotion, "~> 2.1"},
      {:ibrowse,   "~> 4.2"},
      {:sweet_xml, "~> 0.5"},
      {:poison, "~> 1.5"},
      {:excoveralls, "~> 0.4", only: [:dev, :test]},
      {:meck, "~> 0.8.2", only: [:dev, :test]}
    ]
  end

  defp version do
     ~r/[0-9]+/
     |> Regex.scan(File.read!("VERSION.yml"))
     |> List.flatten
     |> Enum.join(".")
  end
end
  """

  @deps_with_sigil """
defmodule Sample.Mixfile do
  use Mix.Project

  @version File.read!("VERSION") |> String.strip

  def project do
    [app: :sample,
     version: @version,
     elixir: "~> 1.0",
     description: "Just a sample.",
     deps: deps,
     package: package]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [
      # Test framework
      {:shouldi, github: "batate/shouldi", only: :test},
      # App config test helper
      {:temporary_env, only: :test},
      # Test coverage checker
      {:excoveralls, only: :test},
      # Automatic test runner
      {:mix_test_watch, only: :dev},

      # Benchmark framework
      {:benchfella, only: :dev},

      # Documentation checker
      {:inch_ex, only: ~w(dev test docs)a},
      # Markdown processor
      {:earmark, only: :dev},
      # Documentation generator
      {:ex_doc, only: :dev},

      # JSON encoder
      {:poison, "~> 1.0"},
    ]
  end

  defp package do
    [files: ~w(lib mix.exs README.md LICENSE),
     maintainers: ["Someone"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/rrrene/credo"}]
  end
end
  """

  @deps_with_x """
defmodule Rollbax.Mixfile do
  use Mix.Project

  def project() do
    [app: :rollbax,
     version: "0.5.2",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application() do
    [applications: [:logger, :hackney, :poison],
     mod: {Rollbax, []}]
  end

  defp deps() do
    [{:hackney, "~> 1.1"},
     {:poison,  "~> 1.4"},

     {:plug,   "~> 0.13.0", only: :test},
     {:cowboy, "~> 1.0.0", only: :test}]
  end

  defp description() do
    "Exception tracking and logging from Elixir to Rollbar"
  end

  defp package() do
    [maintainers: ["Aleksei Magusev"],
     licenses: ["ISC"],
     links: %{"GitHub" => "https://github.com/elixir-addicts/rollbax"}]
  end
end
  """


  test "get deps (none)" do
    assert nil == MixExsLoader.parse(@no_deps)
  end

  test "get deps (empty)" do
    assert [] == MixExsLoader.parse(@empty_deps)
  end

  test "get deps" do
    expected =
      [
        {:timex, "~> 1.0.0-rc4"},
        {:httpotion, "~> 2.1"},
        {:ibrowse,   "~> 4.2"},
        {:sweet_xml, "~> 0.5"},
        {:poison, "~> 1.5"},
        {:excoveralls, "~> 0.4", only: [:dev, :test]},
        {:meck, "~> 0.8.2", only: [:dev, :test]}
      ]
    assert expected == MixExsLoader.parse(@some_deps)
  end

  test "get deps with sigil_w" do
    expected =
      [
        {:shouldi, github: "batate/shouldi", only: :test},
        {:temporary_env, only: :test},
        {:excoveralls, only: :test},
        {:mix_test_watch, only: :dev},
        {:benchfella, only: :dev},
        {:inch_ex, only: ~w(dev test docs)a},
        {:earmark, only: :dev},
        {:ex_doc, only: :dev},
        {:poison, "~> 1.0"},
      ]
    assert expected == MixExsLoader.parse(@deps_with_sigil)
  end

  test "get deps with ????" do
    expected =
      [
        {:hackney, "~> 1.1"},
        {:poison,  "~> 1.4"},
        {:plug,   "~> 0.13.0", only: :test},
        {:cowboy, "~> 1.0.0", only: :test}
      ]
    assert expected == MixExsLoader.parse(@deps_with_x)
  end
end
