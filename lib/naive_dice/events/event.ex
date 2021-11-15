defmodule NaiveDice.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [:allocation, :title]

  schema "events" do
    field :allocation, :integer
    field :title
    field :price, :float
    has_many :tickets, NaiveDice.Events.Ticket

    timestamps()
  end

  @doc false
  def changeset(event, attrs \\ %{}) do
    event
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
