defmodule HexFaktor.Repo.Migrations.AddUseLockFileToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :use_lock_file, :boolean, default: false
    end
  end
end
