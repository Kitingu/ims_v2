defmodule ImsWeb.TrainingApplicationLive.Show do
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
     |> assign(:training_application, Trainings.get_training_application!(id))}
  end

  defp page_title(:show), do: "Show Training application"
  defp page_title(:edit), do: "Edit Training application"
end
