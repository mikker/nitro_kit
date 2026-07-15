const submitControlSelector = "button[type='submit'], input[type='submit']";
const locks = new WeakMap();

export function acquireFormSubmitLock(form, owner) {
  if (!form) return;

  let lock = locks.get(form);
  if (!lock) {
    lock = { owners: new Set(), controls: new Map() };
    locks.set(form, lock);
  }

  form.querySelectorAll(submitControlSelector).forEach((control) => {
    if (!lock.controls.has(control)) {
      lock.controls.set(control, control.disabled);
    }
    control.disabled = true;
  });
  lock.owners.add(owner);
}

export function releaseFormSubmitLock(form, owner) {
  const lock = form && locks.get(form);
  if (!lock || !lock.owners.delete(owner) || lock.owners.size > 0) return;

  lock.controls.forEach((initiallyDisabled, control) => {
    if (control.isConnected) control.disabled = initiallyDisabled;
  });
  locks.delete(form);
}
