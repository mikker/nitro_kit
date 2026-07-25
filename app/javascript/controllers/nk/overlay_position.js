export function positionOverlay(trigger, overlay, placement) {
  const triggerRect = trigger.getBoundingClientRect();
  overlay.style.setProperty("--_nk-combobox-width", `${triggerRect.width}px`);
  const overlayRect = overlay.getBoundingClientRect();
  const gap = 4;
  const inset = 16;
  const [side, alignment] = placement.split("-");
  const preferredTop =
    side === "top"
      ? triggerRect.top - overlayRect.height - gap
      : triggerRect.bottom + gap;
  const preferredLeft =
    alignment === "end"
      ? triggerRect.right - overlayRect.width
      : triggerRect.left;
  const top = Math.min(
    Math.max(preferredTop, inset),
    window.innerHeight - overlayRect.height - inset,
  );
  const left = Math.min(
    Math.max(preferredLeft, inset),
    window.innerWidth - overlayRect.width - inset,
  );

  overlay.style.setProperty("--_nk-overlay-top", `${top}px`);
  overlay.style.setProperty("--_nk-overlay-left", `${left}px`);
}

export function observeOverlayPosition(callback) {
  document.addEventListener("scroll", callback, true);
  window.addEventListener("resize", callback);

  return () => {
    document.removeEventListener("scroll", callback, true);
    window.removeEventListener("resize", callback);
  };
}
