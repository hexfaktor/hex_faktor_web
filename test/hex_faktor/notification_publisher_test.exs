defmodule HexFaktor.NotificationPublisherTest do
  use HexFaktor.ConnCase

  alias HexFaktor.Persistence.Package
  alias HexFaktor.Persistence.Notification

  alias HexFaktor.NotificationPublisher
  alias HexFaktor.Persistence.PackageUserSettings

  @test_package_id 1
  @test_user_id 1

  setup do
    package_user_settings =
      PackageUserSettings.ensure(@test_package_id, @test_user_id)
    {:ok, %{"package_user_settings" => package_user_settings}}
  end

  def notification_count do
    Notification.latest_for(@test_user_id, 1000)
    |> Enum.count
  end

  test "the truth" do
    assert PackageUserSettings.find(@test_package_id, @test_user_id)
    assert 0 == notification_count()

    test_package = Package.find_by_id(@test_package_id)
    NotificationPublisher.handle_new_package_update(test_package)
    assert 1 == notification_count()

    NotificationPublisher.handle_new_package_update(test_package)
    assert 1 == notification_count()

    new_release =
      %{"updated_at" => "2020-01-01T00:00:00Z", "version" => "42.0.0"}
    releases = [new_release] ++ test_package.releases
    test_package2 =
      %HexFaktor.Package{test_package | releases: releases}

    NotificationPublisher.handle_new_package_update(test_package2)
    assert 2 == notification_count()
  end

end
