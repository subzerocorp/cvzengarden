/**
 * Renderer concern: the pure Rust crate compiled to Wasm, run in the browser.
 *
 * Nothing leaves the page — the module is a static asset next to this file.
 * `render` is a thin async wrapper: it never grows logic, it only translates
 * the crate's two outcomes (HTML string, or its plain-words error) and the
 * one browser-side failure (the module could not load) into a Promise the
 * Elm port and the Chrome can show unchanged.
 *
 * `swapResume` is the sandbox action: replace `article.rz-resume` with the
 * one the crate rendered and update the document title. The Theme <link>
 * and the iframe src are not touched.
 */

const MODULE_PATH = "./wasm/resumezen_renderer_wasm.js";
const ARTICLE = "article.rz-resume";

// Plain words for the Chrome, with no cause and no stack — the cause goes to the console.
export const LOAD_FAILURE_MESSAGE = "The renderer could not be loaded in this browser. Reload the page to try again.";

// Calculation: the message of a thrown value. wasm-bindgen throws the crate's
// `Err(String)` as a bare string; anything else is an Error.
export function plainMessage(thrown) {
  if (typeof thrown === "string") {
    return thrown;
  }
  return thrown instanceof Error ? thrown.message : String(thrown);
}

// Calculation: title and article of a rendered Skeleton document.
export function renderedParts(rendered) {
  const article = rendered.querySelector(ARTICLE);
  if (!article) {
    throw new Error("rendered HTML has no article.rz-resume");
  }
  return { title: rendered.title, article };
}

let modulePromise = null;

async function initModule() {
  const wasm = await import(MODULE_PATH);
  await wasm.default();
  return wasm;
}

// Loads once; a failed load is forgotten so a later call can retry.
function loadModule() {
  modulePromise ??= initModule().catch((cause) => {
    modulePromise = null;
    console.warn("renderer module failed to load", cause);
    throw new Error(LOAD_FAILURE_MESSAGE);
  });
  return modulePromise;
}

export async function render(json) {
  const wasm = await loadModule();
  try {
    return wasm.render_json(json);
  } catch (thrown) {
    throw new Error(plainMessage(thrown));
  }
}

export async function contractVersion() {
  return (await loadModule()).contract_version();
}

export async function version() {
  return (await loadModule()).version();
}

export function swapResume(html, doc) {
  const parts = renderedParts(new DOMParser().parseFromString(html, "text/html"));
  doc.querySelector(ARTICLE).replaceWith(doc.adoptNode(parts.article));
  doc.title = parts.title;
}
