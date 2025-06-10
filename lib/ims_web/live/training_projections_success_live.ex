# lib/ims_web/live/training_projections_success_live.ex
defmodule ImsWeb.TrainingProjectionsSuccessLive do
  use ImsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-green-50 flex items-center justify-center">
      <div class="bg-white p-8 rounded shadow-lg text-center">
        <h1 class="text-2xl font-bold text-green-700">Submission Successful!</h1>
        <p class="text-gray-700 mt-2">Your training projection has been submitted successfully.</p>
        <div class="mt-4">

        </div>
      </div>
    </div>
    """
  end
end
