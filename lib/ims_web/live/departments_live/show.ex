defmodule ImsWeb.DepartmentsLive.Show do
  use ImsWeb, :live_view

  alias Ims.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:departments, Accounts.get_departments!(id))}
  end

  defp page_title(:show), do: "Show Departments"
  defp page_title(:edit), do: "Edit Departments"
end
