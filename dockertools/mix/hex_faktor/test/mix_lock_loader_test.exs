defmodule HexFaktorCLI.MixLockLoaderTest do
  use ExUnit.Case

  alias HexFaktor.MixLockLoader

  @locked_deps """
%{"benchfella": {:hex, :benchfella, "0.3.1"},
  "earmark": {:hex, :earmark, "0.2.0"},
  "ex_doc": {:hex, :ex_doc, "0.11.3"},
  "exjsx": {:git, "https://github.com/talentdeficit/exjsx.git", "53db5d995b1b070e3883381e9acb195969137f67", []},
  "jazz": {:git, "https://github.com/meh/jazz.git", "49f335492aca5516495199dd81dd18b845ebaa69", []},
  "jiffy": {:git, "https://github.com/davisp/jiffy.git", "6303ff98aaa3fce625038c8b7af2aa8b802f4742", []},
  "jsx": {:hex, :jsx, "2.6.2"}}
  """

  @locked_deps2 """
%{"exactor": {:git, "git://github.com/sasa1977/exactor.git", "f7f6bae7fead5e0e5525581d44311f803169fa4e", []},
  "excoveralls": {:hex, :excoveralls, "0.4.0"},
  "exjsx": {:hex, :exjsx, "3.2.0"},
  "exprintf": {:hex, :exprintf, "0.1.3"},
  "hackney": {:hex, :hackney, "1.3.2"},
  "idna": {:hex, :idna, "1.0.2"},
  "jsex": {:package, "2.0.0"},
  "jsx": {:hex, :jsx, "2.6.2"},
  "ssl_verify_hostname": {:hex, :ssl_verify_hostname, "1.0.5"},
  "triq": {:git, "https://github.com/krestenkrab/triq.git", "c7306b8eaea133d52140cb828817efb5e50a3d52", []}}
  """

  test "get deps" do
    expected =
      %{
        "benchfella": {:hex, :benchfella, "0.3.1"},
        "earmark": {:hex, :earmark, "0.2.0"},
        "ex_doc": {:hex, :ex_doc, "0.11.3"},
        "exjsx": {:git, "https://github.com/talentdeficit/exjsx.git", "53db5d995b1b070e3883381e9acb195969137f67", []},
        "jazz": {:git, "https://github.com/meh/jazz.git", "49f335492aca5516495199dd81dd18b845ebaa69", []},
        "jiffy": {:git, "https://github.com/davisp/jiffy.git", "6303ff98aaa3fce625038c8b7af2aa8b802f4742", []},
        "jsx": {:hex, :jsx, "2.6.2"}
      }
    assert expected == MixLockLoader.parse(@locked_deps)
  end

  test "get deps /2" do
    expected =
      %{"exactor": {:git, "git://github.com/sasa1977/exactor.git", "f7f6bae7fead5e0e5525581d44311f803169fa4e", []},
        "excoveralls": {:hex, :excoveralls, "0.4.0"},
        "exjsx": {:hex, :exjsx, "3.2.0"},
        "exprintf": {:hex, :exprintf, "0.1.3"},
        "hackney": {:hex, :hackney, "1.3.2"},
        "idna": {:hex, :idna, "1.0.2"},
        "jsex": {:package, "2.0.0"},
        "jsx": {:hex, :jsx, "2.6.2"},
        "ssl_verify_hostname": {:hex, :ssl_verify_hostname, "1.0.5"},
        "triq": {:git, "https://github.com/krestenkrab/triq.git", "c7306b8eaea133d52140cb828817efb5e50a3d52", []}}
    assert expected == MixLockLoader.parse(@locked_deps2)
  end
end
