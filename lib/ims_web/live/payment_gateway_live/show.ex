defmodule ImsWeb.PaymentGatewayLive.Show do
  use ImsWeb, :live_view

  alias Ims.Payments

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:payment_gateway, Payments.get_payment_gateway!(id))}
  end

  defp page_title(:show), do: "Show Payment gateway"
  defp page_title(:edit), do: "Edit Payment gateway"
end
