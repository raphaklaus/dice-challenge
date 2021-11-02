defmodule NaiveDice.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :allocation, :integer
    field :title

    timestamps()
  end
end
