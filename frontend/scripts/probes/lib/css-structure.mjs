/**
 * Static structure of a theme sheet, for the ZG-12 `rz-rise` rules.
 *
 * Everything here is a calculation over a CSS string. `parseRules` is a
 * brace-matching scan (no CSS parser dependency): each style rule becomes a
 * record `{ selector, context, declarations }` where `context` is the chain
 * of enclosing at-rule preludes. `@keyframes` bodies are skipped, so the
 * keyframe `from { opacity: 0 }` never reads as a selector rule.
 */

const VIEW_SUPPORTS = /^@supports\s*\(\s*animation-timeline\s*:\s*view\(\s*\)\s*\)$/;
const SECTION_SELECTOR = /\.rz-section(?![\w-])/;
const SECTION_OR_RISE_SELECTOR = /\.rz-(?:section|rise)(?![\w-])/;
const ANIMATION_PROPS = new Set(["animation", "animation-name"]);
const BANNED_FILL_TOKENS = ["both", "backwards"];

const COMMENT = /\/\*[\s\S]*?\*\//g;

function stripComments(css) {
  return css.replace(COMMENT, " ");
}

// Comments replaced by same-length blanks, so indices into the result index the original.
function blankComments(css) {
  return css.replace(COMMENT, (comment) => " ".repeat(comment.length));
}

function squash(text) {
  return text.replace(/\s+/g, " ").trim();
}

export function isViewSupports(prelude) {
  return VIEW_SUPPORTS.test(squash(prelude));
}

function isKeyframes(prelude) {
  return /^@(?:-webkit-)?keyframes\b/.test(squash(prelude));
}

// Brace-matched `{ prelude, body, start, end }` blocks at the top level of `text`,
// comments blanked (a `;` or `{` inside one is not syntax). `start` is the index
// of the prelude, `end` the index after the closing brace, both into `text`.
export function topLevelBlocks(source) {
  const text = blankComments(source);
  const blocks = [];
  let depth = 0;
  let boundary = 0;
  let preludeEnd = 0;
  for (let i = 0; i < text.length; i += 1) {
    const ch = text[i];
    if (ch === "{") {
      if (depth === 0) {
        preludeEnd = i;
      }
      depth += 1;
    } else if (ch === "}") {
      depth -= 1;
      if (depth === 0) {
        blocks.push({ prelude: text.slice(boundary, preludeEnd), body: text.slice(preludeEnd + 1, i), start: boundary, end: i + 1 });
        boundary = i + 1;
      }
    } else if (ch === ";" && depth === 0) {
      boundary = i + 1;
    }
  }
  return blocks;
}

function parseDeclarations(body) {
  return body
    .split(";")
    .map((chunk) => chunk.trim())
    .filter(Boolean)
    .map((chunk) => {
      const colon = chunk.indexOf(":");
      return { property: chunk.slice(0, colon).trim().toLowerCase(), value: squash(chunk.slice(colon + 1)) };
    })
    .filter((decl) => decl.property);
}

function rulesIn(text, context) {
  return topLevelBlocks(text).flatMap(({ prelude, body }) => {
    // Blocks already carry blanked comments; nested scans re-blank harmlessly.
    if (isKeyframes(prelude)) {
      return [];
    }
    const name = squash(prelude);
    return body.includes("{")
      ? rulesIn(body, [...context, name])
      : [{ selector: name, context, declarations: parseDeclarations(body) }];
  });
}

export function parseRules(css) {
  return rulesIn(stripComments(css), []);
}

// The sheet with every `@supports (animation-timeline: view())` block removed:
// the "browser without scroll-driven animations" view of the theme.
export function withoutViewSupports(css) {
  const cut = topLevelBlocks(css).filter((block) => isViewSupports(block.prelude));
  return cut.reduceRight((text, block) => text.slice(0, block.start) + text.slice(block.end), css);
}

function selectsSection(rule) {
  return SECTION_SELECTOR.test(rule.selector);
}

function inViewSupports(rule) {
  return rule.context.some(isViewSupports);
}

function isRiseDeclaration(decl) {
  return ANIMATION_PROPS.has(decl.property) && /\brz-rise\b/.test(decl.value);
}

function isAnimationDeclaration(decl) {
  return decl.property.startsWith("animation");
}

function tokens(value) {
  return value.split(/[\s,]+/);
}

function riseRules(rules) {
  return rules.filter((rule) => selectsSection(rule) && rule.declarations.some(isRiseDeclaration));
}

function describe(rule, decl) {
  return `\`${rule.selector}\` ${decl.property}: ${decl.value}`;
}

// (a) every `.rz-section` rz-rise declaration sits inside the view() @supports block.
export function riseOutsideSupportsReasons(rules) {
  return riseRules(rules)
    .filter((rule) => !inViewSupports(rule))
    .flatMap((rule) => rule.declarations.filter(isRiseDeclaration).map((decl) => `(a) ${describe(rule, decl)} outside @supports (animation-timeline: view())`));
}

function declaresForwards(rule) {
  return rule.declarations.some(
    (decl) =>
      (decl.property === "animation-fill-mode" && decl.value === "forwards") ||
      (decl.property === "animation" && tokens(decl.value).includes("forwards")),
  );
}

function declaresViewTimeline(rule) {
  return rule.declarations.some((decl) => decl.property === "animation-timeline" && /^view\(\s*\)$/.test(decl.value));
}

// (b) inside the block the rise rule uses `animation-timeline: view()` and fill `forwards`;
// no `.rz-section` animation declaration anywhere carries `both` / `backwards`.
export function riseInsideSupportsReasons(rules) {
  const inside = riseRules(rules).filter(inViewSupports);
  const banned = rules
    .filter(selectsSection)
    .flatMap((rule) => rule.declarations.filter(isAnimationDeclaration).map((decl) => ({ rule, decl })))
    .filter(({ decl }) => tokens(decl.value).some((token) => BANNED_FILL_TOKENS.includes(token)));
  return [
    ...(inside.length === 0 ? ["(b) no `.rz-section` rz-rise rule inside @supports (animation-timeline: view())"] : []),
    ...inside.filter((rule) => !declaresViewTimeline(rule)).map((rule) => `(b) \`${rule.selector}\` inside @supports lacks animation-timeline: view()`),
    ...inside.filter((rule) => !declaresForwards(rule)).map((rule) => `(b) \`${rule.selector}\` inside @supports fill mode is not forwards`),
    ...banned.map(({ rule, decl }) => `(b) ${describe(rule, decl)} uses a both/backwards fill`),
  ];
}

function isHiddenRest(decl) {
  const opacity = decl.property === "opacity" ? Number.parseFloat(decl.value) : NaN;
  return (Number.isFinite(opacity) && opacity < 1) || (decl.property === "transform" && decl.value.includes("translateY("));
}

// (c) no `opacity` < 1 / `transform: translateY(` on `.rz-section` or `.rz-rise` outside @keyframes.
export function hiddenRestReasons(rules) {
  return rules
    .filter((rule) => SECTION_OR_RISE_SELECTOR.test(rule.selector))
    .flatMap((rule) => rule.declarations.filter(isHiddenRest).map((decl) => `(c) ${describe(rule, decl)} hides the rest state`));
}

export function riseStructureReasons(css) {
  const rules = parseRules(css);
  return [...riseOutsideSupportsReasons(rules), ...riseInsideSupportsReasons(rules), ...hiddenRestReasons(rules)];
}

export function describeRiseStructure(css) {
  const rules = parseRules(css);
  const rise = riseRules(rules);
  const inside = rise.filter(inViewSupports).length;
  return `${rules.filter(selectsSection).length} .rz-section rule(s), rz-rise declared ${rise.length}× (${inside} inside @supports view()), fill forwards, ${hiddenRestReasons(rules).length} hidden rest-state declaration(s)`;
}
