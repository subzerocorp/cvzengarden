/**
 * Calculations over a Playwright request log (URLs in order) for the
 * "nothing leaves the browser" checks.
 */

// URLs not served by `origin`, or any `/api` path on it.
export function foreignRequests(urls, origin) {
  return urls.filter((url) => !url.startsWith(`${origin}/`) || new URL(url).pathname.startsWith("/api"));
}

// Requests made after the first `before` entries.
export function requestsSince(urls, before) {
  return urls.slice(before);
}

// Page assets plus `themes/*.css`. Anything else (skeleton JSON, /api,
// third-party) is a leak.
export function isGardenAsset(url, origin) {
  if (!url.startsWith(`${origin}/`)) {
    return false;
  }
  const { pathname } = new URL(url);
  if (pathname === "/" || pathname === "/index.html") {
    return true;
  }
  if (pathname === "/chrome.css" || pathname === "/garden.js" || pathname === "/ports.js" || pathname === "/clipboard.js" || pathname === "/garden-query.js" || pathname === "/render.js" || pathname === "/sandbox.html") {
    return true;
  }
  if (pathname.startsWith("/wasm/")) {
    return true;
  }
  if (pathname.startsWith("/themes/fonts/") && pathname.endsWith(".woff2")) {
    return true;
  }
  return pathname.startsWith("/themes/") && pathname.endsWith(".css");
}

export function offGardenRequests(urls, origin) {
  return urls.filter((url) => !isGardenAsset(url, origin));
}
