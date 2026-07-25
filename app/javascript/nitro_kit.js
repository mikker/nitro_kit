import { Turbo } from "@hotwired/turbo-rails";

const runtimeKey = Symbol.for("nitro-kit.bootstrap");
const confirmEvent = "nitro-kit:confirm";
const confirmReadyEvent = "nitro-kit:confirm-ready";
const confirmDialogSelector = '[data-controller~="nk--confirm-dialog"]';

export const NitroKit = {
  start() {
    if (window[runtimeKey]) return window[runtimeKey];

    const confirm = (message) =>
      new Promise((resolve) => {
        if (requestConfirmation(message, resolve)) return;

        const dialog = document.querySelector(confirmDialogSelector);
        if (!dialog) return resolve(false);

        const handleReady = () => {
          cleanup();
          if (!requestConfirmation(message, resolve)) resolve(false);
        };
        const timeout = window.setTimeout(handleReady, 1_000);
        const cleanup = () => {
          window.clearTimeout(timeout);
          document.removeEventListener(confirmReadyEvent, handleReady);
        };

        document.addEventListener(confirmReadyEvent, handleReady);
        if (dialog.dataset.nkConfirmReady === "true") handleReady();
      });

    const runtime = { confirm };
    Turbo.config.forms.confirm = confirm;
    window[runtimeKey] = runtime;

    return runtime;
  },
};

function requestConfirmation(message, resolve) {
  const event = new CustomEvent(confirmEvent, {
    cancelable: true,
    detail: { message, resolve },
  });

  return !document.dispatchEvent(event);
}
