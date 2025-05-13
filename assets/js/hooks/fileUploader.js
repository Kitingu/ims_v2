export const FileUploadHook = {
    mounted() {
      this.el.addEventListener("change", (e) => {
        if (this.el.files.length > 0) {
          this.pushEventTo(this.el, "file_selected", {});
        }
      });
    }
  };
  
  export const configureUploaders = (liveSocket) => {
    liveSocket.uploaders = {
      file: {
        progress: (entries, to, socket) => {
          entries.forEach(entry => {
            if (entry.progress == 100) {
              setTimeout(() => {
                const progressEvent = new CustomEvent("progress", { 
                  detail: { progress: 0 } 
                });
                socket.uploaders.file.activeEntries.get(entry.ref)
                  .progressEventTarget.dispatchEvent(progressEvent);
              }, 100);
            }
          });
        }
      }
    };
  };