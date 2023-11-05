import { signal, effect } from "@preact/signals";

export const urlSyncedSignal = (name, default_value) => {
  const urlParams = new URLSearchParams(window.location.search);
  const sig = signal(urlParams.get(name) || default_value);

  effect(() => {
    if (urlParams.get(name) !== sig.value) {
      urlParams.set(name, sig.value);
      window.history.replaceState(null, null, "?" + urlParams);
    }
  });
  return sig;
};
