defmodule ImsWeb.UnauthorizedController do
  use ImsWeb, :controller
  use Phoenix.Component

  @unauthorized_template """
  <div class="d-flex flex-column align-items-center justify-content-center vh-100 bg-light">
    <div class="card shadow-lg border-0 p-4 text-center" style="max-width: 500px;">
      <div class="card-body">
        <div class="mb-3">
          <i class="bi bi-lock-fill text-danger" style="font-size: 4rem;"></i>
        </div>
        <h2 class="text-danger fw-bold">Access Denied</h2>
        <p class="text-muted">You do not have the required permissions to access this page.</p>
        <a href="/" class="btn btn-primary mt-3">
          <i class="bi bi-house-door-fill"></i> Return to Home
        </a>
      </div>
    </div>
  </div>
  """

  def index(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> html(@unauthorized_template)
  end
end
