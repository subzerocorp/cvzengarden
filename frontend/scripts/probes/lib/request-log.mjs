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
