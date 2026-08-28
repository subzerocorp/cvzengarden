/**
 * Chrome ↔ sandbox bridge. Wiring only: ports subscribe to per-concern
 * modules (`render.js` for the Wasm renderer and the sandbox swap).
 *
 * Theme id math lives in Elm (`ThemeId`). This file pushes history and
 * swaps Theme sheets. The live edit inside the iframe is the Theme
 * <link> set: keep the outgoing sheet until the incoming sheet is ready
 * so a committed frame never paints UA-default serif on a blank canvas.
 * article.rz-resume is replaced only by crate output (`swapResume`).
 * iframe.src stays sandbox.html.
 */
import { writeClipboard } from "./clipboard.js";
import { gardenSearch, readGardenQuery } from "./garden-query.js";
import { contractVersion, render, swapResume, version } from "./render.js";

const FRAME_ID = "garden-frame";
const THEME_LINK_ID = "theme-stylesheet";
const STORAGE_KEY = "resumezen.resume";

const app = Elm.Main.init({
  node: document.getElementById("root"),
  flags: {
    prefersDark: window.matchMedia("(prefers-color-scheme: dark)").matches,
    themeQuery: new URLSearchParams(window.location.search).get("theme") || "",
    viewQuery: new URLSearchParams(window.location.search).get("view") || "",
  },
});

let previewMedia = "screen";
const originalMedia = new WeakMap();
let themeSwapGen = 0;

const prefersDark = window.matchMedia("(prefers-color-scheme: dark)");
prefersDark.addEventListener("change", (event) => {
  app.ports.preferDarkChanged.send(event.matches);
});

function gardenFrame() {
  return document.getElementById(FRAME_ID);
}

function waitForFrame() {
  const iframe = gardenFrame();
  if (!iframe) {
    return new Promise((resolve) => {
      requestAnimationFrame(() => resolve(waitForFrame()));
    });
  }

  const doc = iframe.contentDocument;
  if (doc && doc.readyState !== "loading" && doc.querySelector(".rz-resume")) {
    return Promise.resolve(iframe);
  }

  return new Promise((resolve) => {
    const onLoad = () => resolve(iframe);
    iframe.addEventListener("load", onLoad, { once: true });
  });
}

function walkMediaRules(rules, visit) {
  if (!rules) {
    return;
  }

  for (const rule of Array.from(rules)) {
    if (rule.type === CSSRule.MEDIA_RULE) {
      visit(rule);
    }

    if (rule.cssRules) {
      walkMediaRules(rule.cssRules, visit);
    }
  }
}

function rememberMedia(rule) {
  if (!originalMedia.has(rule)) {
    originalMedia.set(rule, rule.media.mediaText);
  }
  return originalMedia.get(rule);
}

function emulatePrint(doc) {
  for (const sheet of Array.from(doc.styleSheets)) {
    try {
      walkMediaRules(sheet.cssRules, (rule) => {
        const original = rememberMedia(rule);
        if (/\bprint\b/.test(original)) {
          rule.media.mediaText = "all";
        } else if (/\bscreen\b/.test(original)) {
          rule.media.mediaText = "not all";
        }
      });
    } catch {
      // Cross-origin or unreadable sheet — ignore.
    }
  }
}

function restoreScreen(doc) {
  for (const sheet of Array.from(doc.styleSheets)) {
    try {
      walkMediaRules(sheet.cssRules, (rule) => {
        if (originalMedia.has(rule)) {
          rule.media.mediaText = originalMedia.get(rule);
        }
      });
    } catch {
      // ignore
    }
  }
}

function applyPreview(doc) {
  if (previewMedia === "print") {
    emulatePrint(doc);
  } else {
    restoreScreen(doc);
  }
}

function whenStylesheetReady(link) {
  if (!link) {
    return Promise.resolve();
  }

  try {
    const sheet = link.sheet;
    if (sheet && sheet.cssRules) {
      return Promise.resolve();
    }
  } catch {
    // sheet exists but is not readable yet
  }

  return new Promise((resolve) => {
    const done = () => resolve();
    link.addEventListener("load", done, { once: true });
    link.addEventListener("error", done, { once: true });
  });
}

/**
 * Dual-link swap: insert the incoming Theme sheet, wait until it has
 * rules, then drop the outgoing sheet. A stub that only writes
 * #theme-stylesheet href (dropping the old sheet first) flashes
 * UA-default serif on a white canvas.
 */
async function setThemeHref(href) {
  const iframe = await waitForFrame();
  const doc = iframe.contentDocument;
  if (!doc) {
    return;
  }

  const gen = ++themeSwapGen;
  const current = doc.getElementById(THEME_LINK_ID);
  const currentHref = current?.getAttribute("href") || "";

  if (current && currentHref === href) {
    try {
      if (current.sheet && current.sheet.cssRules) {
        applyPreview(doc);
        return;
      }
    } catch {
      // fall through and rebuild
    }
  }

  const incoming = doc.createElement("link");
  incoming.rel = "stylesheet";
  incoming.setAttribute("href", href);
  incoming.setAttribute("data-theme-incoming", "true");

  if (current && current.parentNode) {
    current.parentNode.insertBefore(incoming, current.nextSibling);
  } else {
    doc.head.appendChild(incoming);
  }

  await whenStylesheetReady(incoming);
  if (gen !== themeSwapGen) {
    incoming.remove();
    return;
  }

  incoming.id = THEME_LINK_ID;
  incoming.removeAttribute("data-theme-incoming");

  if (current && current !== incoming) {
    current.remove();
  }

  applyPreview(doc);
}

async function setPreviewMedia(media) {
  previewMedia = media === "print" ? "print" : "screen";
  const iframe = await waitForFrame();
  const doc = iframe.contentDocument;
  if (!doc) {
    return;
  }
  applyPreview(doc);
}

function currentHref() {
  return window.location.pathname + window.location.search + window.location.hash;
}

function pushGarden(next, state) {
  if (next !== currentHref()) {
    window.history.pushState(state, "", next);
  }
}

app.ports.setThemeHref.subscribe((href) => {
  setThemeHref(href);
});

app.ports.setPreviewMedia.subscribe((media) => {
  setPreviewMedia(media);
});

/**
 * Garden Print prints the child document (contentWindow.print()).
 * File → Print / Ctrl+P print the chrome shell. The iframe is a
 * replaced element: child break-before does not paginate the parent,
 * and a viewport-height box drops page 2. Hoist .rz-resume plus the
 * already-loaded Theme sheet into the parent so shell print paginates
 * like the child document (Nightgarden 2, Quarto/Switchyard 3).
 */
let restoreShellPrint = null;

function collectChildCss(doc) {
  const chunks = [];
  for (const sheet of Array.from(doc.styleSheets)) {
    try {
      chunks.push(Array.from(sheet.cssRules).map((rule) => rule.cssText).join("\n"));
    } catch {
      // Cross-origin or unreadable sheet — ignore.
    }
  }
  return chunks.join("\n");
}

function hoistResumeForShellPrint(iframe) {
  const doc = iframe.contentDocument;
  const resume = doc?.querySelector(".rz-resume");
  if (!doc || !resume) {
    return null;
  }

  const style = document.createElement("style");
  style.setAttribute("data-garden-shell-print", "true");
  style.textContent = collectChildCss(doc);

  const themeHref = doc.getElementById(THEME_LINK_ID)?.href || "";
  const themeLink = document.createElement("link");
  themeLink.rel = "stylesheet";
  themeLink.setAttribute("data-garden-shell-print", "true");
  if (themeHref) {
    themeLink.href = themeHref;
  }

  const host = document.createElement("div");
  host.id = "garden-print-host";
  host.setAttribute("data-garden-shell-print", "true");
  host.appendChild(resume.cloneNode(true));

  document.head.appendChild(style);
  if (themeHref) {
    document.head.appendChild(themeLink);
  }
  document.body.appendChild(host);
  document.documentElement.setAttribute("data-garden-shell-printing", "true");
  void host.offsetHeight;

  return () => {
    host.remove();
    style.remove();
    themeLink.remove();
    document.documentElement.removeAttribute("data-garden-shell-printing");
  };
}

function onShellBeforePrint() {
  const iframe = gardenFrame();
  if (!iframe || restoreShellPrint) {
    return;
  }
  restoreShellPrint = hoistResumeForShellPrint(iframe);
}

function onShellAfterPrint() {
  if (restoreShellPrint) {
    restoreShellPrint();
    restoreShellPrint = null;
  }
}

window.addEventListener("beforeprint", onShellBeforePrint);
window.addEventListener("afterprint", onShellAfterPrint);
window.matchMedia("print").addEventListener("change", (event) => {
  if (event.matches) {
    onShellBeforePrint();
  } else {
    onShellAfterPrint();
  }
});

function printChildDocument() {
  waitForFrame().then((iframe) => {
    iframe.contentWindow.print();
  });
}

app.ports.printGarden.subscribe(() => {
  printChildDocument();
});

app.ports.pushThemeQuery.subscribe((id) => {
  pushGarden(gardenSearch(window.location.href, { theme: id }), { theme: id });
});

app.ports.pushViewQuery.subscribe((view) => {
  pushGarden(gardenSearch(window.location.href, { view }), { view });
});

window.addEventListener("popstate", () => {
  app.ports.onGardenQuery.send(readGardenQuery(window.location.search));
});

/**
 * Renderer port: JSON in, `{ ok, html, error }` out. Elm keeps the error
 * for the console only (`logDebug`) and shows its own sentence; nothing
 * here inspects the résumé. The call goes through `window.resumezen` so
 * the probe seam and the Chrome exercise the same function.
 */
const renderedOk = (html) => ({ ok: true, html, error: "" });
const renderedErr = (failure) => ({ ok: false, html: "", error: failure.message });

app.ports.renderResume.subscribe((json) => {
  window.resumezen
    .render(json)
    .then(renderedOk, renderedErr)
    .then((message) => app.ports.onRendered.send(message));
});

async function swapInFrame(html) {
  const iframe = await waitForFrame();
  swapResume(html, iframe.contentDocument);
}

app.ports.swapResume.subscribe((html) => {
  swapInFrame(html).catch((failure) => console.warn("sandbox swap failed", failure));
});

app.ports.logDebug.subscribe((raw) => {
  console.debug("renderer error", raw);
});

/**
 * File bytes and localStorage. Wiring only: FileReader for the panel's
 * file input and drop zone; the original `article.rz-resume` is cloned
 * at sandbox first-load so Forget restores Jordan Hale with no network.
 */
let originalResume = null;
let originalTitle = "";

function captureOriginalResume() {
  return waitForFrame().then((iframe) => {
    const article = iframe.contentDocument?.querySelector("article.rz-resume");
    if (article && !originalResume) {
      originalResume = article.cloneNode(true);
      originalTitle = iframe.contentDocument.title;
    }
  });
}

function restoreOriginalResume() {
  waitForFrame().then((iframe) => {
    const live = iframe.contentDocument?.querySelector("article.rz-resume");
    if (live && originalResume) {
      live.replaceWith(originalResume.cloneNode(true));
      iframe.contentDocument.title = originalTitle;
    }
  });
}

function readFileAsText(file) {
  return new Promise((resolve) => {
    const reader = new FileReader();
    reader.onload = () => resolve({ name: file.name, text: String(reader.result ?? "") });
    reader.onerror = () => resolve({ name: file.name, text: "" });
    reader.readAsText(file);
  });
}

function sendFile(file) {
  readFileAsText(file).then((payload) => app.ports.onFileBytes.send(payload));
}

function dropZoneOf(event) {
  const target = event.target;
  return target instanceof Element ? target.closest("[data-drop-zone]") : null;
}

document.addEventListener("change", (event) => {
  const input = event.target;
  if (!(input instanceof HTMLInputElement) || input.type !== "file") {
    return;
  }
  const file = input.files?.[0];
  if (!file) {
    return;
  }
  sendFile(file);
  input.value = "";
});

document.addEventListener("dragover", (event) => {
  if (!dropZoneOf(event)) {
    return;
  }
  event.preventDefault();
  if (event.dataTransfer) {
    event.dataTransfer.dropEffect = "copy";
  }
});

document.addEventListener("drop", (event) => {
  if (!dropZoneOf(event)) {
    return;
  }
  event.preventDefault();
  const file = event.dataTransfer?.files?.[0];
  if (file) {
    sendFile(file);
  }
});

app.ports.storeResume.subscribe((json) => {
  try {
    localStorage.setItem(STORAGE_KEY, json);
  } catch {
    // quota / private mode — the résumé still shows this session
  }
});

app.ports.forgetResume.subscribe(() => {
  try {
    localStorage.removeItem(STORAGE_KEY);
  } catch {
    // ignore
  }
});

app.ports.restoreSample.subscribe(() => {
  restoreOriginalResume();
});

app.ports.copyText.subscribe((text) => {
  writeClipboard(text).then(
    () => app.ports.onCopied.send(true),
    () => app.ports.onCopied.send(false),
  );
});

app.ports.copyLink.subscribe(() => {
  writeClipboard(window.location.href).then(
    () => app.ports.onLinkCopied.send(true),
    () => app.ports.onLinkCopied.send(false),
  );
});

app.ports.focusId.subscribe((id) => {
  const focus = () => document.getElementById(id)?.focus();
  requestAnimationFrame(() => requestAnimationFrame(focus));
});

const originalReady = captureOriginalResume();

originalReady.then(() => {
  let stored = null;
  try {
    stored = localStorage.getItem(STORAGE_KEY);
  } catch {
    stored = null;
  }
  if (stored !== null) {
    app.ports.onStoredResume.send(stored);
  }
});

// Probe seam and ZG-5 hook. Thin wrappers only; the logic is in render.js.
window.resumezen = { render, contractVersion, version, swap: swapInFrame };
