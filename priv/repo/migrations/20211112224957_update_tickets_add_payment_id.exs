defmodule NaiveDice.Repo.Migrations.UpdateTicketsAddPaymentId do
  use Ecto.Migration

  def change do
    alter table(:tickets) do
      add :payment_id, :string
    end
  end
end
