defmodule ImsWeb.Plugs.AuditPlug do
  @moduledoc """
  Sets the current actor & request metadata for the audit log on controller requests.
  """
  import Plug.Conn
  alias Ims.Audit

  def init(opts), do: opts

  def call(conn, _opts) do
    actor =
      case conn.assigns[:current_user] do
        %{id: id} = user when not is_nil(id) -> user
        _ -> :system
      end

    Audit.set_actor(actor)

    # optional metadata
    meta = %{
      ip: ip_to_string(conn.remote_ip),
      user_agent: get_req_header(conn, "user-agent") |> List.first(),
      request_path: conn.request_path,
      request_id: get_req_header(conn, "x-request-id") |> List.first()
    }

    Audit.put_metadata(meta)

    conn
  end

  defp ip_to_string(nil), do: nil
  defp ip_to_string({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"
  defp ip_to_string(other), do: to_string(:inet.ntoa(other))
end
