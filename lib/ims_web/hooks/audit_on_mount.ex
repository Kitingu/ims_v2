defmodule ImsWeb.Hooks.AuditOnMount do
  @moduledoc """
  Ensures the LiveView process sets the audit actor & basic metadata.
  """
  import Phoenix.LiveView
  alias Ims.Audit

  def on_mount(:set_actor, _params, _session, socket) do
    actor =
      case socket.assigns[:current_user] do
        %{id: _} = user -> user
        _ -> :system
      end

    Audit.set_actor(actor)

    # optional: lightweight LV metadata
    Audit.put_metadata(%{
      live_view: socket.view |> to_string(),
      lv_connected?: connected?(socket)
    })

    {:cont, socket}
  end
end
