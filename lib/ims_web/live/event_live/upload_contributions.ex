defmodule ImsWeb.EventLive.UploadContributionsComponent do
  @moduledoc """
  LiveComponent for uploading contributions via Excel file with proper file handling.
  """
  use ImsWeb, :live_component

  @upload_dir Path.join([:code.priv_dir(:ims), "static", "uploads"])

  @impl true
  def mount(socket) do
    # Ensure upload directory exists
    ensure_upload_dir_exists()

    {:ok,
     socket
     |> allow_upload(:file,
       accept: ~w(.xlsx .xls),
       max_entries: 1,
       max_file_size: 5_000_000,
       auto_upload: false
     )
     |> assign(:uploaded_files, [])
     |> assign(:errors, [])
     |> assign(:form, to_form(%{}))
     |> assign(:file_selected, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto p-6 bg-white rounded-lg shadow-md">
      <h2 class="text-xl font-semibold mb-4">Upload Contributions Excel File</h2>

      <.form for={@form} phx-submit="save" phx-target={@myself} multipart>
        <div class="flex flex-col">
          <label class="block text-sm font-medium text-gray-700 mb-1">Excel File</label>
          <.live_file_input
            upload={@uploads.file}
            class="block w-full text-sm text-gray-500
                file:mr-4 file:py-2 file:px-4
                file:rounded-md file:border-0
                file:text-sm file:font-semibold
                file:bg-blue-50 file:text-blue-700
                hover:file:bg-blue-100"
            phx-change="file_selected"
          />
        </div>

        <.button
          type="submit"
          class={"w-full justify-center mt-4 #{unless @file_selected, do: "opacity-50 cursor-not-allowed"}"}
          disabled={!@file_selected}
        >
          Upload Contributions
        </.button>
      </.form>

      <%= if Enum.any?(@errors) do %>
        <div class="mt-4 p-3 bg-red-50 rounded-md">
          <h3 class="text-sm font-medium text-red-800">Upload Errors</h3>
          <div class="mt-2 text-sm text-red-700">
            <ul class="list-disc pl-5 space-y-1">
              <%= for err <- @errors do %>
                <li>{err}</li>
              <% end %>
            </ul>
          </div>
        </div>
      <% end %>

      <%= if Enum.any?(@uploaded_files) do %>
        <div class="mt-4 p-3 bg-green-50 rounded-md">
          <h3 class="text-sm font-medium text-green-800">Successfully Processed</h3>
          <div class="mt-2 text-sm text-green-700">
            File uploaded and queued for processing
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("file_selected", _params, socket) do
    {:noreply, assign(socket, :file_selected, true)}
  end

  @impl true
  def handle_event("save", _params, socket) do
    case uploaded_entries(socket, :file) do
      {[entry], []} ->
        process_uploaded_file(socket, entry)

      {[], []} ->
        {:noreply, assign(socket, :errors, ["Please select a file to upload"])}

      {[], [error | _]} ->
        {:noreply, assign(socket, :errors, [upload_error_to_string(error)])}
    end
  end

  defp process_uploaded_file(socket, entry) do
    dest_path = Path.join(@upload_dir, "#{Ecto.UUID.generate()}_#{entry.client_name}")

    result =
      consume_uploaded_entry(socket, entry, fn %{path: source_path} ->
        case File.cp(source_path, dest_path) do
          :ok -> {:ok, dest_path}
          {:error, reason} -> {:error, "file copy failed: #{reason}"}
        end
      end)

    case result do
       saved_path ->
        case enqueue_processing_job(saved_path) do
          {:ok, _job} ->
            {:noreply,
             socket
             |> assign(:uploaded_files, [entry.client_name])
             |> assign(:errors, [])
             |> assign(:file_selected, false)}

          {:error, reason} ->
            File.rm(saved_path)
            {:noreply, assign(socket, :errors, ["Job enqueue failed: #{inspect(reason)}"])}
        end

      {:error, reason} ->
        {:noreply, assign(socket, :errors, ["File processing failed: #{inspect(reason)}"])}
    end
  end

  # Helper function to ensure upload directory exists
  defp ensure_upload_dir_exists do
    unless File.exists?(@upload_dir) do
      File.mkdir_p!(@upload_dir)
    end
  end

  defp enqueue_processing_job(file_path) do
    job_attrs = %{"file_path" => file_path}
    Ims.Workers.ProcessContributionsWorker.new(job_attrs) |> Oban.insert()
  end

  defp upload_error_to_string(:too_large), do: "File is too large (max 5MB)"
  defp upload_error_to_string(:too_many_files), do: "Too many files (max 1)"
  defp upload_error_to_string(:not_accepted), do: "Invalid file type (.xlsx or .xls only)"
  defp upload_error_to_string(error), do: "Upload error: #{inspect(error)}"
end
