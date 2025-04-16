defmodule ImsWeb.RequestLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Inventory

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage request records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="request-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:status]} type="text" label="Status" />
        <.input field={@form[:request_type]} type="text" label="Request type" />
        <.input field={@form[:assigned_at]} type="datetime-local" label="Assigned at" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Request</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{request: request} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Inventory.change_request(request))
     end)}
  end

  @impl true
  def handle_event("validate", %{"request" => request_params}, socket) do
    changeset = Inventory.change_request(socket.assigns.request, request_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"request" => request_params}, socket) do
    save_request(socket, socket.assigns.action, request_params)
  end

  defp save_request(socket, :edit, request_params) do
    case Inventory.update_request(socket.assigns.request, request_params) do
      {:ok, request} ->
        notify_parent({:saved, request})

        {:noreply,
         socket
         |> put_flash(:info, "Request updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_request(socket, :new, request_params) do
    case Inventory.create_request(request_params) do
      {:ok, request} ->
        notify_parent({:saved, request})

        {:noreply,
         socket
         |> put_flash(:info, "Request created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
