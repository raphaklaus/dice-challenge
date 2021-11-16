defmodule NaiveDiceWeb.TicketController do
  use NaiveDiceWeb, :controller
  alias NaiveDice.{Events, Tickets}
  alias NaiveDice.Repo

  action_fallback(NaiveDiceWeb.FallbackController)

  # STEPS OF THE WIZARD

  @doc """
  STEP 1: Renders an empty form with user name input
  That's an entry point for the booking flow.
  """
  def new(conn, %{"event_id" => event_id}) do
    with {:ok, event} <- Events.get_event_by_id(event_id) do
      # TODO: implement this
      remaining_tickets = event.allocation - Tickets.available_tickets(Repo, event)

      render(conn, "new.html", %{
        changeset: Tickets.new_ticket_changeset(event),
        event: event,
        remaining_tickets: remaining_tickets,
        message: get_flash(conn, :message)
      })
    end
  end

  @doc """
  STEP 2: Renders the Stripe payment form
  """
  def edit(conn, %{"id" => ticket_id}) do
    # TODO: implement this
    ticket = Tickets.get_ticket_by_id(ticket_id)

    %{url: url, id: payment_id} = NaiveDice.Stripe.create_session(ticket)

    {:ok, ticket} = Tickets.update_payment_id(ticket, payment_id)
    schedule_ticket_cleanup(ticket)

    render(conn, "edit.html", %{ticket: ticket, checkout_url: url})
  end

  @doc """
  STEP 3: Renders the confirmation / receipt / thank you screen
  """
  def show(conn, %{"id" => ticket_id}) do
    # TODO: don't render a pending ticket as a successfully purchased one
    ticket = Tickets.get_ticket_by_id(ticket_id)

    case ticket.confirmed do
      true -> render(conn, "show.html", %{ticket: ticket})
      _ -> render(conn, "pending.html", %{ticket: ticket})
    end
  end

  # TRANSITIONS BETWEEN WIZARD STEPS

  @doc """
  Reserves a ticket for 5 minutes
  """
  def create(conn, %{"event_id" => event_id, "ticket" => %{"user_name" => user_name}}) do
    with {:ok, event} <- Events.get_event_by_id(event_id) do
      Tickets.reserve_ticket(event, user_name)
      |> redirect_create(conn, event)
    end
  end

  defp redirect_create({:error, :create_ticket, %{errors: errors}, _}, conn, event) do
    message =
      errors
      |> Enum.map(fn {k, v} ->
        {message, _} = v
        "#{k}: #{message}."
      end)
      |> Enum.join("/n")

    conn
    |> put_flash(:message, message)
    |> redirect(to: "/events/#{event.id}/tickets/new")
  end

  defp redirect_create({:error, :check_available_tickets, _, _}, conn, _) do
    render(conn, "sold_out.html")
  end

  defp redirect_create({:ok, %{create_ticket: ticket}}, conn, _) do
    redirect(conn, to: Routes.ticket_path(conn, :edit, ticket.id))
  end

  defp schedule_ticket_cleanup(ticket) do
    expires_in = :timer.minutes(5)
    NaiveDice.TicketScheduler.Supervisor.start_child(%{ticket: ticket, expires_in: expires_in})
  end

  @doc """
  Updates a ticket with the charge details and redirects to the confirmation / receipt / thank you
  """
  def update(conn, %{"session_id" => session_id}) do
    ticket =
      Tickets.get_by_payment_id(session_id)
      |> Repo.preload(:event)

    Tickets.confirm_paid_ticket(ticket)
    |> redirect_show(conn)
  end

  defp redirect_show({:error, :check_available_tickets, _, _}, conn) do
    render(conn, "sold_out_after_checkout.html")
  end

  defp redirect_show({:ok, %{ticket: ticket}}, conn) do
    redirect(conn, to: Routes.ticket_path(conn, :show, ticket.id))
  end

  def cancel(conn, %{"ticket_id" => _ticket_id}) do
    render(conn, "cancel.html")
  end

  # ADMIN ACTIONS

  @doc """
  Helper method which returns the system into the original state (useful for testing)
  """
  def reset_guests(conn, _params) do
    Tickets.remove_all_tickets()

    conn
    |> put_flash(:info, "All tickets deleted. Starting from scratch.")
    |> redirect(to: "/")
  end
end
