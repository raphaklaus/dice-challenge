defmodule NaiveDice.Tickets do
  import Ecto.Query
  alias NaiveDice.Events.Ticket
  alias NaiveDice.Repo
  alias Ecto.Multi

  # My TODO: Separate functions of ticket and event into different modules

  def get_by_payment_id(id) do
    Repo.get_by(Ticket, payment_id: id)
  end

  def confirm_paid_ticket(ticket) do
    Multi.new()
    |> Multi.run(:check_available_tickets, fn repo, _ -> has_available_tickets?(repo, ticket.event) end)
    |> Multi.update(:ticket, Ticket.changeset(ticket, %{confirmed: true}))
    |> Repo.transaction()
    |> cancel_stale_ticket_removal()
  end

  defp cancel_stale_ticket_removal({:ok, %{ticket: ticket}} = params) do
    NaiveDice.TicketScheduler.Supervisor.terminate_child_by_id(ticket.id)
    params
  end

  defp cancel_stale_ticket_removal(params), do: params

  def update_payment_id(ticket, payment_id) do
    ticket
      |> Ticket.changeset(%{payment_id: payment_id})
      |> Repo.update()
  end

  def get_guests() do
    from(
      t in Ticket,
      where: t.confirmed == true,
      select: t.user_name
    ) |> Repo.all()
  end

  def new_ticket_changeset(event) do
    Ticket.changeset(%Ticket{}, %{event: event})
  end


  def available_tickets(repo, event) do
    from(
      t in Ticket,
      where: t.event_id == ^event.id and t.confirmed == true,
      select: count(t.id)
    ) |> repo.one()
  end

  def is_pending_ticket?(repo, ticket) do
    result = from(
      t in Ticket,
      where: t.id == ^ticket.id and t.confirmed == false,
      select: count(t.id)
    ) |> repo.one()

    if result == 1, do: {:ok, result}, else: {:error, result}
  end

  def has_available_tickets?(repo, event) do
    allocation = available_tickets(repo, event)

    if allocation >= 5, do: {:error, allocation}, else: {:ok, allocation}
  end

  def reserve_ticket(event, user_name) do
    Multi.new()
    |> Multi.run(:check_available_tickets, fn repo, _ -> has_available_tickets?(repo, event) end)
    |> Multi.insert(:create_ticket, Ticket.changeset(%Ticket{}, %{user_name: user_name, event: event}))
    |> Repo.transaction()
  end

  def delete_pending_ticket(ticket) do
    Multi.new()
    |> Multi.run(:check_pending, fn repo, _ -> is_pending_ticket?(repo, ticket) end)
    |> Multi.delete(:delete_ticket, ticket)
    |> Repo.transaction()
  end

  def get_ticket_by_id(ticket_id) do
    NaiveDice.Events.Ticket
      |> NaiveDice.Repo.get(ticket_id)
      |> NaiveDice.Repo.preload([:event])
  end

  def remove_all_tickets() do
    from(t in Ticket, where: t.confirmed == true)
      |> Repo.delete_all
  end
end
