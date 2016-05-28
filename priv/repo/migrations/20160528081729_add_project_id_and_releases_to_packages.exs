defmodule Elixir.HexFaktor.Repo.Migrations.AddProjectIdAndReleasesToPackages do
  use Ecto.Migration

  def change do
    alter table(:packages) do
      add :project_id, :integer
      add :releases, {:array, :map}

      modify :description, :text
    end
  end
end
