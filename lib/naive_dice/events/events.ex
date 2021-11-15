defmodule NaiveDice.Events do
  alias NaiveDice.Events.{Ticket, Event}
  alias NaiveDice.Repo

  @spec list_all :: list(%Event{})
  def list_all do
    Repo.all(Event)
  end

  @spec get_event_by_id(any) :: {:error, :not_found} | {:ok, %Event{}}
  def get_event_by_id(id) do
    case Repo.get(Event, id) do
      nil ->
        {:error, :not_found}

      event ->
        {:ok, event}
    end
  end

  def new_ticket_changeset(event) do
    Ticket.changeset(%Ticket{}, %{event: event})
  end

  def reserve_ticket(event, user_name) do
    %Ticket{}
    |> Ticket.changeset(%{user_name: user_name, event: event})
    |> Repo.insert()
  end

  def get_ticket_by_id(ticket_id) do
    NaiveDice.Events.Ticket
      |> NaiveDice.Repo.get(ticket_id)
      |> NaiveDice.Repo.preload([:event])
  end
end
