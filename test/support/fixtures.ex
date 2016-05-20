defmodule HexFaktor.Fixtures do
  alias HexFaktor.Repo
  alias HexFaktor.User
  alias HexFaktor.Package
  alias HexFaktor.Project
  alias HexFaktor.ProjectUser
  alias HexFaktor.ProjectUserSettings

  def insert_basic() do
    user = user(1) |> Repo.insert!
    project = project(1) |> Repo.insert!
    project_user(project.id, user.id) |> Repo.insert!
    project_user_settings(project.id, user.id) |> Repo.insert!

    project(2) |> Repo.insert!
    package = package(1) |> Repo.insert!
  end

  def user(1) do
    %User{
      uid: 1,
      provider: "github",
      full_name: "René Föhring",
      user_name: "rrrene",
      email: "rf@bamaru.de",
      email_notification_frequency: "weekly",
      email_newsletter: true,
      email_verified_at: Ecto.DateTime.utc
    }
  end

  def project(1) do
    %Project{
      active: true,
      uid: 123,
      provider: "github",
      name: "rrrene/credo",
      html_url: "https://github.com/rrrene/credo",
      clone_url: "https://github.com/rrrene/credo.git",
      default_branch: "master",
      language: "Elixir"
    }
  end

  def project(2) do
    %Project{
      active: true,
      uid: 234,
      provider: "github",
      name: "rrrene/inch_ex",
      html_url: "https://github.com/rrrene/inch_ex",
      clone_url: "https://github.com/rrrene/inch_ex.git",
      default_branch: "master",
      language: "Elixir"
    }
  end

  def project_user(project_id, user_id) do
    %ProjectUser{
      project_id: project_id,
      user_id: user_id,
    }
  end

  def project_user_settings(project_id, user_id) do
    %ProjectUserSettings{
      project_id: project_id,
      user_id: user_id,
      notification_branches: ["master"],
      email_enabled: true
    }
  end

  def package(1) do
    %Package{
      source: "hex",
      name: "credo"
    }
  end
end
