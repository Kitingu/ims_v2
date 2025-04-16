defmodule ImsWeb.AwayRequestLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.HR

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage away_request records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="away_request-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:reason]} type="text" label="Reason" />
        <.input field={@form[:location]} type="text" label="Location" />
        <.input field={@form[:memo]} type="text" label="Memo" />
        <.input field={@form[:memo_upload]} type="text" label="Memo upload" />
        <.input field={@form[:days]} type="number" label="Days" />
        <.input field={@form[:return_date]} type="date" label="Return date" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Away request</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{away_request: away_request} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(HR.change_away_request(away_request))
     end)}
  end

  @impl true
  def handle_event("validate", %{"away_request" => away_request_params}, socket) do
    changeset = HR.change_away_request(socket.assigns.away_request, away_request_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"away_request" => away_request_params}, socket) do
    save_away_request(socket, socket.assigns.action, away_request_params)
  end

  defp save_away_request(socket, :edit, away_request_params) do
    case HR.update_away_request(socket.assigns.away_request, away_request_params) do
      {:ok, away_request} ->
        notify_parent({:saved, away_request})

        {:noreply,
         socket
         |> put_flash(:info, "Away request updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_away_request(socket, :new, away_request_params) do
    case HR.create_away_request(away_request_params) do
      {:ok, away_request} ->
        notify_parent({:saved, away_request})

        {:noreply,
         socket
         |> put_flash(:info, "Away request created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
