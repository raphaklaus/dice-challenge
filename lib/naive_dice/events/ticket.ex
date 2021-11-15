defmodule NaiveDice.Events.Ticket do
  @moduledoc """
  This schema represents a purchased ticket

  TODO: should we use the same schema to represent a pending reservation?
  """

  use Ecto.Schema
  import Ecto.Changeset

  # TODO: the schema is far from beging complete:
  schema "tickets" do
    field :user_name, :string
    field :confirmed, :boolean
    field :payment_id, :string
    belongs_to :event, NaiveDice.Events.Event

    timestamps()
  end

  @spec changeset(
          {map, map}
          | %{
              :__struct__ => atom | %{:__changeset__ => map, optional(any) => any},
              optional(atom) => any
            },
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(ticket, attrs \\ %{}) do\
    ticket
    |> cast(attrs, [:user_name, :confirmed, :payment_id])
    |> maybe_put_assoc(:event, attrs[:event])
    |> validate_required([:user_name, :event, :payment_id])
  end

  defp maybe_put_assoc(ticket, :event, nil), do: ticket
  defp maybe_put_assoc(ticket, :event, event), do: put_assoc(ticket, :event, event)
end
