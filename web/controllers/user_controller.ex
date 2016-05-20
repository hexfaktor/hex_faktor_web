defmodule HexFaktor.UserController do
  use HexFaktor.Web, :controller

  alias HexFaktor.Persistence.User
  alias HexFaktor.EmailVerifier

  alias HexFaktor.Auth
  alias HexFaktor.NotificationMailer

  @edit_sections [
    {"email", "Notifications"},
    {"resend_validation", "Resend Email"},
    {"github_sync", "Sync GitHub"}
  ]

  #
  # /edit
  #

  def edit(conn, params) do
    current_user = Auth.current_user(conn)
    if current_user do
      conn |> perform_edit(current_user, params["section"] |> nil_if_empty)
    else
      conn |> access_denied()
    end
  end

  defp perform_edit(conn, current_user, nil) do
    perform_edit(conn, current_user, "email")
  end
  defp perform_edit(conn, current_user, section) do
    changeset = HexFaktor.User.changeset(current_user)
    sections =
      if current_user.email_verified_at do
        @edit_sections |> List.keydelete("resend_validation", 0)
      else
        @edit_sections
      end

    assigns = [
      current_section: section,
      sections: sections,
      user: current_user,
      changeset: changeset
    ]
    render conn, "edit.html", assigns
  end

  #
  # /update
  #

  def update(conn, params) do
    current_user = Auth.current_user(conn)
    if current_user do
      conn |> perform_update(current_user, params)
    else
      conn |> access_denied()
    end
  end

  defp perform_update(conn, current_user, %{"user" => user_params}) do
    email_changed? = user_params["email"] && user_params["email"] != current_user.email
    if email_changed? do
      user_params = EmailVerifier.update_email_params(conn, current_user, user_params)
    end
    changeset = User.update_attributes(current_user, user_params)
    if changeset.valid? do
      current_user = User.find_by_id(current_user.id)
      flash_message =
        if email_changed? do
          NotificationMailer.send_validation(current_user)
          "A confirmation link has been sent to #{current_user.email}."
        else
          "Settings updated successfully."
        end
      conn
      |> put_flash(:info, flash_message)
      |> redirect to: user_path(conn, :edit)
    else
      assigns = [
        current_section: "email",
        sections: @edit_sections,
        user: current_user,
        changeset: changeset
      ]
      render conn, "edit.html", assigns
    end
  end

  #
  # /verify_email
  #

  def verify_email(conn, %{"email" => email, "token" => email_token}) do
    user = User.find_by_email_and_token(email, email_token)
    if user do
      conn |> perform_verify_email(user)
    else
      render conn, "verify_email.html", success: false
    end
  end

  def perform_verify_email(conn, current_user) do
    params = %{
      "email_verified_at" => Ecto.DateTime.utc,
      "email_token" => nil
    }
    User.update_attributes(current_user, params)
    render conn, "verify_email.html", success: true
  end

  #
  # /resend_verify_email
  #

  def resend_verify_email(conn, _params) do
    current_user = Auth.current_user(conn)
    if current_user do
      conn |> perform_resend_verify_email(current_user)
    else
      conn |> access_denied()
    end
  end

  def perform_resend_verify_email(conn, current_user) do
    params = EmailVerifier.update_email_params(conn, current_user, %{})
    User.update_attributes(current_user, params)
    current_user = User.find_by_id(current_user.id)
    NotificationMailer.send_validation(current_user)
    render conn, "resend_verify_email.html", success: true
  end
end
