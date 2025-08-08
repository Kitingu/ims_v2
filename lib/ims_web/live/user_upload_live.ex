defmodule ImsWeb.UserLive.UploadUsersModal do
  use ImsWeb, :live_component
  # alias Ims.Workers.UploadUsersWorker
  alias Ims.Workers.UploadStaffMembersWorker
  # UploadStaffMembersWorker
  import Phoenix.LiveView

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:download_url, ~p"/admin/users/download_template")
     |> allow_upload(:excel, accept: ~w(.xlsx .xls), max_entries: 1)
     |> IO.inspect(label: "Socket after update")}
  end

  def handle_event("validate", _params, socket) do
    IO.inspect(socket.assigns.uploads.excel.entries, label: "Entries during validation")
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    IO.inspect("we are alive")
    IO.inspect(socket.assigns.uploads.excel.entries, label: "Uploaded entries")

    case Phoenix.LiveView.uploaded_entries(socket, :excel) |> IO.inspect() do
      {[_entry], []} ->
        [entry] = socket.assigns.uploads.excel.entries |> IO.inspect()

        path =
          consume_uploaded_entry(socket, entry, fn %{path: path} ->
            dest =
              Path.join(System.tmp_dir(), "user_upload_template#{System.unique_integer()}.xlsx")

            IO.inspect({:source_path, path})
            IO.inspect({:copy_to, dest})
            File.cp!(path, dest)
            {:ok, dest}
          end)
          |> IO.inspect(label: "File path after upload")

        # Start the Oban job
        %{admin_id: socket.assigns.current_user.id, path: path}
        |> UploadStaffMembersWorker.new()
        |> IO.inspect(label: "Oban job")
        |> Oban.insert()

        {:noreply,
         socket
         |> put_flash(:info, "User upload started. You'll be notified once complete.")
         |> push_patch(to: socket.assigns.patch)}

      {[], [_entry]} ->
        {:noreply, put_flash(socket, :error, "File upload failed")}

      _ ->
        {:noreply, put_flash(socket, :error, "Please select a file to upload")}
    end
  end

  def handle_event("close", _params, socket) do
    send(self(), {:close_upload_modal})
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="fixed inset-0 bg-gray-900 bg-opacity-50 flex items-center justify-center z-50">
        <div
          class="bg-white w-full max-w-md p-6 rounded-lg shadow-lg relative"
          phx-click-away="close"
          phx-window-keydown="close"
          phx-key="escape"
          phx-target={@myself}
        >
          <!-- Close Button -->
          <button
            type="button"
            phx-click="close"
            class="absolute top-2 right-2 text-gray-500 hover:text-gray-700 text-xl"
          >
            &times;
          </button>

          <h2 class="text-lg font-bold mb-4">Upload Users via Excel</h2>

          <div class="mb-4">
            <.link
              href={@download_url}
              class="text-blue-600 hover:text-blue-800 underline text-sm flex items-center"
              download
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
                />
              </svg>
              Download Sample Template
            </.link>
          </div>

          <form phx-submit="save"  phx-change="validate" phx-target={@myself}>
            <div class="mb-4">
              <.live_file_input
                upload={@uploads.excel}
                class="block w-full border border-gray-300 rounded p-2"
              />
              <p class="text-xs text-gray-500 mt-1">Only .xlsx and .xls files are accepted</p>
            </div>

            <div class="flex justify-between items-center">
              <div class="text-sm text-gray-600">
                <%= if Enum.any?(@uploads.excel.entries) do %>
                  Selected: {hd(@uploads.excel.entries).client_name}
                <% end %>
              </div>
              <div>
                <.button
                  type="submit"
                  class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded"
                >
                  Upload
                </.button>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
    """
  end
end
