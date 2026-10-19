// Remote Combobox transport. The application renders Combobox::Results as
// HTML; these helpers fetch it and keep only the newest search alive.

const RESULTS_SELECTOR = '[data-nk="combobox-results"]';

export async function fetchResults(
  url,
  { signal, method = "get", params = {} } = {},
) {
  const headers = { Accept: "text/html, application/xhtml+xml" };
  const options = { headers, signal, credentials: "same-origin" };

  if (method !== "get") {
    const body = new FormData();
    Object.entries(params).forEach(([key, value]) => body.append(key, value));
    // Rails reads the override from POST bodies for PATCH and PUT.
    if (method !== "post") body.append("_method", method);
    const token = document.querySelector('meta[name="csrf-token"]')?.content;
    if (token) headers["X-CSRF-Token"] = token;
    Object.assign(options, { method: "POST", body });
  }

  const response = await fetch(url, options);
  const html = await response.text();
  if (!response.ok)
    throw new Error(`Combobox results failed: ${response.status}`);

  const results = new DOMParser()
    .parseFromString(html, "text/html")
    .querySelector(RESULTS_SELECTOR);
  if (!results) throw new Error("Combobox response has no Combobox::Results");

  // Copy the collection first: adopting a node removes it from the live list.
  return Array.from(results.children).map((item) => document.adoptNode(item));
}

// Starting a request aborts its predecessor, and a sequence number discards
// any predecessor response that still resolves, so an older search can never
// overwrite newer results.
export class LatestRequest {
  sequence = 0;
  controller = null;

  async run(request) {
    this.cancel();
    const sequence = this.sequence;
    const controller = new AbortController();
    this.controller = controller;

    try {
      const result = await request(controller.signal);
      return sequence === this.sequence ? result : null;
    } catch (error) {
      if (sequence !== this.sequence) return null;
      throw error;
    } finally {
      if (this.controller === controller) this.controller = null;
    }
  }

  cancel() {
    this.sequence += 1;
    this.controller?.abort();
    this.controller = null;
  }

  isStale(error) {
    return error?.name === "AbortError";
  }
}
