import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import datepicker from "./hooks/datepicker";
import { FileUploadHook, configureUploaders } from "./hooks/fileUploader";

// import "select2/dist/css/select2.css"

// import selectHook from "./hooks/select2";

import Alpine from "alpinejs";
window.Alpine = Alpine;
Alpine.start();





let hooks = {
  Datepicker: datepicker,
  FileUploadHook: FileUploadHook,
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
