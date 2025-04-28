defmodule ImsWeb.InternAttacheeLive.Show do
  use ImsWeb, :live_view

  alias Ims.Interns

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:intern_attachee, Interns.get_intern_attachee!(id))}
  end

  defp page_title(:show), do: "Show Intern attachee"
  defp page_title(:edit), do: "Edit Intern attachee"
end
