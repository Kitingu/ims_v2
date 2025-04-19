defmodule ImsWeb.PaymentGatewayLive.Index do
  use ImsWeb, :live_view

  alias Ims.Payments
  alias Ims.Payments.PaymentGateway
  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Listing Payment gateways")
      |> assign(:filters, %{})
      |> assign(:page, 1)
      |> assign(:payment_gateways, fetch_records(%{}, @paginator_opts))
      |> assign(:current_user, socket.assigns.current_user)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Payment gateway")
    |> assign(:payment_gateway, Payments.get_payment_gateway!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Payment gateway")
    |> assign(:payment_gateway, %PaymentGateway{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Payment gateways")
    |> assign(:payment_gateway, nil)
  end

  @impl true
  def handle_info({ImsWeb.PaymentGatewayLive.FormComponent, {:saved, payment_gateway}}, socket) do
    payment_gateways =
      fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Payment gateway saved successfully")
     |> assign(:payment_gateways, payment_gateways)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    payment_gateway = Payments.get_payment_gateway!(id)
    {:ok, _} = Payments.delete_payment_gateway(payment_gateway)

    {:noreply, stream_delete(socket, :payment_gateways, payment_gateway)}
  end

  @impl true
  def handle_event("edit" <> id, _params, socket) do
    payment_gateway = Payments.get_payment_gateway!(id)

    {:noreply,
     assign(socket,
       page_title: "Edit Gateway",
       payment_gateway: payment_gateway,
       live_action: :edit
     )}
  end

  @impl true
  def handle_event("view" <> id, _params, socket) do

    {:noreply, push_navigate(socket, to: ~p"/payment_gateways/#{id}")}
  end

  defp fetch_records(filters, opts) do
    IO.inspect(opts, label: "opts")
    query = PaymentGateway.search(filters)
    opts = Keyword.merge(@paginator_opts, opts)

    query
    |> Ims.Repo.paginate(opts)
  end
end
