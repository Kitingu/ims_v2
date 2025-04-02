defmodule ImsWeb.EmptyStateComponent do
  use Phoenix.LiveComponent

  @impl true
  def update(_assigns, socket) do
    {:ok, assign(socket, :image, ImsWeb.Endpoint.static_path("/assets/empty_state.svg"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col ">
      <div class="overflow-x-auto">
        <div class="inline-block min-w-full py-2 align-middle md:px-6 lg:px-8 ">
          <div class="overflow-x-auto ring-0 ">
            <div class="py-10 sm:py-20 flex-1 flex flex-col items-center min-h-full">
              <img class="h-28 w-32" src={@image} />
              <div class="space-y-1 text-center">
                <p class="text-base text-gray-900 font-semibold">No Information</p>
                <p class="text-sm text-gray-600">There is no information to display</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
