/**
 * Chrome ↔ sandbox bridge.
 *
 * The only live edit inside the iframe is the Theme <link> href
 * (#theme-stylesheet). .rz-resume inner HTML is never rewritten.
 * iframe.src stays sandbox.html.
 */
(() => {
  const FRAME_ID = "garden-frame";
  const THEME_LINK_ID = "theme-stylesheet";

  const app = Elm.Main.init({
    node: document.getElementById("root"),
    flags: {
      prefersDark: window.matchMedia("(prefers-color-scheme: dark)").matches,
    },
  });

  let previewMedia = "screen";
  const originalMedia = new WeakMap();

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

    const sheet = link.sheet;
    if (sheet && sheet.cssRules) {
      return Promise.resolve();
    }

    return new Promise((resolve) => {
      const done = () => resolve();
      link.addEventListener("load", done, { once: true });
      link.addEventListener("error", done, { once: true });
    });
  }

  async function setThemeHref(href) {
    const iframe = await waitForFrame();
    const doc = iframe.contentDocument;
    if (!doc) {
      return;
    }

    let link = doc.getElementById(THEME_LINK_ID);
    if (!link) {
      link = doc.createElement("link");
      link.id = THEME_LINK_ID;
      link.rel = "stylesheet";
      doc.head.appendChild(link);
    }

    const current = link.getAttribute("href") || "";
    if (current !== href) {
      link.setAttribute("href", href);
    }

    await whenStylesheetReady(link);
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
})();
