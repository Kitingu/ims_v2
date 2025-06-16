defmodule ImsWeb.TrainingProjectionsLive.Index do
  use ImsWeb, :live_view

  alias Ims.Trainings
  alias Ims.Trainings.TrainingProjections

  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]

  @impl true
  def mount(_params, _session, socket) do
    filters = %{}

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:page, 1)
      |> assign(:training_projections, fetch_records(filters, @paginator_opts))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Training projections")
    |> assign(:training_projections, Trainings.get_training_projections!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Training projections")
    |> assign(:training_projections, %TrainingProjections{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Training projections")
    |> assign(:training_projections, fetch_records(socket.assigns.filters, @paginator_opts))
  end

  @impl true
  def handle_info(
        {ImsWeb.TrainingProjectionsLive.FormComponent, {:saved, training_projections}},
        socket
      ) do
    {:noreply, stream_insert(socket, :training_projections_collection, training_projections)}
  end

  @impl true
  def handle_event("edit" <> id, _params, socket) do
    training_projection =
      Trainings.get_training_projections!(id) |> IO.inspect(label: "Training Projection")

    {:noreply,
     socket
     |> assign(:page_title, "Edit Training projections")
     |> assign(:training_projection, training_projection)
     |> assign(:live_action, :edit)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    training_projections = Trainings.get_training_projections!(id)
    {:ok, _} = Trainings.delete_training_projections(training_projections)

    {:noreply, stream_delete(socket, :training_projections_collection, training_projections)}
  end

  def fetch_records(filters, opts) do
    filters = atomize_keys(filters)
    opts = Keyword.merge(@paginator_opts, opts)

    TrainingProjections.search(filters)
    |> Ims.Repo.paginate(opts)
  end

  defp atomize_keys(map) do
    for {k, v} <- map, into: %{} do
      {maybe_atom(k), v}
    end
  end

  defp maybe_atom(k) when is_binary(k), do: String.to_existing_atom(k)
  defp maybe_atom(k), do: k
end
