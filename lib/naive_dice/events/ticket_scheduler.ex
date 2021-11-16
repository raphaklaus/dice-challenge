defmodule NaiveDice.TicketScheduler do
  alias NaiveDice.Tickets
  use GenServer

  def start_link(%{ticket: ticket} = opts) do
    name = {:via, Registry, {NaiveDice.TicketScheduler, ticket.id}}
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    %{ticket: ticket, expires_in: expires_in} = opts
    schedule(expires_in)
    {:ok, ticket}
  end

  def handle_info(:work, ticket) do
    NaiveDice.Stripe.expire_session(ticket.payment_id)
    Tickets.delete_pending_ticket(ticket)
    {:noreply, ticket}
  end

  defp schedule(expires_in) do
    Process.send_after(self(), :work, expires_in)
  end
end
