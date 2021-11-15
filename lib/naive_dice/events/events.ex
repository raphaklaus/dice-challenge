defmodule NaiveDice.Events do
  import Ecto.Query
  alias NaiveDice.Events.{Ticket, Event}
  alias NaiveDice.Repo
  alias Ecto.Multi

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

  # My TODO: Separate functions of ticket and event into different modules
  def get_by_payment_id(id) do
    Repo.get_by(Ticket, payment_id: id)
  end

  def confirm_paid_ticket(ticket) do
    Multi.new()
    |> Multi.run(:check_available_tickets, fn repo, _ -> has_available_tickets?(repo, ticket.event) end)
    |> Multi.update(:ticket, Ticket.changeset(ticket, %{confirmed: true}))
    |> Repo.transaction()
    |> IO.inspect
  end

  def new_ticket_changeset(event) do
    Ticket.changeset(%Ticket{}, %{event: event})
  end

  def has_available_tickets?(repo, event) do
    allocation = from(
      t in Ticket,
      where: t.event_id == ^event.id and t.confirmed == true,
      select: count(t.id)
    ) |> repo.one()

    IO.inspect allocation

    if allocation >= 5, do: {:error, allocation}, else: {:ok, allocation}
  end

  def reserve_ticket(_event, _user_name, nil) do
    {:error, :no_payment_id}
  end

  def reserve_ticket(event, user_name, payment_id) do
    Multi.new()
    |> Multi.run(:check_available_tickets, fn repo, _ -> has_available_tickets?(repo, event) end)
    |> Multi.insert(:create_ticket, Ticket.changeset(%Ticket{}, %{user_name: user_name, event: event, payment_id: payment_id}))
    |> Repo.transaction()
  end

  def get_ticket_by_id(ticket_id) do
    NaiveDice.Events.Ticket
      |> NaiveDice.Repo.get(ticket_id)
      |> NaiveDice.Repo.preload([:event])
  end
end
