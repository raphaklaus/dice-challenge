defmodule NaiveDice.Repo.Migrations.UpdateEventsAddPrice do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :price, :float
    end
  end
end
