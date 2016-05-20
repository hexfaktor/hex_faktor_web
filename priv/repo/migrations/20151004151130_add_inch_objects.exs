defmodule HexFaktor.Repo.Migrations.AddInchObjects do
  use Ecto.Migration

  def change do
    create table(:inch_object_references) do
      add :job_id, :integer
      add :inch_object_id, :integer
    end
    create index(:inch_object_references, ["job_id"])
    create unique_index(:inch_object_references,
                        ["job_id", "inch_object_id"],
                        name: :inch_object_references_unique_index)

    create table(:inch_objects) do
      add :repo_id, :integer
      add :type, :string
      add :fullname, :text
      add :score, :integer
      add :grade, :string, size: 1
      add :priority, :integer
      add :location, :string
      add :digest, :string, size: 44

      timestamps
    end
    create index(:inch_objects, ["digest"])

    create table(:inch_object_roles) do
      add :inch_object_id, :integer
      add :inch_object_role_name_id, :integer
      add :ref_name, :string
      add :priority, :integer
      add :score, :integer

      timestamps
    end
    create index(:inch_object_roles, ["inch_object_id"])

    create table(:inch_object_role_names) do
      add :name, :string
    end
    create unique_index(:inch_object_role_names, [:name])
  end
end
