/**
 * Chrome ↔ sandbox bridge. Isolated actions only.
 *
 * Theme id math lives in Elm (`ThemeId`). This file pushes history and
 * swaps Theme sheets. The live edit inside the iframe is the Theme
 * <link> set: keep the outgoing sheet until the incoming sheet is ready
 * so a committed frame never paints UA-default serif on a blank canvas.
 * .rz-resume inner HTML is never rewritten. iframe.src stays sandbox.html.
 */
(() => {
  const FRAME_ID = "garden-frame";
  const THEME_LINK_ID = "theme-stylesheet";

  const app = Elm.Main.init({
    node: document.getElementById("root"),
    flags: {
      prefersDark: window.matchMedia("(prefers-color-scheme: dark)").matches,
      themeQuery: new URLSearchParams(window.location.search).get("theme") || "",
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

  function themeUrl(id) {
    const url = new URL(window.location.href);
    url.searchParams.set("theme", id);
    return url.pathname + url.search + url.hash;
  }

  app.ports.setThemeHref.subscribe((href) => {
    setThemeHref(href);
  });

  app.ports.setPreviewMedia.subscribe((media) => {
    setPreviewMedia(media);
  });

  app.ports.printGarden.subscribe(() => {
    waitForFrame().then((iframe) => {
      iframe.contentWindow.print();
    });
  });

  app.ports.pushThemeQuery.subscribe((id) => {
    const next = themeUrl(id);
    const current = window.location.pathname + window.location.search + window.location.hash;
    if (next !== current) {
      window.history.pushState({ theme: id }, "", next);
    }
  });

  window.addEventListener("popstate", () => {
    const raw = new URLSearchParams(window.location.search).get("theme") || "";
    app.ports.onThemeQuery.send(raw);
  });
})();
