/**
 * ZG-23 static lock: the sandbox's #theme-stylesheet must be a plain
 * render-blocking <link> in <head>. A sheet moved into <body>, or given
 * media="print"/disabled/onload tricks, stops blocking first paint, which
 * is exactly the stub the paint-order oracle exists to catch.
 *
 * Pure: HTML string in, list of reasons out (empty means the lock holds).
 */

const THEME_LINK = /<link\b[^>]*\bid="theme-stylesheet"[^>]*>/g;
const NON_BLOCKING_ATTRIBUTE = /\s(?:media|disabled|onload)(?=[\s=>\/])/i;

export function sheetBlockingReasons(html) {
  const links = [...html.matchAll(THEME_LINK)];
  if (links.length !== 1) {
    return [`expected exactly one #theme-stylesheet link, found ${links.length}`];
  }
  const [link] = links;
  const bodyAt = html.search(/<body\b/);
  return [
    ...(bodyAt !== -1 && link.index < bodyAt ? [] : ["#theme-stylesheet link is not before <body>"]),
    ...(/\brel="stylesheet"/.test(link[0]) ? [] : ['#theme-stylesheet link lacks rel="stylesheet"']),
    ...(NON_BLOCKING_ATTRIBUTE.test(link[0]) ? ["#theme-stylesheet link carries media/disabled/onload"] : []),
  ];
}
