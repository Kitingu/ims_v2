defmodule ImsWeb.JobGroupLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage job_group records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="job_group-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Job group</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{job_group: job_group} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Accounts.change_job_group(job_group))
     end)}
  end

  @impl true
  def handle_event("validate", %{"job_group" => job_group_params}, socket) do
    changeset = Accounts.change_job_group(socket.assigns.job_group, job_group_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"job_group" => job_group_params}, socket) do
    save_job_group(socket, socket.assigns.action, job_group_params)
  end

  defp save_job_group(socket, :edit, job_group_params) do
    case Accounts.update_job_group(socket.assigns.job_group, job_group_params) do
      {:ok, job_group} ->
        notify_parent({:saved, job_group})

        {:noreply,
         socket
         |> put_flash(:info, "Job group updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_job_group(socket, :new, job_group_params) do
    case Accounts.create_job_group(job_group_params) do
      {:ok, job_group} ->
        notify_parent({:saved, job_group})

        {:noreply,
         socket
         |> put_flash(:info, "Job group created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
