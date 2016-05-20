defmodule HexFaktor.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :uid, :integer
      add :provider, :string
      add :user_name, :string

      add :full_name, :string
      add :email, :string
      add :email_token, :string
      add :email_verified_at, :datetime

      add :last_github_sync, :datetime

      add :email_notification_frequency, :string
      add :email_newsletter, :boolean

      timestamps
    end
  end
end
