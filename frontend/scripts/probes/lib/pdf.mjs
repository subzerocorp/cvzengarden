/**
 * Real print output: Chromium's printToPDF plus a page counter over the
 * PDF bytes. `printToPdf` is an action; `countPdfPages` is a calculation.
 */

export async function printToPdf(page) {
  const client = await page.context().newCDPSession(page);
  const result = await client.send("Page.printToPDF", {
    printBackground: true,
    preferCSSPageSize: true,
    scale: 1,
  });
  await client.detach();
  return Buffer.from(result.data, "base64");
}

export function countPdfPages(buffer) {
  const text = buffer.toString("latin1");
  const matches = text.match(/\/Type\s*\/Page(?!s)\b/g);
  return matches ? matches.length : 0;
}
