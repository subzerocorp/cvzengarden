# ZG-16 Reviewer — cycle 1 (commit `5529b3f`)

## Verdict

**REVIEWER REJECT ZG-16**

`safeThemeUrl` — the part attacked hardest — held. 18 hostile inputs (`javascript:`,
`JAVASCRIPT:`, `java\tscript:`, `vbscript:`, `data:`, `//host`, `/relative`,
unparseable) all returned `""`; the URL parser strips tabs/newlines before the
protocol check, so the classic split fails closed, and `elmEscape` closes the
generated-source injection path behind it. Five blockers elsewhere.

## Must-fix (blockers)

1. **`themes/README.md`'s worked example teaches a form the parser does not read.**
   `parseTheme` matches `rz-target` only as its own `/* … */` comment (hence line 1
   of every shipped theme); the new example puts it inside the `/** … */` block.
   Measured: the example declaring `print` parses as `Both`. A designer who copies
   it silently gets the wrong filter and badge. (`themes/_blank.css:8` has the same
   in-block form — pre-existing, `43517f9`, not introduced here, but the new README
   now teaches it as canonical.)
2. **`generate.test.mjs` "importing does not run the generator" cannot fail.** Its
   only assertion is `typeof parseTheme === "function"`, which the `import` already
   guarantees. Delete the `main()` guard and it still passes while the test run
   rewrites `src/Generated/*.elm`. `build-wasm.test.mjs:27` shows the house pattern:
   spawn a child and assert observable behaviour.
3. **`probes/zg-16.mjs` ships no sibling `zg-16.test.mjs`.** Its own header sells the
   action/calculation split ("`bylineReasons` is unit-testable without a browser").
   Every other probe module with an exported `*Reasons` has a sibling test; zg-16 is
   the sole exception. Cover the five branches or drop the export and the comment.
4. **`viewByline`'s author-without-URL branch has zero coverage.** All three
   first-party themes carry a URL and the lab theme carries neither, so the
   plain-text byline — advertised in the README as supported — is exercised by
   nothing, in a PBI whose entire subject is bylines.
5. **Invalid nested interactive content (`<a href>` inside `<button>`) shipped to
   satisfy a literal AC instead of escalating the AC conflict.** `button`'s content
   model forbids interactive descendants; it survives only because Elm builds the DOM
   through DOM APIs, and any path that round-trips the markup through the HTML parser
   hoists the `<a>` out. `role=button` is children-presentational, so the byline is a
   tab stop assistive tech never exposes as a link, and the button's accessible name
   became "Nightgarden by ResumeZen Screen". `readCards` queries the DOM rather than
   the accessibility tree, which is why no probe saw it.

## Should-fix (non-blocking)

`pathToFileURL(process.argv[1])` throws when `argv[1]` is undefined, and ESM realpath
resolution makes the guard false under a symlinked invocation — turning `npm run gen`
into a silent no-op; duplicate `.theme-switcher__option` / `__name` blocks in
`chrome.css` instead of extending the existing ones; the three `order:` rules exist
only because the byline was inserted between name and badge; a schemeless `URL:`
(the likeliest designer typo) is dropped silently with no warning; `rel` could carry
`nofollow ugc`; the probe writes into tracked `themes/` where `zg-5.mjs:351` uses
`mkdtempSync`; `safeThemeUrl` could return `parsed.href` rather than raw input; the
decorative `Target:` line the generator ignores is undocumented.

## Explicitly not a finding

The S4 edit (`focus(nightgarden)+Tab` → `focus(quarto)`) is **not** a weakened test:
the pass message's claim is unchanged and per-option Tab reachability is still
asserted by the 24-Tab walk at `probes.mjs:963-1013`. Two Tabs would be strictly
better coverage. DoD lines on `progress.md`, PBI id in the commit, no `rz-` prefix in
chrome, and themes touched in header comments only are all satisfied.

## Disposition

AC1's "each `#theme-option-*` … contains" is what forced blocker 5. Human ruled:
amend AC1 to the card, restructure so the byline is a sibling of the option button.
Fix all five, then restart the full three-adversary chain — prior findings do not
carry across material change.

---

# ZG-16 Reviewer — cycle 2 (commit `8af53d2`)

## Verdict

**REVIEWER REJECT ZG-16**

All five cycle-1 blockers verified closed by measurement, not by reading the commit
message: the aria snapshot now renders `button "Nightgarden Screen" [pressed]` and a
separate `link "ResumeZen"`, and the card's `outerHTML` survives a `DOMParser`
round-trip byte-identical, so the parser no longer hoists the anchor out. The import
guard was mutation-tested in both directions. `safeThemeUrl` was re-attacked with 38
hostile inputs, all rejected. The restructure is the right one. Two new blockers.

## Must-fix (blockers)

1. **The theme card's click target shrank to 30% of the card while the whole card still
   paints hover.** Padding, border and background moved to `.theme-switcher__item`
   (`chrome.css:213`) and the button was left at `padding: 0` (`:231`), with hover on
   the `li` (`:226`). Measured at 1280×800: card 259.8×55.2, button 237×**18.2**;
   `elementFromPoint` at the card's inner corner returns the `li`, and a click there
   does not change the theme, yet that region lightens on hover exactly like the live
   control. Pre-ZG-16 the button *was* the card (`width:100%` plus the padding), so
   every pixel selected. Unmentioned in the doc comments, the commit message and
   `progress.md`, and unasserted by any probe — an unnoticed side effect, not a
   decision, in the product's primary control (BAR-Q1 priority 1 is ease of use).
   Fixable without disturbing AC1's siblinghood: return the padding to the button and
   give `.theme-switcher__author` matching padding, or keep the card frame and drive
   the highlight from `.theme-switcher__item:has(.theme-switcher__option:hover)`.
   Pin the hit box with a probe either way.
2. **AC2's stated value no longer matches the code, and the AC was not amended.**
   `safeThemeUrl` returns `parsed.href`, so `https://mika.example` yields the slashed
   form. The change is good and cycle 1 asked for it, but a reviewer's should-fix does
   not amend an acceptance criterion — the mirror image of cycle 1's blocker 5.

## Should-fix (non-blocking)

Byline link's focus ring exists (measured) but is excluded from S4's ring filter
(`probes.mjs:1016`) and the `:focus-visible` grep (`:301`); a SIGKILL mid-probe leaves
two lab themes plus a modified tracked `Themes.elm` (clean runs verified byte-exact —
`mkdtempSync` per `zg-5.mjs:351` plus a themes-dir override would remove the window);
`rebuildCatalog()` inside `finally` (`zg-16.mjs:165`) can mask the real exception and
runs after the files are deleted; `generate.test.mjs:93` regenerates tracked build
output as a side effect of `test:unit`; the module header claims a fuller
calculation split than it implements; `zg-16.mjs:21` shadows the injected
`repoDir`/`frontendDir`; `bylineReasons` proves "not a descendant" while only quarto
proves siblinghood; `https:alert(1)` and `http:evil` normalise to live broken links
with no warning, and header keys are case-sensitive; fixed `waitForTimeout(200)`.

## Disposition

Blocker 2 settled by the conductor: AC2's example amended to the parser's normalised
form, keeping the security improvement. Blocker 1 goes back to the Generator. Chain
restarts again — prior findings do not carry across material change.
