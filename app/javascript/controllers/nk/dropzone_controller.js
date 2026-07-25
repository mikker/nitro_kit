import { Controller } from "@hotwired/stimulus";
import DirectUploadSession from "controllers/nk/dropzone/direct_upload";
import {
  formatBytes,
  rejectionMessage,
  validateFiles,
} from "controllers/nk/dropzone/file_rules";
import {
  acquireFormSubmitLock,
  releaseFormSubmitLock,
} from "controllers/nk/dropzone/form_submit_lock";

export default class extends Controller {
  static targets = [
    "input",
    "status",
    "error",
    "previewList",
    "previewTemplate",
  ];
  static values = {
    directUpload: Boolean,
    maxFiles: Number,
    maxBytes: Number,
    accept: String,
  };

  connect() {
    this.entries = [];
    this.nextIdentifier = 1;
    this.dragDepth = 0;
    this.initialInputDisabled = this.inputTarget.disabled;
    this.submitLockOwner = {};

    const files = Array.from(this.inputTarget.files);
    if (files.length > 0) this.replaceFiles(files);
  }

  disconnect() {
    this.release({ clearInput: false });
  }

  select() {
    this.replaceFiles(Array.from(this.inputTarget.files));
  }

  dragEnter(event) {
    if (!this.hasFiles(event)) return;

    event.preventDefault();
    this.dragDepth += 1;
    this.element.dataset.state = "drag";
  }

  dragOver(event) {
    if (!this.hasFiles(event)) return;

    event.preventDefault();
    event.dataTransfer.dropEffect = "copy";
  }

  dragLeave(event) {
    if (!this.hasFiles(event)) return;

    event.preventDefault();
    this.dragDepth = Math.max(0, this.dragDepth - 1);
    if (this.dragDepth === 0) this.reflectState();
  }

  drop(event) {
    if (!this.hasFiles(event)) return;

    event.preventDefault();
    this.dragDepth = 0;
    this.replaceFiles(Array.from(event.dataTransfer.files));
  }

  remove(event) {
    const item = event.currentTarget.closest("[data-slot='dropzone-preview']");
    const entry = this.entries.find(
      (candidate) => candidate.id === item?.dataset.fileId,
    );
    if (!entry) return;

    this.releaseEntry(entry, { removeElement: true });
    this.entries = this.entries.filter((candidate) => candidate !== entry);
    this.syncNativeFiles();
    this.clearError();
    if (this.uploadingEntries.length === 0) this.restoreSubmitControls();

    const failed = this.entries.find(
      (candidate) => candidate.state === "error",
    );
    if (failed) this.showError(`${failed.file.name} could not be uploaded.`);

    this.reflectState();
    this.announceSelection();
  }

  submit(event) {
    const form = this.element.closest("form");
    if (!form || event.target !== form) return;

    if (this.uploadingEntries.length > 0) {
      event.preventDefault();
      this.showError("Wait for uploads to finish before submitting the form.");
      return;
    }

    if (
      this.directUploadValue &&
      this.entries.some((entry) => entry.state !== "success")
    ) {
      event.preventDefault();
      this.showError(
        "Remove failed files or choose them again before submitting the form.",
      );
      return;
    }

    if (this.directUploadValue && this.entries.length > 0) {
      this.inputTarget.disabled = true;
    }
  }

  teardown() {
    this.release({ clearInput: true });
  }

  release({ clearInput }) {
    const input = this.element.querySelector(
      ':scope > [data-slot="dropzone-input"]',
    );
    const previewList = this.element.querySelector(
      ':scope > [data-slot="dropzone-preview-list"]',
    );
    const status = this.element.querySelector(
      ':scope > [data-slot="dropzone-status"]',
    );
    const error = this.element.querySelector(
      ':scope > [data-slot="dropzone-error"]',
    );

    this.entries?.forEach((entry) =>
      this.releaseEntry(entry, { removeElement: true }),
    );
    this.entries = [];
    this.restoreSubmitControls();
    this.dragDepth = 0;

    if (input) {
      input.disabled = this.initialInputDisabled;
      input.setCustomValidity("");
      input.removeAttribute("aria-invalid");
      if (clearInput) input.value = "";
    }
    if (previewList) {
      previewList.replaceChildren();
      previewList.hidden = true;
    }
    const selectedCount = input ? input.files.length : 0;
    if (status) {
      status.textContent =
        selectedCount === 0
          ? "No files selected."
          : `${selectedCount} ${selectedCount === 1 ? "file" : "files"} selected.`;
    }
    if (error) {
      error.textContent = "";
      error.hidden = true;
    }
    this.element.dataset.state = this.initialInputDisabled
      ? "disabled"
      : selectedCount > 0
        ? "success"
        : "idle";
  }

  replaceFiles(files) {
    this.entries.forEach((entry) =>
      this.releaseEntry(entry, { removeElement: true }),
    );
    this.entries = [];
    this.restoreSubmitControls();
    this.clearError();

    const validation = validateFiles(files, {
      maxFiles: this.maxFilesValue,
      maxBytes: this.hasMaxBytesValue ? this.maxBytesValue : null,
      accept: this.hasAcceptValue ? this.acceptValue : null,
    });
    validation.accepted.forEach((file) => this.addFile(file));
    this.syncNativeFiles();

    if (this.directUploadValue) {
      this.entries.forEach((entry) => this.startUpload(entry));
    } else {
      this.entries.forEach((entry) =>
        this.updateEntry(entry, "success", 0, "Ready to submit"),
      );
    }

    this.reflectState();
    this.announceSelection();
    if (validation.rejected.length > 0) {
      this.showError(rejectionMessage(validation.rejected), {
        blocking: this.entries.length === 0,
      });
    }
  }

  addFile(file) {
    const fragment = this.previewTemplateTarget.content.cloneNode(true);
    const element = fragment.querySelector("[data-slot='dropzone-preview']");
    const id = String(this.nextIdentifier++);
    element.dataset.fileId = id;
    element.querySelector("[data-slot='dropzone-file-name']").textContent =
      file.name;
    element.querySelector("[data-slot='dropzone-file-size']").textContent =
      formatBytes(file.size);

    const remove = element.querySelector(
      "[data-slot='dropzone-remove-control']",
    );
    remove.setAttribute("aria-label", `Remove ${file.name}`);
    const progress = element.querySelector("[data-slot='dropzone-progress']");
    progress.setAttribute("aria-label", `Upload progress for ${file.name}`);
    progress.hidden = !this.directUploadValue;

    const preview = element.querySelector(
      "[data-slot='dropzone-preview-image']",
    );
    let objectUrl = null;
    if (file.type.startsWith("image/")) {
      objectUrl = URL.createObjectURL(file);
      preview.src = objectUrl;
      preview.hidden = false;
    }

    this.previewListTarget.append(fragment);
    this.previewListTarget.hidden = false;
    this.entries.push({ id, file, element, objectUrl, state: "queued" });
  }

  startUpload(entry) {
    entry.state = "uploading";
    this.updateEntry(entry, "uploading", 0, "Uploading");
    this.reflectState();
    this.disableSubmitControls();

    entry.upload = new DirectUploadSession(
      entry.file,
      this.inputTarget.dataset.directUploadUrl,
      {
        onProgress: (event) => this.progress(entry, event),
        onComplete: (error, attributes) =>
          this.completeUpload(entry, error, attributes),
      },
    );
    entry.upload.start();
  }

  completeUpload(entry, error, attributes) {
    if (entry.cancelled) return;

    if (error) {
      this.updateEntry(entry, "error", 0, "Upload failed");
      this.showError(`${entry.file.name} could not be uploaded: ${error}`);
    } else {
      entry.hiddenInput = this.createSignedIdInput(attributes.signed_id);
      this.updateEntry(entry, "success", 100, "Uploaded");
    }

    this.reflectState();
    if (this.uploadingEntries.length === 0) this.restoreSubmitControls();
    this.announceSelection();
  }

  progress(entry, event) {
    if (!event.lengthComputable || entry.cancelled) return;

    const percentage = Math.round((event.loaded / event.total) * 100);
    this.updateEntry(
      entry,
      "uploading",
      percentage,
      `Uploading ${percentage}%`,
    );
  }

  updateEntry(entry, state, progress, message) {
    entry.state = state;
    entry.element.dataset.state = state;
    entry.element.querySelector("[data-slot='dropzone-progress']").value =
      progress;
    entry.element.querySelector(
      "[data-slot='dropzone-file-status']",
    ).textContent = message;
  }

  createSignedIdInput(value) {
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = this.inputTarget.name;
    input.value = value;
    input.dataset.slot = "dropzone-signed-id";
    this.inputTarget.insertAdjacentElement("afterend", input);
    return input;
  }

  releaseEntry(entry, { removeElement }) {
    entry.cancelled = true;
    entry.upload?.cancel();
    entry.upload = null;
    entry.hiddenInput?.remove();
    if (entry.objectUrl) URL.revokeObjectURL(entry.objectUrl);
    if (removeElement) entry.element.remove();
  }

  syncNativeFiles() {
    const transfer = new DataTransfer();
    this.entries.forEach((entry) => transfer.items.add(entry.file));
    this.inputTarget.files = transfer.files;
    this.previewListTarget.hidden = this.entries.length === 0;
  }

  reflectState() {
    if (this.dragDepth > 0) return;

    if (
      !this.errorTarget.hidden ||
      this.entries.some((entry) => entry.state === "error")
    ) {
      this.element.dataset.state = "error";
    } else if (this.uploadingEntries.length > 0) {
      this.element.dataset.state = "uploading";
    } else if (this.entries.length > 0) {
      this.element.dataset.state = "success";
    } else {
      this.element.dataset.state = "idle";
    }
  }

  announceSelection() {
    const count = this.entries.length;
    if (count === 0) {
      this.statusTarget.textContent = "No files selected.";
    } else if (this.uploadingEntries.length > 0) {
      this.statusTarget.textContent = `Uploading ${count} ${
        count === 1 ? "file" : "files"
      }.`;
    } else if (this.entries.some((entry) => entry.state === "error")) {
      this.statusTarget.textContent = `${count} ${
        count === 1 ? "file needs" : "files need"
      } attention.`;
    } else if (
      this.directUploadValue &&
      this.entries.every((entry) => entry.state === "success")
    ) {
      this.statusTarget.textContent = `${count} ${
        count === 1 ? "file" : "files"
      } uploaded.`;
    } else {
      this.statusTarget.textContent = `${count} ${
        count === 1 ? "file" : "files"
      } ready to submit.`;
    }
  }

  showError(message, { blocking = true } = {}) {
    this.errorTarget.textContent = message;
    this.errorTarget.hidden = false;
    this.inputTarget.setCustomValidity(blocking ? message : "");
    if (blocking) {
      this.inputTarget.setAttribute("aria-invalid", "true");
    } else {
      this.inputTarget.removeAttribute("aria-invalid");
    }
    this.element.dataset.state = "error";
  }

  clearError() {
    this.errorTarget.textContent = "";
    this.errorTarget.hidden = true;
    this.inputTarget.setCustomValidity("");
    this.inputTarget.removeAttribute("aria-invalid");
  }

  disableSubmitControls() {
    const form = this.element.closest("form");
    if (this.lockedForm && this.lockedForm !== form) {
      releaseFormSubmitLock(this.lockedForm, this.submitLockOwner);
    }

    this.lockedForm = form;
    acquireFormSubmitLock(form, this.submitLockOwner);
  }

  restoreSubmitControls() {
    releaseFormSubmitLock(this.lockedForm, this.submitLockOwner);
    this.lockedForm = null;
  }

  hasFiles(event) {
    return Array.from(event.dataTransfer?.types || []).includes("Files");
  }

  get uploadingEntries() {
    return this.entries.filter((entry) => entry.state === "uploading");
  }
}
