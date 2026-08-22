/**
 * RZ-3 acceptance probes. A stub page, a reload-to-swap, or an iframe-src
 * swap fails these on purpose.
 */
import { spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const frontendDir = path.resolve(__dirname, "..");
const repoDir = path.resolve(frontendDir, "..");
const distDir = path.join(frontendDir, "dist");
const port = Number(process.env.PROBE_PORT || 4173);
const origin = `http://127.0.0.1:${port}`;

const failures = [];

function fail(message) {
  failures.push(message);
  console.error(`FAIL  ${message}`);
}

function pass(message) {
  console.log(`PASS  ${message}`);
}

function chromeSourceFiles() {
  const roots = [
    path.join(frontendDir, "src"),
    path.join(frontendDir, "css"),
    path.join(frontendDir, "static"),
  ];
  const files = [];
  for (const root of roots) {
    const stack = [root];
    while (stack.length) {
      const current = stack.pop();
      for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
        const full = path.join(current, entry.name);
        if (entry.isDirectory()) {
          stack.push(full);
        } else {
          files.push(full);
        }
      }
    }
  }
  return files;
}

function staticProbes() {
  const chromeFiles = chromeSourceFiles();
  const bannedClassOrId = /(?:\bclass|\bid|classList)\s*[=\[]?\s*["']rz-|["']rz-[a-z]/i;
  const cssRz = /(?:^|[^\w-])(?:\.#?|[#.])rz-[a-z]/m;

  for (const file of chromeFiles) {
    const source = fs.readFileSync(file, "utf8");
    const rel = path.relative(frontendDir, file);

    if (/(?:@import|href\s*=|url\()\s*["'][^"']*preview\.css/.test(source)) {
      fail(`Chrome file ${rel} links skeleton/preview.css`);
    }

    if (rel.endsWith(".css") && cssRz.test(source)) {
      fail(`Chrome CSS ${rel} uses an rz- selector`);
    }

    if ((rel.endsWith(".elm") || rel.endsWith(".html") || rel.endsWith(".css")) && bannedClassOrId.test(source)) {
      fail(`Chrome markup ${rel} has a class or id prefixed rz-`);
    }
  }

  const themesElm = fs.readFileSync(path.join(frontendDir, "src", "Generated", "Themes.elm"), "utf8");
  if (/\bid\s*=\s*"_blank"/.test(themesElm) || /preview\.css/.test(themesElm)) {
    fail("Generated theme list includes _blank or preview.css");
  } else {
    pass("Generated theme list excludes _blank and preview.css");
  }

  const themeFiles = fs
    .readdirSync(path.join(repoDir, "themes"))
    .filter((name) => name.endsWith(".css") && name !== "_blank.css")
    .map((name) => name.replace(/\.css$/, ""));

  for (const id of themeFiles) {
    if (!themesElm.includes(`id = "${id}"`)) {
      fail(`Generated Themes.elm is missing ${id}`);
    }
  }
  pass(`Generated Themes.elm lists ${themeFiles.join(", ")}`);

  const sandbox = fs.readFileSync(path.join(distDir, "sandbox.html"), "utf8");
  if (!sandbox.includes('class="rz-resume"') || !sandbox.includes('data-rz-schema="1.0"')) {
    fail("Sandbox document is missing .rz-resume / data-rz-schema");
  } else {
    pass("Sandbox document contains .rz-resume and data-rz-schema=\"1.0\"");
  }
  if (/preview\.css/.test(sandbox)) {
    fail("Sandbox links or mentions preview.css");
  } else {
    pass("Sandbox does not link preview.css");
  }
  if (!sandbox.includes('id="theme-stylesheet"')) {
    fail("Sandbox is missing #theme-stylesheet");
  }
}

function startServer() {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, [path.join(__dirname, "serve.mjs")], {
      cwd: frontendDir,
      env: { ...process.env, PORT: String(port) },
      stdio: ["ignore", "pipe", "pipe"],
    });
    const onData = (buf) => {
      const text = buf.toString();
      if (text.includes("Garden chrome")) {
        child.stdout.off("data", onData);
        resolve(child);
      }
    };
    child.stdout.on("data", onData);
    child.stderr.on("data", (buf) => process.stderr.write(buf));
    child.on("error", reject);
    setTimeout(() => reject(new Error("Server did not start")), 8000);
  });
}

async function browserProbes() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto(origin + "/", { waitUntil: "networkidle" });
  await page.waitForSelector(".theme-switcher");
  await page.waitForSelector("#garden-frame");

  const frame = page.frameLocator("#garden-frame");
  await frame.locator(".rz-resume").waitFor();

  const switcherVisible = await page.locator(".theme-switcher").evaluate((el) => {
    const style = getComputedStyle(el);
    return style.display !== "none" && style.visibility !== "hidden";
  });
  if (!switcherVisible) {
    fail("Chrome .theme-switcher is not visible");
  } else {
    pass("Chrome renders a visible .theme-switcher");
  }

  const sandboxMeta = await page.evaluate(() => {
    const iframe = document.getElementById("garden-frame");
    const doc = iframe.contentDocument;
    const resume = doc.querySelector(".rz-resume");
    return {
      schema: resume?.getAttribute("data-rz-schema"),
      name: doc.querySelector(".rz-name")?.textContent.trim(),
      html: resume?.innerHTML,
      href: doc.getElementById("theme-stylesheet")?.getAttribute("href"),
      src: iframe.getAttribute("src"),
      pathname: location.pathname,
    };
  });

  if (sandboxMeta.schema !== "1.0") {
    fail(`Sandbox data-rz-schema is ${sandboxMeta.schema}`);
  } else {
    pass("Live sandbox has data-rz-schema=\"1.0\"");
  }
  if (sandboxMeta.name !== "Jordan Hale") {
    fail(`Expected Jordan Hale in .rz-name, got ${sandboxMeta.name}`);
  } else {
    pass("Jordan Hale is in .rz-name");
  }
  if (!sandboxMeta.href || !sandboxMeta.href.includes("themes/") || sandboxMeta.href.includes("preview.css")) {
    fail(`Initial theme href is wrong: ${sandboxMeta.href}`);
  }

  const themeButtons = page.locator(".theme-switcher__item label");
  const count = await themeButtons.count();
  if (count < 3) {
    fail(`Theme switcher lists ${count} themes; expected at least 3`);
  } else {
    pass(`Theme switcher lists ${count} themes`);
  }

  await page.locator('label[for="theme-option-quarto"]').click();
  await page.waitForFunction(() => {
    const href = document
      .getElementById("garden-frame")
      ?.contentDocument?.getElementById("theme-stylesheet")
      ?.getAttribute("href");
    return href && href.includes("quarto.css");
  });

  const afterQuarto = await page.evaluate(() => {
    const iframe = document.getElementById("garden-frame");
    const doc = iframe.contentDocument;
    return {
      href: doc.getElementById("theme-stylesheet")?.getAttribute("href"),
      html: doc.querySelector(".rz-resume")?.innerHTML,
      name: doc.querySelector(".rz-name")?.textContent.trim(),
      src: iframe.getAttribute("src"),
      pathname: location.pathname,
    };
  });

  if (afterQuarto.href === sandboxMeta.href) {
    fail("Theme href did not change after switching to Quarto");
  } else if (!afterQuarto.href.includes("quarto.css")) {
    fail(`Theme href after Quarto is ${afterQuarto.href}`);
  } else {
    pass(`Theme <link> href swapped to ${afterQuarto.href}`);
  }

  if (afterQuarto.html !== sandboxMeta.html) {
    fail(".rz-resume inner HTML changed during theme swap");
  } else {
    pass(".rz-resume inner HTML is unchanged after swap");
  }
  if (afterQuarto.name !== "Jordan Hale") {
    fail("Jordan Hale missing after swap");
  } else {
    pass("Jordan Hale is still in .rz-name after swap");
  }
  if (afterQuarto.pathname !== sandboxMeta.pathname) {
    fail("location.pathname changed during swap");
  } else {
    pass("Chrome location.pathname is unchanged");
  }
  if (afterQuarto.src !== sandboxMeta.src) {
    fail(`iframe src changed from ${sandboxMeta.src} to ${afterQuarto.src}`);
  } else {
    pass("iframe src is unchanged");
  }

  await page.locator('label[for="theme-option-nightgarden"]').click();
  await page.waitForFunction(() => {
    const href = document
      .getElementById("garden-frame")
      ?.contentDocument?.getElementById("theme-stylesheet")
      ?.getAttribute("href");
    return href && href.includes("nightgarden.css");
  });

  const motion = await page.evaluate(() => {
    const name = document
      .getElementById("garden-frame")
      .contentDocument.querySelector(".rz-name");
    return getComputedStyle(name).animationName;
  });
  if (!motion || motion === "none") {
    fail(`Nightgarden screen motion is missing (animation-name: ${motion})`);
  } else {
    pass(`Nightgarden screen motion is running (${motion})`);
  }

  await page.getByRole("button", { name: "Print preview" }).click();
  await page.waitForTimeout(400);

  const printMotion = await page.evaluate(() => {
    const name = document
      .getElementById("garden-frame")
      .contentDocument.querySelector(".rz-name");
    return getComputedStyle(name).animationName;
  });
  if (printMotion && printMotion !== "none") {
    fail(`Print preview still runs Nightgarden motion (${printMotion})`);
  } else {
    pass("Print preview does not keep Nightgarden screen motion running");
  }

  await page.getByRole("button", { name: "Screen" }).click();
  await page.waitForTimeout(200);

  const leak = await page.evaluate(() => {
    const iframe = document.getElementById("garden-frame");
    const style = iframe.contentDocument.createElement("style");
    style.textContent = ".theme-switcher{display:none}";
    iframe.contentDocument.head.appendChild(style);
    return getComputedStyle(document.querySelector(".theme-switcher")).display;
  });
  if (leak === "none") {
    fail("Theme CSS leaked: Chrome .theme-switcher computed display is none");
  } else {
    pass(`Theme .theme-switcher{display:none} left Chrome display as ${leak}`);
  }

  const chromePreview = await page.evaluate(() => {
    return [...document.styleSheets].some((sheet) => {
      const href = sheet.href || "";
      return href.includes("preview.css");
    });
  });
  if (chromePreview) {
    fail("Chrome linked skeleton/preview.css");
  } else {
    pass("Chrome does not link skeleton/preview.css");
  }

  await browser.close();
}

staticProbes();

const server = await startServer();
try {
  await browserProbes();
} finally {
  server.kill("SIGTERM");
}

if (failures.length) {
  console.error(`\n${failures.length} probe(s) failed.`);
  process.exit(1);
}

console.log("\nAll RZ-3 probes passed.");
