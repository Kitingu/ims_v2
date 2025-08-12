defmodule ImsWeb.Plugs.EnsureAuthorizedPlug do
  import Plug.Conn
  import Phoenix.Controller
  # import Phoenix.VerifiedRoutes

  alias Ims.Repo
  alias Ims.Accounts.User

  @behaviour Plug
  # ✅ Specify the router explicitly

  def init(opts), do: opts

  def call(conn, opts) do
    user =
      conn.assigns[:current_user] || get_current_user(conn)

    case user do
      nil ->
        conn
        # ✅ Explicitly use `@router`
        |> redirect(to: "/unauthorized")
        |> halt()

      %User{} = user ->
        actions = Keyword.get(opts, :actions, [])
        resource = get_resource_from_path(conn.request_path)
        if Canada.Can.can?(user, actions, resource) do
          conn
        else
          conn
          # ✅ Explicitly use `@router`
          |> redirect(to: "/unauthorized")
          |> halt()
        end
    end
  end

  defp get_resource_from_path("/hr" <> _), do: "hr_dashboard"
  defp get_resource_from_path("/welfare" <> _), do: "welfare_dashboard"
  defp get_resource_from_path("/assets" <> _), do: "assets_dashboard"
  # defp get_resource_from_path("/" <> _), do: "all_routes"

  # ✅ Matches `/admin` and all subpaths
  defp get_resource_from_path("/admin" <> _), do: "admin_panel"
  defp get_resource_from_path("/admin"), do: "admin_panel"
  defp get_resource_from_path(_), do: "unknown"

  defp get_current_user(conn) do
    conn.assigns[:current_user] || Repo.get(User, get_session(conn, :user_id))
  end
end
