defmodule NaiveDice.Repo.Migrations.UpdateTicketsAddNameUniqueIndex do
  use Ecto.Migration

  def change do
    create index(:tickets, :user_name, unique: true)
  end
end
