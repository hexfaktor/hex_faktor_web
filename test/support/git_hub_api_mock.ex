defmodule GitHubAPIMock do
  # we are taking a single parameter here, which is the `?code=` query
  # param of the call to `/auth/callback`
  #
  # TODO: use this to test what happens if the API return unexpected results
  def user("1") do
    %{
      "id" => 1,
      "login" => "rrrene",
      "name" => "René Föhring",
      "email" => "rf@bamaru.de",
    }
  end

  def user("2") do
    %{
      "id" => 2,
      "login" => "rrrene2",
      "name" => "René Föhring the Second",
      "email" => "rf-2@bamaru.de",
    }
  end

  def set_hook() do
    %{
      "active" => true,
      "config" => %{
        "content_type" => "json",
        "url" => "http://localhost:4000/rebuild"
      },
      "created_at" => "2016-01-06T19:47:16Z",
      "events" => ["push"],
      "id" => 6860506,
      "fork" => false,
      "last_response" => %{"code" => nil, "message" => nil, "status" => "unused"},
      "name" => "web",
      "ping_url" => "https://api.github.com/repos/inch-ci/Hello-World-Elixir/hooks/6860506/pings",
      "test_url" => "https://api.github.com/repos/inch-ci/Hello-World-Elixir/hooks/6860506/test",
      "updated_at" => "2016-01-06T19:47:16Z",
      "url" => "https://api.github.com/repos/inch-ci/Hello-World-Elixir/hooks/6860506"
    }
  end
end
