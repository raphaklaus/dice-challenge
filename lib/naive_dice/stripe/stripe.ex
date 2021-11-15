defmodule NaiveDice.Stripe do
  require Logger
  def create_session(event) do
    case Stripe.Session.create(%{
      cancel_url: "http://localhost:4000/ticket/cancel",
      payment_method_types: ["card"],
      success_url: "http://localhost:4000/ticket/success?session_id={CHECKOUT_SESSION_ID}",
      line_items: [%{
        amount: trunc(event.price * 100),
        currency: "EUR",
        name: event.title,
        quantity: 1
      }]
    }) do
      {:ok, session} -> session
      {:error, error} ->
        Logger.critical("Stripe integration error: #{inspect(error)}")
        %{url: nil, id: nil}
    end
  end

  ## Refactor both function as they use the same pattern
  def retrieve_session(id) do
    case Stripe.Session.retrieve(id) do
      {:ok, session} -> session
      {:error, error} ->
        Logger.critical("Stripe integration error: #{inspect(error)}")
        %{url: nil, id: nil}
    end
  end
end
