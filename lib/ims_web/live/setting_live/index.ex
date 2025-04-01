defmodule ImsWeb.SettingLive.Index do
  use ImsWeb, :live_view

  alias Ims.Settings
  alias Ims.Settings.Setting

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :settings, Settings.list_settings())}
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
  def handle_info({ImsWeb.SettingLive.FormComponent, {:saved, setting}}, socket) do
    {:noreply, stream_insert(socket, :settings, setting)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    setting = Settings.get_setting!(id)
    {:ok, _} = Settings.delete_setting(setting)

    {:noreply, stream_delete(socket, :settings, setting)}
  end
end
