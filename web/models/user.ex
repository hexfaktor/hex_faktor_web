defmodule HexFaktor.User do
  use HexFaktor.Web, :model

  schema "users" do
    field :uid, :integer #
    field :provider, :string
    field :user_name, :string

    field :full_name, :string
    field :email, :string
    field :email_token, :string
    field :email_verified_at, Ecto.DateTime

    field :last_github_sync, Ecto.DateTime

    field :email_notification_frequency, :string
    field :email_newsletter, :boolean

    timestamps

    has_many :notifications, HexFaktor.Notification, on_delete: :delete_all
    has_many :project_users, HexFaktor.ProjectUser, on_delete: :delete_all
  end

  @required_fields ~w(uid provider user_name email_notification_frequency)
  @optional_fields ~w(full_name last_github_sync email email_verified_at email_newsletter email_token)
  @valid_email_notification_frequency ~w(none daily weekly)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_inclusion(:email_notification_frequency, @valid_email_notification_frequency)
  end
end
