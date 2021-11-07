defmodule NaiveDice.Repo.Migrations.UpdateTicketsAddConfirmedEvent do
  use Ecto.Migration

  def change do
    alter table(:tickets) do
      add :confirmed, :boolean, default: false
      add :event_id, references(:events)
    end
  end
end
