defmodule ImsWeb.SettingLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Settings

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage setting records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="setting-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:value]} type="text" label="Value" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Setting</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{setting: setting} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Settings.change_setting(setting))
     end)}
  end

  @impl true
  def handle_event("validate", %{"setting" => setting_params}, socket) do
    changeset = Settings.change_setting(socket.assigns.setting, setting_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"setting" => setting_params}, socket) do
    save_setting(socket, socket.assigns.action, setting_params)
  end

  defp save_setting(socket, :edit, setting_params) do
    case Settings.update_setting(socket.assigns.setting, setting_params) do
      {:ok, setting} ->
        notify_parent({:saved, setting})

        {:noreply,
         socket
         |> put_flash(:info, "Setting updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_setting(socket, :new, setting_params) do
    case Settings.create_setting(setting_params) do
      {:ok, setting} ->
        notify_parent({:saved, setting})

        {:noreply,
         socket
         |> put_flash(:info, "Setting created successfully")
         |> redirect(to: "/admin/settings")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
