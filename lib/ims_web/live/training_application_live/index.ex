defmodule ImsWeb.TrainingApplicationLive.Index do
  use ImsWeb, :live_view
  import Phoenix.LiveView.Helpers

  alias Ims.Trainings
  alias Ims.Trainings.TrainingApplication
  alias Ims.Accounts
  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]

  @impl true
  def mount(_params, _session, socket) do
    filters = %{}
    current_user = socket.assigns.current_user

    filters =
      case Canada.Can.can?(current_user, ["list_all"], "training_applications") do
        true -> filters
        false -> Map.put(filters, "user_id", current_user.id)
      end

    socket =
      socket
      |> assign(
        :training_applications,
        fetch_records(filters, @paginator_opts)
      )
      |> assign(:selected_user, "")
      |> assign(:user_options, Enum.map(Accounts.list_users(), &{&1.first_name, &1.id}))
      |> assign(:page_title, "Listing Training applications")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Training application")
    |> assign(:training_application, Trainings.get_training_application!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Training application")
    |> assign(:training_application, %TrainingApplication{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Training applications")
    |> assign(:training_application, nil)
  end

  @impl true
  def handle_info(
        {ImsWeb.TrainingApplicationLive.FormComponent, {:saved, _training_application}},
        socket
      ) do
    {:noreply,
     assign(socket,
       training_applications: fetch_records(socket.assigns.filters, @paginator_opts)
     )}
  end

  def handle_event("filter_user", %{"user_id" => user_id}, socket) do
    IO.inspect(user_id, label: "user_id")

    filters =
      if user_id == "",
        do: %{},
        else:
          %{"user_id" => user_id}
          |> IO.inspect(label: "filters")

    applications = Ims.Trainings.TrainingApplication.search(filters) |> Ims.Repo.paginate()
    {:noreply, assign(socket, training_applications: applications, selected_user: user_id)}
  end

  def handle_event("search", %{"query" => query}, socket) do
    applications = Ims.Trainings.TrainingApplication.search(%{"institution" => query})
    {:noreply, assign(socket, training_applications: applications)}
  end

  def handle_event("export_csv", _, socket) do
    case TrainingApplication.generate_report(:csv) do
      {:ok, file_path} ->
        {:noreply,
         socket
         |> put_flash(:info, "CSV Export ready")
         |> push_event("download", %{file_path: file_path, filename: "training_applications.csv"})}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to generate CSV")}
    end
  end

  def handle_event("export_excel", _, socket) do
    case TrainingApplication.generate_report(:excel) do
      {:ok, binary_content} ->
        {:noreply,
         socket
         |> put_flash(:info, "Excel Export ready")
         |> push_event("download", %{
           content: Base.encode64(binary_content),
           filename: "training_applications.xlsx"
         })}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to generate Excel")}
    end
  end

  @impl true
  def handle_event("edit" <> id, _, socket) do
    training_application = Trainings.get_training_application!(id)
    {:noreply, assign(socket, training_application: training_application, live_action: :edit)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    training_application = Trainings.get_training_application!(id)
    {:ok, _} = Trainings.delete_training_application(training_application)

    {:noreply, stream_delete(socket, :training_applications, training_application)}
  end

  def days_to_period(days) when is_integer(days) do
    cond do
      days >= 365 && rem(days, 365) == 0 ->
        {"#{div(days, 365)} Year#{if div(days, 365) > 1, do: "s", else: ""}",
         "#{div(days, 365)}_years"}

      days >= 30 && rem(days, 30) == 0 ->
        {"#{div(days, 30)} Month#{if div(days, 30) > 1, do: "s", else: ""}",
         "#{div(days, 30)}_months"}

      days >= 7 && rem(days, 7) == 0 ->
        {"#{div(days, 7)} Week#{if div(days, 7) > 1, do: "s", else: ""}", "#{div(days, 7)}_weeks"}

      true ->
        {"#{days} Day#{if days > 1, do: "s", else: ""}", "#{days}_days"}
    end
  end

  def fetch_records(filters, opts) do
    opts = Keyword.merge(@paginator_opts, opts)

    TrainingApplication.search(filters)
    |> Ims.Repo.paginate(opts)
  end
end
