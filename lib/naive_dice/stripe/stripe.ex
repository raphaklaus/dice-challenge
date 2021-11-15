defmodule NaiveDice.Stripe do
  require Logger
  def create_session(ticket) do
    case Stripe.Session.create(%{
      cancel_url: "http://localhost:4000/cancel",
      payment_method_types: ["card"],
      success_url: "http://localhost:4000/tickets/#{ticket.id}/success",
      line_items: [%{
        amount: trunc(ticket.event.price * 100),
        currency: "EUR",
        name: ticket.event.title,
        quantity: 1
      }]
    }) do
      {:ok, session} -> session
      {:error, error} ->
        Logger.critical("Stripe integration error: #{inspect(error)}")
        %{url: nil}
    end
  end

  ## Refactor both function as they use the same pattern
  def retrieve_session(id) do
    case Stripe.Session.retrieve(id) do
      {:ok, session} -> session
      {:error, error} ->
        Logger.critical("Stripe integration error: #{inspect(error)}")
        %{url: nil}
    end
  end
end
