defmodule ImsWeb.SettingLive.Index do
  use ImsWeb, :live_view

  alias Ims.Settings
  alias Ims.Settings.Setting

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:settings, Settings.list_settings() |> Ims.Repo.paginate(page: 1))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Setting")
    |> assign(:setting, Settings.get_setting!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Setting")
    |> assign(:setting, %Setting{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Settings")
    |> assign(:setting, nil)
  end

  @impl true
  def handle_info({ImsWeb.SettingLive.FormComponent, {:saved, _setting}}, socket) do
   {:noreply, socket |>
    assign(:settings, Settings.list_settings() |> Ims.Repo.paginate(page: 1)) |>
    put_flash(:info, "Setting saved successfully")}

  end

  @impl true
  def handle_event("edit" <> id, _params, socket) do
    setting = Settings.get_setting!(id)

    {:noreply,
     assign(socket,
       page_title: "Edit Asset type",
       setting: setting,
       live_action: :edit
     )}
  end

  @impl true
  def handle_event("view" <> id, _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/admin/settings/#{id}")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    setting = Settings.get_setting!(id)
    {:ok, _} = Settings.delete_setting(setting)

    {:noreply, stream_delete(socket, :settings, setting)}
  end
end
