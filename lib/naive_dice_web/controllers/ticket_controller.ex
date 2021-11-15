defmodule NaiveDiceWeb.TicketController do
  use NaiveDiceWeb, :controller
  alias NaiveDice.Events
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
      remaining_tickets = event.allocation - NaiveDice.Events.available_tickets(Repo, event)

      render(conn, "new.html", %{
        changeset: Events.new_ticket_changeset(event),
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
    ticket = Events.get_ticket_by_id(ticket_id)

    %{url: url} = NaiveDice.Stripe.retrieve_session(ticket.payment_id)

    render(conn, "edit.html", %{ticket: ticket, checkout_url: url})
  end


  def success(conn, %{"session_id" => session_id}) do
    # My TODO: There can be a vulnerability here ;)

    session = NaiveDice.Stripe.retrieve_session(session_id)

    if session_id == session.id do
      ticket = NaiveDice.Events.get_by_payment_id(session.id)
      |> Repo.preload(:event)

      NaiveDice.Events.confirm_paid_ticket(ticket)
      |> redirect_success(conn)
    else
      render(conn, "problem.html")
    end
  end

  defp redirect_success({:error, :check_available_tickets, _, _}, conn) do
    render(conn, "sold_out_after_checkout.html")
  end

  defp redirect_success({:ok, _}, conn) do
    render(conn, "success.html")
  end

  # defp maybe_redirect_to(conn, nil = _ticket), do: redirect(conn, "/")

  @doc """
  STEP 3: Renders the confirmation / receipt / thank you screen
  """
  def show(conn, %{"id" => ticket_id}) do
    # TODO: don't render a pending ticket as a successfully purchased one
    ticket = Events.get_ticket_by_id(ticket_id)
    render(conn, "show.html", %{ticket: ticket})
  end

  # TRANSITIONS BETWEEN WIZARD STEPS

  @doc """
  Reserves a ticket for 5 minutes
  """
  def create(conn, %{"event_id" => event_id, "ticket" => %{"user_name" => user_name}}) do
    with {:ok, event} <- Events.get_event_by_id(event_id) do
      # TODO: implement reservation "the right way" - handle all edge cases!!!

      session = NaiveDice.Stripe.create_session(event)


      Events.reserve_ticket(event, user_name, session.id)
      |> redirect_create(conn, event)

      # TODO: I think a Ticket can represent both a pending reservation and a purchased ticket
      # but you may have a different opinion :-)
    end
  end

# #Ecto.Changeset<
#    action: :insert,
#    changes: %{
#      event: #Ecto.Changeset<action: :update, changes: %{}, errors: [],
#       data: #NaiveDice.Events.Event<>, valid?: true>,
#      payment_id: "cs_test_a1El4KowFucYaKm1R98eOlmeLVGA5FvmXN1fFINuBGQXWbBhbzonJlDeJk",
#      user_name: "back"
#    },
#    errors: [
#      user_name: {"has already been taken",
#       [constraint: :unique, constraint_name: "tickets_user_name_index"]}
#    ],
#    data: #NaiveDice.Events.Ticket<>,
#    valid?: false
#  >

  defp redirect_create({:error, :create_ticket, %{errors: errors}, _}, conn, event) do
    IO.inspect "what"
    message = errors
      |> Enum.map(fn {k, v} ->
        {message, _} = v
        "#{k}: #{message}."
      end)
      |> Enum.join("/n")

    IO.inspect message

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

  @doc """
  Updates a ticket with the charge details and redirects to the confirmation / receipt / thank you
  """
  def update(conn, %{"id" => ticket_id}) do
    # TODO: implement this
    conn |> redirect(to: Routes.ticket_path(conn, :show, ticket_id))
  end

  # ADMIN ACTIONS

  @doc """
  Helper method which returns the system into the original state (useful for testing)
  """
  def reset_guests(conn, _params) do
    NaiveDice.Events.remove_all_tickets()

    conn
    |> put_flash(:info, "All tickets deleted. Starting from scratch.")
    |> redirect(to: "/")
  end
end
