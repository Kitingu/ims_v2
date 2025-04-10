import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import datepicker from "./hooks/datepicker";


// import "select2/dist/css/select2.css"

// import selectHook from "./hooks/select2";

import Alpine from "alpinejs";
window.Alpine = Alpine;
Alpine.start();





let hooks = {
  Datepicker: datepicker,
};

hooks.select2JS = {
  mounted() {
    this.initSelect2();

    // Handle LiveView updates
    this.handleEvent("update_select_options", ({ options, selected_value }) => {
      if (this.el.id === options.target_id) {
        this.updateOptions(options.data, selected_value);
      }
    });
  },

  initSelect2() {
    const el = this.el;
    const placeholder = el.dataset.placeholder || "Select an option";

    $(el).select2({
      placeholder: placeholder,
      dropdownParent: $(el).parent(),
      width: '100%'
    }).on('change', (e) => {
      const eventName = el.dataset.phxEvent || "select_changed";
      const payloadKey = el.name || "value";

      this.pushEventTo(el, eventName, {
        [payloadKey]: e.target.value,
        select_id: el.id
      });
    });
  },

  updateOptions(options, selectedValue) {
    $(this.el).empty().select2('destroy');

    // Add new options
    options.forEach(opt => {
      const isSelected = opt.id === selectedValue;
      $(this.el).append(new Option(opt.text, opt.id, false, isSelected));
    });

    this.initSelect2();

    // Trigger change if there's a selected value
    if (selectedValue) {
      $(this.el).val(selectedValue).trigger('change');
    }
  },

  destroyed() {
    $(this.el).select2('destroy');
  }
};


let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: hooks,
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to);
      }
    },
  },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// Connect if there are any LiveViews on the page
liveSocket.connect();

// Expose liveSocket on window for web console debugging
window.liveSocket = liveSocket;



// defmodule FleetmsWeb.PartLive.FilterFormComponent do
//   use FleetmsWeb, :live_component

//   @impl true
//   def render(assigns) do
//     ~H"""
//     <div>
//       <.header>
//         <%= @title %>
//       </.header>
//       <.simple_form
//         for={@filter_form}
//         id="filter-form"
//         phx-change="validate"
//         phx-submit="apply"
//         phx-target={@myself}
//         tabindex="-1"
//         aria-hidden="true"
//       >
//         <div class="px-4 space-y-4 md:px-6">
//           <div class="grid gap-6 md:grid-cols-2">
//             <div class="w-full" id="part_manufacturers-select" phx-update="ignore">
//               <.input
//                 field={@filter_form[:part_manufacturers]}
//                 options={@part_manufacturers}
//                 type="select"
//                 label="Part Manufacturers"
//                 multiple
//                 phx-hook="select2JS"
//                 style="width: 100%;"
//                 value={
//                   @filter_form.source.changes[:part_manufacturers] ||
//                     @filter_form.data[:part_manufacturers]
//                 }
//               />
//             </div>

//             <div class="w-full" id="part_categories-select" phx-update="ignore">
//               <.input
//                 field={@filter_form[:part_categories]}
//                 options={@part_categories}
//                 type="select"
//                 label="Part Categories"
//                 multiple
//                 phx-hook="select2JS"
//                 style="width: 100%;"
//                 value={
//                   @filter_form.source.changes[:part_categories] ||
//                     @filter_form.data[:part_categories]
//                 }
//               />
//             </div>
//           </div>
//           <div class="grid gap-6 md:grid-cols-2">
//             <div class="w-full">
//               <.input
//                 field={@filter_form[:unit_cost_min]}
//                 type="number"
//                 label="Unit Cost Min"
//                 value={
//                   @filter_form.source.changes[:unit_cost_min] ||
//                     @filter_form.data[:unit_cost_min]
//                 }
//               />
//             </div>

//             <div class="w-full">
//               <.input
//                 field={@filter_form[:unit_cost_max]}
//                 type="number"
//                 label="Unit Cost Max"
//                 value={
//                   @filter_form.source.changes[:unit_cost_max] ||
//                     @filter_form.data[:unit_cost_max]
//                 }
//               />
//             </div>
//           </div>
//         </div>
//         <!-- Modal footer -->
//         <div class="flex items-center p-6 space-x-4 rounded-b dark:border-gray-600">
//           <.button type="submit">
//             Apply
//           </.button>
//           <.button type="reset">
//             Reset
//           </.button>
//         </div>
//       </.simple_form>
//     </div>
//     """
//   end

//   @impl true
//   def update(assigns, socket) do
//     socket = assign(socket, assigns)
//     %{tenant: tenant, current_user: actor} = socket.assigns

//     filter_form =
//       build_filter_changeset(assigns.filter_form_data, %{})
//       |> to_form(as: "filter_form")

//     part_manufacturers =
//       Fleetms.Inventory.PartManufacturer.get_all!(tenant: tenant, actor: actor)
//       |> Enum.map(&{&1.name, &1.id})

//     part_categories =
//       Fleetms.Inventory.PartCategory.get_all!(tenant: tenant, actor: actor)
//       |> Enum.map(&{&1.name, &1.id})

//     socket =
//       socket
//       |> assign(:filter_form, filter_form)
//       |> assign(:part_manufacturers, part_manufacturers)
//       |> assign(:part_categories, part_categories)

//     {:ok, socket}
//   end

//   @impl true
//   def handle_event("validate", %{"filter_form" => form_params}, socket) do
//     filter_form =
//       build_filter_changeset(socket.assigns.filter_form_data, form_params)
//       |> Map.put(:action, :validate)
//       |> to_form(as: "filter_form")

//     {:noreply, assign(socket, :filter_form, filter_form)}
//   end

//   @impl true
//   def handle_event("apply", %{"filter_form" => form_params}, socket) do
//     build_filter_changeset(%{}, form_params)
//     |> Ecto.Changeset.apply_action(:create)
//     |> case do
//       {:ok, new_filter_form_data} ->
//         new_url_params =
//           new_filter_form_data
//           |> Map.merge(socket.assigns.paginate_sort_opts)
//           |> Map.merge(socket.assigns.search_params)

//         {:noreply, push_patch(socket, to: ~p"/parts?#{new_url_params}")}

//       {:error, changeset} ->
//         {:noreply, assign(socket, :filter_form, changeset |> to_form(as: "filter_form"))}
//     end
//   end

//   def build_filter_changeset(data, submit_params) do
//     types = %{
//       part_manufacturers: {:array, :string},
//       part_categories: {:array, :string},
//       unit_cost_min: :integer,
//       unit_cost_max: :integer
//     }

//     {data, types}
//     |> Ecto.Changeset.cast(submit_params, Map.keys(types))
//   end
// end
