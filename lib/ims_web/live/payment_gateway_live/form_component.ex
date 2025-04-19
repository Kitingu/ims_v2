defmodule ImsWeb.PaymentGatewayLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Payments

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage payment_gateway records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="payment_gateway-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:slug]} type="hidden" />
        <.input field={@form[:label]} type="text" label="Label" />
        <.input field={@form[:type]} type="text" label="Type" />
        <.input field={@form[:status]} type="hidden" />
        <.input field={@form[:identifier]} type="text" label="Identifier" />
        <.input field={@form[:key]} type="hidden"  />
        <.input field={@form[:secret]} type="hidden"  />
        <.input field={@form[:common_name]} type="text" label="Common name" />
        <.input field={@form[:currency]}
          type="select"
          options={
            [
              {"KES", "KES"},
              {"USD", "USD"},
            ]
          }
         label="Currency" />
        <.input field={@form[:payment_instructions]} type="textarea" label="Payment instructions" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Payment gateway</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{payment_gateway: payment_gateway} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Payments.change_payment_gateway(payment_gateway))
     end)}
  end

  @impl true
  def handle_event("validate", %{"payment_gateway" => payment_gateway_params}, socket) do
    changeset = Payments.change_payment_gateway(socket.assigns.payment_gateway, payment_gateway_params)
    |> IO.inspect()
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"payment_gateway" => payment_gateway_params}, socket) do
    save_payment_gateway(socket, socket.assigns.action, payment_gateway_params)
  end

  defp save_payment_gateway(socket, :edit, payment_gateway_params) do
    case Payments.update_payment_gateway(socket.assigns.payment_gateway, payment_gateway_params) do
      {:ok, payment_gateway} ->
        notify_parent({:saved, payment_gateway})

        {:noreply,
         socket
         |> put_flash(:info, "Payment gateway updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_payment_gateway(socket, :new, payment_gateway_params) do
    case Payments.create_payment_gateway(payment_gateway_params) do
      {:ok, payment_gateway} ->
        notify_parent({:saved, payment_gateway})

        {:noreply,
         socket
         |> put_flash(:info, "Payment gateway created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
