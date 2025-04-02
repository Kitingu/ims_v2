defmodule ImsWeb.Plugs.CurrentUserPlug do
  import Plug.Conn
  import Phoenix.Controller

  alias Ims.Accounts

  def init(default), do: default

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in to access this page")
        |> redirect(to: "/users/log_in")
        |> halt()

      user_id ->
        user = Accounts.get_user!(user_id)
        assign(conn, :current_user, user)
    end
  end
end
