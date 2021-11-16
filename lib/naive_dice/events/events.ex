defmodule NaiveDice.Events do
  alias NaiveDice.Events.Event
  alias NaiveDice.Repo

  def list_all do
    Repo.all(Event)
  end

  def get_event_by_id(id) do
    case Repo.get(Event, id) do
      nil ->
        {:error, :not_found}

      event ->
        {:ok, event}
    end
  end
end
