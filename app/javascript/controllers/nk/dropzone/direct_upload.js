import { DirectUpload } from "@rails/activestorage";

export default class DirectUploadSession {
  constructor(file, url, { onProgress, onComplete }) {
    this.file = file;
    this.url = url;
    this.onProgress = onProgress;
    this.onComplete = onComplete;
  }

  start() {
    this.upload = new DirectUpload(this.file, this.url, {
      directUploadWillCreateBlobWithXHR: (request) => {
        this.bindRequest(request);
      },
      directUploadWillStoreFileWithXHR: (request) => {
        this.bindRequest(request, { tracksProgress: true });
      },
    });

    this.upload.create((error, attributes) => {
      if (this.cancelled) return;

      this.releaseRequest();
      this.onComplete(error, attributes);
    });
  }

  cancel() {
    this.cancelled = true;
    this.request?.abort();
    this.releaseRequest();
  }

  bindRequest(request, { tracksProgress = false } = {}) {
    if (this.cancelled) {
      queueMicrotask(() => request.abort());
      return;
    }

    this.releaseRequest();
    this.request = request;

    if (tracksProgress) {
      this.progressListener = (event) => this.onProgress(event);
      request.upload.addEventListener("progress", this.progressListener);
    }
  }

  releaseRequest() {
    if (this.request && this.progressListener) {
      this.request.upload.removeEventListener(
        "progress",
        this.progressListener,
      );
    }

    this.request = null;
    this.progressListener = null;
  }
}
