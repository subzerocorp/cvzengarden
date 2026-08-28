/**
 * Pure garden search-param math. ports.js applies the result with
 * pushState; Elm never builds the URL.
 */

export function gardenSearch(href, patch) {
  const url = new URL(href, "https://garden.invalid");
  if (Object.hasOwn(patch, "theme")) {
    url.searchParams.set("theme", patch.theme);
  }
  if (Object.hasOwn(patch, "view")) {
    url.searchParams.set("view", patch.view);
  }
  return url.pathname + url.search + url.hash;
}

export function readGardenQuery(search) {
  const params = new URLSearchParams(search.startsWith("?") ? search.slice(1) : search);
  return {
    theme: params.get("theme") || "",
    view: params.get("view") || "",
  };
}

export function isPrintView(raw) {
  return String(raw).trim().toLowerCase() === "print";
}
