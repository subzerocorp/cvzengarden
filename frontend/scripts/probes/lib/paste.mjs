/**
 * Pure calculations for the ZG-5 paste probes. Each returns a list of
 * reasons a probe should fail — empty means pass.
 *
 * `observed` is the shape `readPasteState` produces in the page:
 * `{ errorClass, errorText, name, hasJordan, src, themeHref, title }`.
 */

// Rust / serde vocabulary that must never reach an Author (case-sensitive).
export const SERDE_TOKENS = ["expected", "EOF", "invalid type", "serde", "Err(", "panicked"];

export function serdeTokenReasons(text) {
  return SERDE_TOKENS.filter((token) => String(text).includes(token)).map((token) => `error text contains the token ${JSON.stringify(token)}`);
}

// Why the panel does not show the expected error class with the expected
// words (`words` must all appear; `without` must none appear).
export function errorReasons(observed, { errorClass, words = [], without = [] }) {
  if (observed.errorClass !== errorClass) {
    return [`[data-paste-error] is ${JSON.stringify(observed.errorClass)}, wanted ${JSON.stringify(errorClass)}`];
  }
  const shown = JSON.stringify(observed.errorText);
  return [
    ...words.filter((word) => !observed.errorText.includes(word)).map((word) => `error text lacks ${JSON.stringify(word)}: ${shown}`),
    ...without.filter((word) => observed.errorText.includes(word)).map((word) => `error text names ${JSON.stringify(word)}: ${shown}`),
  ];
}

// Why a paste that must not touch the sandbox did.
export function unchangedReasons(before, after) {
  return after.name === before.name ? [] : [`.rz-name changed ${JSON.stringify(before.name)} → ${JSON.stringify(after.name)}`];
}

// Why the sandbox does not show `name` after an accepted paste, with the
// frame src and Theme link untouched and no error on the panel.
export function shownReasons(before, after, name) {
  return [
    ...(after.errorClass === null ? [] : [`[data-paste-error=${after.errorClass}] is showing`]),
    ...(after.name === name ? [] : [`.rz-name is ${JSON.stringify(after.name)}, wanted ${JSON.stringify(name)}`]),
    ...(after.src === before.src ? [] : [`iframe src changed to ${after.src}`]),
    ...(after.themeHref === before.themeHref ? [] : [`#theme-stylesheet changed ${before.themeHref} → ${after.themeHref}`]),
  ];
}

// Why the frame is not showing `name` under the Theme `href`.
export function switchedReasons(observed, { href, name }) {
  return [
    ...(observed.themeHref === href ? [] : [`#theme-stylesheet is ${observed.themeHref}, wanted ${href}`]),
    ...(observed.name === name ? [] : [`.rz-name is ${JSON.stringify(observed.name)}, wanted ${JSON.stringify(name)}`]),
  ];
}

// Why the crate did not reject a text the Chrome classified as not a résumé
// (the crate is the oracle; the Elm check must agree with it).
export function oracleReasons(outcome) {
  return outcome.ok ? ["the renderer accepted a text the Chrome rejected"] : [];
}

// Why the console did not receive the raw renderer error at debug level only.
export function debugOnlyReasons(consoleMessages, raw) {
  const carrying = consoleMessages.filter((message) => message.text.includes(raw));
  if (!carrying.some((message) => message.type === "debug")) {
    return ["raw renderer error was not sent to console.debug"];
  }
  return carrying.filter((message) => message.type !== "debug").map((message) => `raw renderer error also reached console.${message.type}`);
}

export function pageErrorReasons(pageErrors) {
  return pageErrors.map((message) => `pageerror: ${message}`);
}

// Why Forget did not drop the stored résumé.
export function forgottenReasons(stored) {
  return stored === null ? [] : [`localStorage['resumezen.resume'] is ${JSON.stringify(stored)}, wanted null`];
}

// Why a corrupt stored value did not restore silently to Jordan Hale.
export function silentRestoreReasons(observed, { stored, pageErrors, consoleMessages }) {
  const consoleErrors = consoleMessages.filter((message) => message.type === "error");
  return [
    ...(observed.name === "Jordan Hale" ? [] : [`.rz-name is ${JSON.stringify(observed.name)}, wanted "Jordan Hale"`]),
    ...(observed.errorClass === null ? [] : [`[data-paste-error=${observed.errorClass}] is showing`]),
    ...forgottenReasons(stored),
    ...pageErrorReasons(pageErrors),
    ...consoleErrors.map((message) => `console.error: ${message.text}`),
  ];
}
