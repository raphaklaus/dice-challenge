defmodule NaiveDice.Stripe do
  require Logger
  def create_session(ticket) do
    case Stripe.Session.create(%{
      cancel_url: "http://localhost:4000/ticket/#{ticket.id}/cancel",
      payment_method_types: ["card"],
      success_url: "http://localhost:4000/ticket/#{ticket.id}/update?session_id={CHECKOUT_SESSION_ID}",
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

  # Stripe Elixir library do not support expire endpoint I had to rely on the API instead :()
  def expire_session(id) do
    secret = Application.get_env(:stripity_stripe, :api_key)

    case HTTPoison.post!("https://api.stripe.com/v1/checkout/sessions/#{id}/expire", "", ["Authorization": "Bearer #{secret}"]) do
      %{status_code: 200, body: body} ->
        {:ok, body}
      error ->
        Logger.critical("Error while expiring a session: #{inspect(error)}")
        {:error, error}
    end

  end
end
