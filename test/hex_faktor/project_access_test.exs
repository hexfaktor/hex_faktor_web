defmodule HexFaktor.ProjectAccessTest do
  use HexFaktor.ModelCase

  alias HexFaktor.Persistence.Project
  alias HexFaktor.Persistence.User
  alias HexFaktor.ProjectAccess
  alias HexFaktor.Fixtures

  test "grant_exclusively" do
    user = User.find_by_id(1)
    project1 = Project.find_by_id(1)
    project2 = Project.find_by_id(2)

    assert ProjectAccess.granted?(project1.id, user)
    refute ProjectAccess.granted?(project2.id, user)

    ProjectAccess.grant_exclusively([project1, project2], user)

    assert ProjectAccess.granted?(project1.id, user)
    assert ProjectAccess.granted?(project2.id, user)

    ProjectAccess.grant_exclusively([project2], user)

    refute ProjectAccess.granted?(project1.id, user)
    assert ProjectAccess.granted?(project2.id, user)
  end

  test "grant & settings" do
    user = User.find_by_id(1)
    project1 = Project.find_by_id(1)
    project2 = Project.find_by_id(2)

    assert ProjectAccess.granted?(project1.id, user)
    refute ProjectAccess.granted?(project2.id, user)

    ProjectAccess.grant(project2, user)

    assert ProjectAccess.granted?(project1.id, user)
    assert ProjectAccess.granted?(project2.id, user)

    settings = ProjectAccess.settings(project2, user)
    assert ["master"] == settings.notification_branches
    assert settings.email_enabled
  end

end
