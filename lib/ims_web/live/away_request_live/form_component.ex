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
      <div class="relative" phx-update="ignore" id="select_user_container">
          <.input
            field={@form[:user_id]}
            type="select"
            id="select_user_id"
            phx-hook="select2JS"
            options={@user_options}
            data-phx-event="select_changed"
            data-placeholder="Select User"
            class="w-full hidden"
          />
        </div>

        <.input field={@form[:reason]} type="text" label="Reason" />
        <.input field={@form[:location]} type="text" label="Location" />
        <.input field={@form[:memo]} type="text" label="Memo" />
        <.input field={@form[:memo_upload]} type="text" label="Memo upload" />
        <.input field={@form[:days]} type="number" label="Days" />
        <.input field={@form[:start_date]} type="date" label="Start date" />
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
    users =
    Ims.Accounts.list_users()
    |> Enum.map(fn user ->
      {"#{user.first_name} #{user.last_name}", user.id}
    end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:user_options, users)
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

  @impl true
  def handle_event(
        "select_changed",
        %{
          "select_id" => "select_user_id",
          "away_request[user_id]" => user_id
        },
        socket
      ) do

    # Merge into form params
    updated_params =
      socket.assigns.form.params
      |> Map.put("user_id", user_id)

    # Re-validate the changeset using updated params
    changeset =
      socket.assigns.away_request
      |> HR.change_away_request(updated_params)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:selected_user, user_id)}
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
