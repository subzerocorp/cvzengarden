/**
 * Calculations for the Wasm ↔ crate parity check: two byte buffers, one
 * verdict with the first differing offset named so a drift is locatable.
 */

// Index of the first byte where the buffers differ, or -1 when equal.
export function firstMismatch(expected, actual) {
  const limit = Math.min(expected.length, actual.length);
  for (let i = 0; i < limit; i += 1) {
    if (expected[i] !== actual[i]) {
      return i;
    }
  }
  return expected.length === actual.length ? -1 : limit;
}

// Reasons the buffers are not byte-identical (empty when they are).
export function parityReasons(expected, actual) {
  const at = firstMismatch(expected, actual);
  if (at === -1) {
    return [];
  }
  return [`first difference at byte ${at} (crate ${expected.length} B, wasm ${actual.length} B)`];
}
