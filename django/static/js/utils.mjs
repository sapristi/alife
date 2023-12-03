import { signal, effect } from "@preact/signals";
import { MD5 } from "md5";

export const urlSyncedSignals = (params) => {
  const urlParams = new URLSearchParams(window.location.search);
  let signals = [];
  for (let [name, default_value] of Object.entries(params)) {
    const sig = signal(urlParams.get(name) || default_value);
    signals.push(sig);
    effect(() => {
      if (urlParams.get(name) !== sig.value) {
        urlParams.set(name, sig.value);
        window.history.replaceState(null, null, "?" + urlParams);
      }
    });
  }
  return signals;
};

export const molHash = (mol) => {
  if (mol.length <= 5) {
    return `|${mol}|`;
  }
  let hash = MD5(mol).slice(0, 8).toUpperCase();
  return `#${hash}(${mol.length})`;
};

export const shortMolRepr = (mol) => {
  if (mol.length <= 5) {
    return `|${mol}|`;
  }
  let hash = MD5(mol).slice(0, 8).toUpperCase();
  return `#${hash}(${mol.length})`;
};

export const makeRandomGenerator = function (seed) {
  let nSeed = 0;
  if (typeof seed == "string") {
    for (let char of seed) {
      nSeed += char.charCodeAt(0);
    }
  } else {
    nSeed = seed;
  }
  var mask = 0xffffffff;
  var m_w = (123456789 + nSeed) & mask;
  var m_z = (987654321 - nSeed) & mask;

  return function () {
    m_z = (36969 * (m_z & 65535) + (m_z >>> 16)) & mask;
    m_w = (18000 * (m_w & 65535) + (m_w >>> 16)) & mask;

    var result = ((m_z << 16) + (m_w & 65535)) >>> 0;
    result /= 4294967296;
    return result;
  };
};
