/**
 * ZG-6 probes: name the résumé format, copy a tiny example, and start
 * from an embedded sample without writing storage or fetching skeleton/.
 */
import { createHash } from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { openGarden } from "./lib/page.mjs";
import { countPdfPages, printToPdf } from "./lib/pdf.mjs";
import { pageErrorReasons } from "./lib/paste.mjs";
import { requestsSince } from "./lib/request-log.mjs";
import { openPanel, paste, pasteSettled, waitForName } from "./zg-5.mjs";

const SCHEMA_HREF = "https://jsonresume.org/schema";
const SCHEMA_SHA256 = "8911e912ee487954b10cb59da39265c7e62ef7cba5973706d125448adc853969";
const SCHEMA_COMMIT = "b25e3f4bbafd349c2c5bbaa62602c03c228762db";
const SIDEBAR_SENTENCE =
  "Your résumé is a small text file (JSON Resume). Paste it, open it, or start from a sample.";
const COPY_FAILED = "Copy failed — select the text and copy it";
const THEME_IDS = ["nightgarden", "quarto", "switchyard"];

function reportReasons(report, label, reasons, passText) {
  if (reasons.length) {
    report.fail(`${label} ${reasons.join("; ")}`);
  } else {
    report.pass(`${label} ${passText}`);
  }
}

function readUtf8(repoDir, relative) {
  return fs.readFileSync(path.join(repoDir, relative), "utf8");
}

function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

function isThemeCss(url) {
  try {
    return new URL(url).pathname.startsWith("/themes/") && url.endsWith(".css");
  } catch {
    return /\/themes\/[^/]+\.css$/.test(url);
  }
}

async function waitSampleSettled(page, attempt) {
  await page.waitForFunction(pasteSettled, attempt);
}

async function clickSample(page, name) {
  await openPanel(page);
  const attempt = await page.locator(".paste").getAttribute("data-paste-attempt");
  await page.getByRole("button", { name }).click();
  await waitSampleSettled(page, attempt);
}

async function sandboxFacts(page) {
  return page.evaluate(() => {
    const doc = document.getElementById("garden-frame")?.contentDocument;
    const score = doc?.querySelector(".rz-score")?.textContent ?? "";
    return {
      name: doc?.querySelector(".rz-name")?.textContent ?? null,
      experience: doc?.querySelectorAll(".rz-entry--experience").length ?? 0,
      projects: doc?.querySelectorAll(".rz-entry--project").length ?? 0,
      score,
      photo: Boolean(doc?.querySelector(".rz-photo")),
      awards: Boolean(doc?.getElementById("rz-awards")),
      publications: Boolean(doc?.getElementById("rz-publications")),
      references: Boolean(doc?.getElementById("rz-references")),
      certificates: Boolean(doc?.getElementById("rz-certificates")),
      pasteError: Boolean(document.querySelector("[data-paste-error]")),
    };
  });
}

async function iframeOverflow(page) {
  return page.evaluate(() => {
    const doc = document.getElementById("garden-frame")?.contentDocument;
    if (!doc) {
      return { ok: false };
    }
    const root = doc.documentElement;
    return {
      ok: true,
      scrollWidth: root.scrollWidth,
      clientWidth: root.clientWidth,
    };
  });
}

async function loadAjv() {
  try {
    const mod = await import("ajv");
    return mod.default ?? mod;
  } catch {
    return null;
  }
}

function compileValidator(Ajv, schema) {
  return new Ajv({ allErrors: true, validateFormats: false, strict: false }).compile(schema);
}

function schemaFail(report, slug, reasons, passText) {
  reportReasons(report, `ZG-6/schema-${slug}`, reasons, passText);
}

async function schemaProbes({ report, repoDir, frontendDir }) {
  const schemaPath = path.join(repoDir, "skeleton/resume-schema.json");
  const readme = readUtf8(repoDir, "skeleton/README.md");
  const exists = fs.existsSync(schemaPath);
  const digest = exists ? sha256(fs.readFileSync(schemaPath)) : "";
  const commitHit = readme.includes(SCHEMA_COMMIT);
  reportReasons(
    report,
    "ZG-6/schema-vendored",
    [
      ...(exists ? [] : ["skeleton/resume-schema.json is missing"]),
      ...(digest === SCHEMA_SHA256 ? [] : [`sha256 is ${digest || "(missing)"}, wanted ${SCHEMA_SHA256}`]),
      ...(commitHit ? [] : [`skeleton/README.md lacks commit ${SCHEMA_COMMIT}`]),
    ],
    `schema sha256 ${SCHEMA_SHA256}; README names ${SCHEMA_COMMIT}`,
  );

  const Ajv = await loadAjv();
  const slugs = [
    { slug: "junior", file: "skeleton/samples/junior.json" },
    { slug: "jordan", file: "skeleton/resume.json" },
  ];
  if (!Ajv) {
    for (const { slug } of slugs) {
      report.fail(`ZG-6/schema-${slug} prerequisite missing: ajv devDependency (Notes)`);
    }
    report.fail("ZG-6/schema-example prerequisite missing: ajv devDependency (Notes)");
    report.fail("ZG-6/schema-rejects prerequisite missing: ajv devDependency (Notes)");
    return;
  }

  const schema = JSON.parse(fs.readFileSync(schemaPath, "utf8"));
  const validate = compileValidator(Ajv, schema);

  for (const { slug, file } of slugs) {
    const payload = JSON.parse(readUtf8(repoDir, file));
    const ok = validate(payload);
    schemaFail(
      report,
      slug,
      ok ? [] : (validate.errors || []).map((error) => `${error.instancePath} ${error.message}`),
      `${file} validates against the vendored schema`,
    );
  }

  const exampleText = exampleFromElm(frontendDir);
  const example = JSON.parse(exampleText);
  const exampleOk = validate(example);
  schemaFail(
    report,
    "example",
    exampleOk ? [] : (validate.errors || []).map((error) => `${error.instancePath} ${error.message}`),
    "pre[data-example] payload validates against the vendored schema",
  );

  const nameWrong = { basics: { name: 5 } };
  const scoreWrong = { education: [{ score: 3.7 }] };
  const nameRejected = !validate(nameWrong);
  const namePath = validate.errors?.[0]?.instancePath;
  const scoreRejected = !validate(scoreWrong);
  const scorePath = validate.errors?.[0]?.instancePath;
  schemaFail(
    report,
    "rejects",
    [
      ...(nameRejected && namePath === "/basics/name" ? [] : [`{"basics":{"name":5}} instancePath is ${JSON.stringify(namePath)}`]),
      ...(scoreRejected && scorePath === "/education/0/score"
        ? []
        : [`{"education":[{"score":3.7}]} instancePath is ${JSON.stringify(scorePath)}`]),
    ],
    "rejects a numeric name and a numeric score with the schema instancePaths",
  );
}

function exampleFromElm(frontendDir) {
  const source = fs.readFileSync(path.join(frontendDir, "src/Paste.elm"), "utf8");
  const match = source.match(/exampleJson =\n    """([\s\S]*?)"""/);
  if (!match) {
    throw new Error("Paste.elm is missing exampleJson triple-quoted string");
  }
  return match[1];
}

function staticSampleProbes({ report, repoDir }) {
  const junior = readUtf8(repoDir, "skeleton/samples/junior.json");
  const imageHits = junior.split('"image"').length - 1;
  reportReasons(
    report,
    "ZG-6/junior-no-image-key",
    imageHits === 0 ? [] : [`grep -c '"image"' is ${imageHits}, wanted 0`],
    'skeleton/samples/junior.json has zero "image" keys',
  );
}

async function formatNamedProbe({ browser, origin, report }) {
  const { page, pageErrors } = await openGarden(browser, origin);
  await openPanel(page);
  const observed = await page.evaluate((href) => {
    const panel = document.getElementById("paste-panel");
    const links = [...(panel?.querySelectorAll("a") || [])].map((node) => node.getAttribute("href"));
    return {
      body: document.body.textContent,
      hasSchemaLink: links.includes(href),
    };
  }, SCHEMA_HREF);
  await page.close();
  reportReasons(
    report,
    "ZG-6/format-named",
    [
      ...(observed.body.includes("JSON Resume") ? [] : ["open panel body.textContent lacks JSON Resume"]),
      ...(observed.hasSchemaLink ? [] : [`panel has no <a href="${SCHEMA_HREF}">`]),
      ...pageErrorReasons(pageErrors),
    ],
    `open panel names JSON Resume and links ${SCHEMA_HREF}`,
  );
}

async function sidebarSentenceProbe({ browser, origin, report }) {
  const { page, pageErrors } = await openGarden(browser, origin);
  const toggle = page.getByRole("button", { name: "Use my résumé" });
  if ((await toggle.getAttribute("aria-expanded")) === "true") {
    await toggle.click();
  }
  const sidebar = await page.locator(".app-sidebar").textContent();
  await page.close();
  reportReasons(
    report,
    "ZG-6/sidebar-sentence",
    [
      ...(sidebar.includes("small text file") ? [] : ["closed sidebar lacks small text file"]),
      ...(sidebar.includes("start from a sample") ? [] : ["closed sidebar lacks start from a sample"]),
      ...(sidebar.includes(SIDEBAR_SENTENCE) ? [] : [`closed sidebar copy is not ${JSON.stringify(SIDEBAR_SENTENCE)}`]),
      ...pageErrorReasons(pageErrors),
    ],
    "closed sidebar has the small-text-file sentence",
  );
}

async function exampleCopyProbe({ browser, origin, report }) {
  const { page, pageErrors } = await openGarden(browser, origin, {
    permissions: ["clipboard-read", "clipboard-write"],
  });
  await openPanel(page);
  const example = await page.locator("pre[data-example]").evaluate((node) => node.textContent);
  const lines = example.split("\n").length;
  let parsed;
  let parseError = "";
  try {
    parsed = JSON.parse(example);
  } catch (error) {
    parseError = error.message;
  }
  await page.getByRole("button", { name: "Copy example" }).click();
  await page.waitForSelector('[data-copy-state="copied"]');
  const copied = await page.locator('[data-copy-state="copied"]').textContent();
  const clipboard = await page.evaluate(() => navigator.clipboard.readText());
  await page.close();
  reportReasons(
    report,
    "ZG-6/example-copy",
    [
      ...(lines >= 8 && lines <= 12 ? [] : [`pre[data-example] is ${lines} lines, wanted 8–12`]),
      ...(parseError ? [`pre[data-example] is not JSON: ${parseError}`] : []),
      ...(parsed?.basics?.name === "Alex Rivera" ? [] : [`basics.name is ${JSON.stringify(parsed?.basics?.name)}`]),
      ...(parsed?.basics?.label ? [] : ["basics.label is missing"]),
      ...(parsed?.basics?.email ? [] : ["basics.email is missing"]),
      ...(parsed?.work?.length === 1 ? [] : [`work.length is ${parsed?.work?.length}`]),
      ...(clipboard === example ? [] : ["clipboard text is not byte-equal to pre[data-example]"]),
      ...(copied === "Copied" ? [] : [`[data-copy-state=copied] text is ${JSON.stringify(copied)}`]),
      ...pageErrorReasons(pageErrors),
    ],
    "Copy example writes the 8–12 line Alex Rivera snippet and shows Copied",
  );
}

async function exampleCopyFailedProbe({ browser, origin, report }) {
  const { page, pageErrors } = await openGarden(browser, origin, {
    beforeNavigate: (gardenPage) =>
      gardenPage.addInitScript(() => {
        Object.defineProperty(navigator, "clipboard", {
          configurable: true,
          value: {
            writeText: () => Promise.reject(new DOMException("Permission denied", "NotAllowedError")),
          },
        });
      }),
  });
  await openPanel(page);
  await page.getByRole("button", { name: "Copy example" }).click();
  await page.waitForSelector('[data-copy-state="failed"]');
  const failed = await page.locator('[data-copy-state="failed"]').textContent();
  const sawCopied = [];
  const started = Date.now();
  while (Date.now() - started < 500) {
    const state = await page.evaluate(() => {
      const copied = document.querySelector('[data-copy-state="copied"]');
      return copied ? copied.textContent : null;
    });
    if (state) {
      sawCopied.push(state);
      break;
    }
    await page.waitForTimeout(50);
  }
  await page.close();
  reportReasons(
    report,
    "ZG-6/example-copy-failed",
    [
      ...(failed.includes("Copy failed") ? [] : [`failed text is ${JSON.stringify(failed)}`]),
      ...(failed === COPY_FAILED ? [] : [`failed text is ${JSON.stringify(failed)}, wanted ${JSON.stringify(COPY_FAILED)}`]),
      ...(sawCopied.length ? [`Copied appeared: ${JSON.stringify(sawCopied[0])}`] : []),
      ...pageErrorReasons(pageErrors),
    ],
    "rejected writeText shows Copy failed and never Copied",
  );
}

async function exampleRendersProbe({ browser, origin, report }) {
  const { page, pageErrors } = await openGarden(browser, origin);
  await openPanel(page);
  const example = await page.locator("pre[data-example]").evaluate((node) => node.textContent);
  await paste(page, example);
  await waitForName(page, "Alex Rivera");
  const facts = await sandboxFacts(page);
  await page.close();
  reportReasons(
    report,
    "ZG-6/example-renders",
    [
      ...(facts.name === "Alex Rivera" ? [] : [`.rz-name is ${JSON.stringify(facts.name)}`]),
      ...(facts.experience === 1 ? [] : [`.rz-entry--experience count is ${facts.experience}`]),
      ...(facts.pasteError ? ["[data-paste-error] is showing"] : []),
      ...pageErrorReasons(pageErrors),
    ],
    "Show it on the example draws Alex Rivera with one experience entry",
  );
}

async function startSampleProbe({ browser, origin, report, repoDir, frontendDir }) {
  const jordan = readUtf8(repoDir, "skeleton/resume.json");
  const ada = readUtf8(frontendDir, "fixtures/ada.json");
  const { page, pageErrors, requests } = await openGarden(browser, origin);
  await paste(page, ada);
  await waitForName(page, "Ada Lovelace");
  const mark = requests.length;
  await clickSample(page, "Start from Jordan's sample");
  await waitForName(page, "Jordan Hale");
  const value = await page.locator("#paste-input").inputValue();
  const name = await page.evaluate(() => {
    return document.getElementById("garden-frame")?.contentDocument?.querySelector(".rz-name")?.textContent ?? null;
  });
  const extra = requestsSince(requests, mark).filter((url) => !isThemeCss(url));
  await page.close();
  reportReasons(
    report,
    "ZG-6/start-sample",
    [
      ...(value === jordan ? [] : ["#paste-input.value is not byte-equal to skeleton/resume.json"]),
      ...(name === "Jordan Hale" ? [] : [`.rz-name is ${JSON.stringify(name)}`]),
      ...(extra.length ? [`click issued HTTP besides themes/*.css: ${extra.join(", ")}`] : []),
      ...pageErrorReasons(pageErrors),
    ],
    "Jordan's sample fills the box with skeleton/resume.json and draws Jordan Hale with no fetch",
  );
}

async function startJuniorProbe({ browser, origin, report, repoDir }) {
  const juniorText = readUtf8(repoDir, "skeleton/samples/junior.json");
  const junior = JSON.parse(juniorText);
  const wantScore = `GPA ${junior.education[0].score}`;
  const { page, pageErrors } = await openGarden(browser, origin);
  await clickSample(page, "Start from a short sample");
  await waitForName(page, "Sam Okoro");
  const value = await page.locator("#paste-input").inputValue();
  const facts = await sandboxFacts(page);
  await page.close();
  reportReasons(
    report,
    "ZG-6/start-junior",
    [
      ...(value === juniorText ? [] : ["#paste-input.value is not byte-equal to skeleton/samples/junior.json"]),
      ...(facts.name === "Sam Okoro" ? [] : [`.rz-name is ${JSON.stringify(facts.name)}`]),
      ...(facts.experience === 1 ? [] : [`.rz-entry--experience count is ${facts.experience}`]),
      ...(facts.projects === 3 ? [] : [`.rz-entry--project count is ${facts.projects}`]),
      ...(facts.score === wantScore ? [] : [`.rz-score is ${JSON.stringify(facts.score)}, wanted ${JSON.stringify(wantScore)}`]),
      ...(facts.photo ? ["sandbox has .rz-photo"] : []),
      ...(facts.awards ? ["sandbox has #rz-awards"] : []),
      ...(facts.publications ? ["sandbox has #rz-publications"] : []),
      ...(facts.references ? ["sandbox has #rz-references"] : []),
      ...(facts.certificates ? ["sandbox has #rz-certificates"] : []),
      ...pageErrorReasons(pageErrors),
    ],
    `short sample draws Sam Okoro, one job, three projects, ${wantScore}, no photo or extras`,
  );
}

async function sampleNotStoredProbe({ browser, origin, report, frontendDir }) {
  const ada = readUtf8(frontendDir, "fixtures/ada.json");
  const { page, pageErrors } = await openGarden(browser, origin);
  await paste(page, ada);
  await waitForName(page, "Ada Lovelace");
  await clickSample(page, "Start from a short sample");
  await waitForName(page, "Sam Okoro");
  const storedAfterSample = await page.evaluate(() => localStorage.getItem("resumezen.resume"));
  await page.reload({ waitUntil: "networkidle" });
  await page.frameLocator("#garden-frame").locator(".rz-resume").waitFor();
  await waitForName(page, "Ada Lovelace");
  const afterReload = await page.evaluate(() => {
    const doc = document.getElementById("garden-frame")?.contentDocument;
    return {
      name: doc?.querySelector(".rz-name")?.textContent ?? null,
      stored: localStorage.getItem("resumezen.resume"),
    };
  });
  await page.close();

  const cleared = await openGarden(browser, origin);
  await clickSample(cleared.page, "Start from Jordan's sample");
  await waitForName(cleared.page, "Jordan Hale");
  await cleared.page.reload({ waitUntil: "networkidle" });
  await cleared.page.frameLocator("#garden-frame").locator(".rz-resume").waitFor();
  await waitForName(cleared.page, "Jordan Hale");
  const afterClear = await cleared.page.evaluate(() => {
    const doc = document.getElementById("garden-frame")?.contentDocument;
    return {
      name: doc?.querySelector(".rz-name")?.textContent ?? null,
      stored: localStorage.getItem("resumezen.resume"),
    };
  });
  await clickSample(cleared.page, "Start from Jordan's sample");
  await waitForName(cleared.page, "Jordan Hale");
  const edited = (await cleared.page.locator("#paste-input").inputValue()).replace("Jordan Hale", "Elena Okoro");
  await paste(cleared.page, edited);
  await waitForName(cleared.page, "Elena Okoro");
  await cleared.page.reload({ waitUntil: "networkidle" });
  await cleared.page.frameLocator("#garden-frame").locator(".rz-resume").waitFor();
  await waitForName(cleared.page, "Elena Okoro");
  const afterEdit = await cleared.page.evaluate(() => {
    const doc = document.getElementById("garden-frame")?.contentDocument;
    return {
      name: doc?.querySelector(".rz-name")?.textContent ?? null,
      stored: localStorage.getItem("resumezen.resume"),
    };
  });
  await cleared.page.close();

  reportReasons(
    report,
    "ZG-6/sample-not-stored",
    [
      ...(storedAfterSample === ada ? [] : ["after short-sample click storage is not the Ada bytes"]),
      ...(afterReload.name === "Ada Lovelace" ? [] : [`reload after sample shows ${JSON.stringify(afterReload.name)}`]),
      ...(afterClear.name === "Jordan Hale" ? [] : [`cleared reload shows ${JSON.stringify(afterClear.name)}`]),
      ...(afterClear.stored === null ? [] : [`cleared reload stored ${JSON.stringify(afterClear.stored)}`]),
      ...(afterEdit.name === "Elena Okoro" ? [] : [`edited Show it reload shows ${JSON.stringify(afterEdit.name)}`]),
      ...(afterEdit.stored && afterEdit.stored.includes("Elena Okoro") ? [] : ["edited Show it did not store the edited name"]),
      ...pageErrorReasons(pageErrors),
      ...pageErrorReasons(cleared.pageErrors),
    ],
    "sample click does not Store; Show it after an edit does",
  );
}

async function juniorAllThemesProbe({ browser, origin, report }) {
  const { page, pageErrors } = await openGarden(browser, origin);
  await page.setViewportSize({ width: 1280, height: 800 });
  await clickSample(page, "Start from a short sample");
  await waitForName(page, "Sam Okoro");

  const overflowReasons = [];
  const printReasons = [];
  for (const id of THEME_IDS) {
    await page.locator(`#theme-option-${id}`).click();
    await page.waitForFunction((want) => {
      const href = document
        .getElementById("garden-frame")
        ?.contentDocument?.getElementById("theme-stylesheet")
        ?.getAttribute("href");
      return href && href.includes(`${want}.css`);
    }, id);
    await page.waitForTimeout(150);
    const box = await iframeOverflow(page);
    if (!box.ok) {
      overflowReasons.push(`${id}: missing iframe document`);
    } else if (box.scrollWidth > box.clientWidth) {
      overflowReasons.push(`${id}: scrollWidth ${box.scrollWidth} > clientWidth ${box.clientWidth}`);
    }

    await page.evaluate(() => {
      const iframe = document.getElementById("garden-frame");
      const win = iframe.contentWindow;
      win.__originalPrint = win.print.bind(win);
      win.__printCalled = false;
      win.print = function stubPrint() {
        win.__printCalled = true;
      };
    });
    await page.locator(".preview-controls__print").click();
    await page.waitForFunction(() => Boolean(document.getElementById("garden-frame")?.contentWindow?.__printCalled));
    await page.evaluate(() => {
      const win = document.getElementById("garden-frame")?.contentWindow;
      if (win && win.__originalPrint) {
        win.print = win.__originalPrint;
        win.__printCalled = false;
      }
    });
    await page.evaluate(() => {
      window.dispatchEvent(new Event("beforeprint"));
    });
    const hoisted = await page.evaluate(() => Boolean(document.getElementById("garden-print-host")));
    const pdf = await printToPdf(page);
    await page.evaluate(() => {
      window.dispatchEvent(new Event("afterprint"));
    });
    const pages = countPdfPages(pdf);
    if (!hoisted) {
      printReasons.push(`${id}: beforeprint did not hoist #garden-print-host`);
    }
    if (pages > 2) {
      printReasons.push(`${id}: shell-print is ${pages} pages, wanted ≤ 2`);
    }
  }
  await page.close();
  reportReasons(
    report,
    "ZG-6/junior-all-themes",
    [...overflowReasons, ...printReasons, ...pageErrorReasons(pageErrors)],
    "junior sample has no horizontal overflow on Nightgarden, Quarto, Switchyard and shell-print is ≤ 2 pages",
  );
}

export async function zg6Probes(context) {
  await schemaProbes(context);
  staticSampleProbes(context);
  await formatNamedProbe(context);
  await sidebarSentenceProbe(context);
  await exampleCopyProbe(context);
  await exampleCopyFailedProbe(context);
  await exampleRendersProbe(context);
  await startSampleProbe(context);
  await startJuniorProbe(context);
  await sampleNotStoredProbe(context);
  await juniorAllThemesProbe(context);
}
