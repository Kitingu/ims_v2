defmodule ImsWeb.TrainingProjectionsLive.Show do
  use ImsWeb, :live_view

  alias Ims.Trainings

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:training_projections, Trainings.get_training_projections!(id))}
  end

  defp page_title(:show), do: "Show Training projections"
  defp page_title(:edit), do: "Edit Training projections"
end
