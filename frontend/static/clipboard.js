/**
 * Clipboard action. Isolated so ports.js stays wiring: Elm sends the
 * string, this module writes it, and the boolean result goes back.
 */

export function writeClipboard(text) {
  return navigator.clipboard.writeText(text);
}
