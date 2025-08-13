defmodule ImsWeb.Welfare.MemberLive.Index do
  use ImsWeb, :live_view

  alias Ims.Welfare
  alias Ims.Welfare.Member

  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]

  # --------- Mount / Params ---------

  @impl true
  def mount(_params, _session, socket) do
    filters = %{}
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    socket =
      socket
      |> assign(:csrf_token, csrf_token)
      |> assign(:page, 1)
      |> assign(:filters, filters)
      |> assign(:loading?, false)
      |> assign(:flash_info, nil)
      |> assign(:members, fetch_records(filters, @paginator_opts))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    page = String.to_integer(params["page"] || "1")

    # Accept only known filter keys; drop blanks
    raw_filters =
      params
      |> Map.take(["status", "user_id"])
      |> Enum.reject(fn {_k, v} -> v in [nil, ""] end)
      |> Enum.into(%{})

    filters = parse_filters(raw_filters)

    socket =
      socket
      |> assign(:page, page)
      |> assign(:filters, raw_filters) # keep raw for query string round-trips
      |> assign(:members, fetch_records(filters, Keyword.put(@paginator_opts, :page, page)))

    {:noreply, socket}
  end

  # --------- Events ---------

  # From form submit: push filters into URL as query params (single source of truth)
  @impl true
  def handle_event("filter", %{"filters" => raw_filters}, socket) do
    {:noreply, push_patch(socket, to: ~p"/welfare/members?#{compact_query(raw_filters)}")}
  end

  # Keep a friendlier name like in the Asset LV
  @impl true
  def handle_event("apply_filters", %{} = raw_filters, socket) do
    {:noreply, push_patch(socket, to: ~p"/welfare/members?#{compact_query(raw_filters)}")}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/welfare/members")}
  end

  @impl true
  def handle_event("refresh_all", _params, socket) do
    Enum.each(socket.assigns.members.entries || socket.assigns.members, &Welfare.refresh_member_balance/1)

    {:noreply,
     socket
     |> put_flash(:info, "All visible members refreshed.")
     |> push_patch(to: ~p"/welfare/members?#{compact_query(socket.assigns.filters)}")}
  end

  @impl true
  def handle_event("refresh_member", %{"id" => id}, socket) do
    member = Welfare.get_member!(String.to_integer(id))
    _ = Welfare.refresh_member_balance(member)

    {:noreply,
     socket
     |> put_flash(:info, "Member ##{id} balance refreshed.")
     |> push_patch(to: ~p"/welfare/members?#{compact_query(socket.assigns.filters)}")}
  end

  # --------- Helpers ---------

  # Normalize query string by dropping blanks
  defp compact_query(filters) do
    filters
    |> Enum.reject(fn {_k, v} -> v in ["", nil] end)
    |> Enum.into(%{})
  end

  # Turn raw (string-keyed) query params into typed filters for the context
  defp parse_filters(%{"status" => s} = params) do
    base = maybe_put(%{}, :status, s)

    case Map.get(params, "user_id") do
      nil -> base
      "" -> base
      uid ->
        case Integer.parse("#{uid}") do
          {int, _} -> Map.put(base, :user_id, int)
          :error -> base
        end
    end
  end

  defp parse_filters(params) when is_map(params), do: params

  defp maybe_put(map, _k, ""), do: map
  defp maybe_put(map, k, v) when v in [nil, ""], do: map
  defp maybe_put(map, k, v), do: Map.put(map, k, v)

  # Centralized fetch (swap in your paginator if/when available)
  defp fetch_records(filters, opts) do
    # If you introduce pagination later, return a %Scrivener.Page{} here.
    # For now, keep it simple and just return a list or a struct your UI expects.
    _opts = Keyword.merge(@paginator_opts, opts)
    Welfare.list_members(filters)
  end

  # --------- View Utilities ---------

  defp money(nil), do: "0"
  defp money(%Decimal{} = d), do: Decimal.to_string(d, :normal)
  defp money(v) when is_integer(v), do: Integer.to_string(v)
  defp money(v) when is_float(v), do: :io_lib.format("~.2f", [v]) |> IO.iodata_to_binary()
  defp money(v) when is_binary(v), do: v

  defp eligibility_badge(true),
    do: %{class: "px-2 py-1 rounded bg-emerald-100 text-emerald-800", label: "Eligible"}

  defp eligibility_badge(false),
    do: %{class: "px-2 py-1 rounded bg-rose-100 text-rose-800", label: "Not eligible"}
end
