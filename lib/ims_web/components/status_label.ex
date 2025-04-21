defmodule ImsWeb.Components.StatusLabel do
  use Phoenix.Component

  attr :status, :any, required: true

  def status_label(assigns) do
    ~H"""
    <span class={status_class(@status)}>
      {format_status(@status)}
    </span>
    """
  end

  defp status_class(:available),
    do:
      "inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold bg-green-100 text-green-800"

  defp status_class("approved"),
    do:
      "inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold bg-green-100 text-green-800"

  defp status_class(:assigned),
    do:
      "inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-800"

  defp status_class(:revoked),
    do:
      "inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold bg-red-100 text-red-800"

  defp status_class("rejected"),
    do:
    "inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold bg-red-100 text-red-800"

  defp status_class(:lost),
    do:
      "inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold bg-yellow-100 text-yellow-800"

  defp status_class(:decommissioned),
    do:
      "inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold bg-gray-200 text-gray-700"

  defp status_class(_),
    do:
      "inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-800"

  defp format_status(status) when is_atom(status) do
    status
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_status(status) do
    status
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  # defp normalize_status(status) when is_binary(status), do: String.to_atom(status)
  # defp normalize_status(status) when is_atom(status), do: status
end
