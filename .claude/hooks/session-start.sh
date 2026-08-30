#!/bin/bash
# Provision a Claude Code on the web container so `just verify` can actually run.
#
# The repo needs five things the base image does not carry: the pinto board CLI
# (every status view reads it), just, and the wasm/Elm/Playwright toolchain the
# frontend probes drive. Three of those cannot be fetched the usual way here --
# wasm-pack's downloader, package.elm-lang.org, and `playwright install` all
# fail behind the egress proxy -- so each one is provisioned from a reachable
# source instead. See the per-step comments.
#
# Idempotent: every step is skipped when its output is already in place, so a
# cached container re-runs this in seconds.
set -euo pipefail

# Local checkouts already have these tools; this only fixes the web container.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CARGO_BIN="${CARGO_HOME:-$HOME/.cargo}/bin"
BINARYEN_VERSION="version_117"
BINARYEN_PREFIX="/opt/binaryen"
PATH="$CARGO_BIN:$BINARYEN_PREFIX/bin:$PATH"
export PATH

step() { printf '\n== %s\n' "$1"; }

# 1. Board + task runner. `pinto` is published as the pinto-cli crate but
#    installs a binary called `pinto`, which is why searching for a "pinto"
#    package finds an unrelated SQL library instead.
step "cargo CLIs"
for spec in "pinto:pinto-cli" "just:just" "wasm-pack:wasm-pack"; do
  binary="${spec%%:*}"
  crate="${spec##*:}"
  if command -v "$binary" >/dev/null 2>&1; then
    echo "  have $binary"
  else
    echo "  installing $crate"
    cargo install "$crate" --locked
  fi
done

# 2. wasm-opt. wasm-pack downloads binaryen itself, but its HTTP client fails
#    behind the proxy while curl succeeds, so fetch the release directly.
step "binaryen (wasm-opt)"
if command -v wasm-opt >/dev/null 2>&1; then
  echo "  have wasm-opt"
else
  tarball="$(mktemp -d)/binaryen.tar.gz"
  curl -fsSL --retry 3 -o "$tarball" \
    "https://github.com/WebAssembly/binaryen/releases/download/${BINARYEN_VERSION}/binaryen-${BINARYEN_VERSION}-x86_64-linux.tar.gz"
  mkdir -p "$BINARYEN_PREFIX"
  tar xzf "$tarball" -C "$BINARYEN_PREFIX" --strip-components=1
  rm -rf "$(dirname "$tarball")"
  echo "  installed $(wasm-opt --version)"
fi

# 3. Frontend packages. npm install (not ci) so the cached container reuses them.
step "npm dependencies"
npm --prefix "$PROJECT_DIR/frontend" install --no-audit --no-fund

# 4. Elm. package.elm-lang.org is blocked, so the helper clones each pinned
#    package from GitHub and writes the registry.dat that `elm make` demands.
step "elm offline cache"
python3 "$PROJECT_DIR/.claude/hooks/elm-offline-cache.py" "$PROJECT_DIR"

# 5. Playwright. The image ships one Chromium revision and playwright-core may
#    pin another; `playwright install` cannot reach the CDN. Map the revision it
#    asks for onto the revision that is actually here, matching the directory
#    layout the installed playwright expects.
step "playwright browsers"
PW_ROOT="${PLAYWRIGHT_BROWSERS_PATH:-/opt/pw-browsers}"
BROWSERS_JSON="$PROJECT_DIR/frontend/node_modules/playwright-core/browsers.json"
if [ -f "$BROWSERS_JSON" ] && [ -d "$PW_ROOT" ]; then
  WANT="$(python3 -c "
import json,sys
data=json.load(open(sys.argv[1]))
print(next((b['revision'] for b in data.get('browsers',[]) if b['name']=='chromium'),''))
" "$BROWSERS_JSON")"
  HAVE="$(ls -d "$PW_ROOT"/chromium-[0-9]* 2>/dev/null | sed 's/.*chromium-//' | sort -n | tail -1 || true)"

  if [ -z "$WANT" ] || [ -z "$HAVE" ]; then
    echo "  cannot determine revisions (want='${WANT:-?}' have='${HAVE:-?}'); leaving as-is"
  elif [ "$WANT" = "$HAVE" ]; then
    echo "  chromium $HAVE matches"
  else
    echo "  mapping chromium $HAVE -> requested $WANT"
    shell_src="$PW_ROOT/chromium_headless_shell-$HAVE/chrome-linux/headless_shell"
    shell_dst="$PW_ROOT/chromium_headless_shell-$WANT/chrome-headless-shell-linux64"
    if [ -x "$shell_src" ]; then
      mkdir -p "$shell_dst"
      ln -sfn "$shell_src" "$shell_dst/chrome-headless-shell"
      touch "$PW_ROOT/chromium_headless_shell-$WANT/INSTALLATION_COMPLETE" \
            "$PW_ROOT/chromium_headless_shell-$WANT/DEPENDENCIES_VALIDATED"
    fi
    if [ -d "$PW_ROOT/chromium-$HAVE/chrome-linux" ]; then
      mkdir -p "$PW_ROOT/chromium-$WANT"
      ln -sfn "$PW_ROOT/chromium-$HAVE/chrome-linux" "$PW_ROOT/chromium-$WANT/chrome-linux"
      touch "$PW_ROOT/chromium-$WANT/INSTALLATION_COMPLETE" \
            "$PW_ROOT/chromium-$WANT/DEPENDENCIES_VALIDATED"
    fi
  fi
else
  echo "  no playwright-core or browser root; skipping"
fi

# Keep wasm-opt and the cargo binaries on PATH for the rest of the session.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$CARGO_BIN:$BINARYEN_PREFIX/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

printf '\n== ready: %s | %s\n' "$(pinto --version 2>/dev/null || echo 'pinto missing')" \
                               "$(just --version 2>/dev/null || echo 'just missing')"
