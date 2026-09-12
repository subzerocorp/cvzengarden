#!/bin/bash
# Provision a Claude Code on the web container so `just verify` can run.
#
# The repo needs an OCaml 5.3 switch with dune + melange + ocamlformat (via
# opam), Bun for the runtime/bundler/tests, just, and the npm packages. Each
# step is skipped when its output is already in place, so a cached container
# re-runs this in seconds.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
SWITCH="cvz"
OPAM_VERSION="2.3.0"
export OPAMYES=1 OPAMCONFIRMLEVEL=unsafe-yes
step() { printf '\n== %s\n' "$1"; }

step "opam"
if ! command -v opam >/dev/null 2>&1; then
  curl -fsSL --retry 3 -o /usr/local/bin/opam \
    "https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/opam-${OPAM_VERSION}-x86_64-linux"
  chmod +x /usr/local/bin/opam
fi
if [ ! -d "$HOME/.opam" ]; then
  opam init --disable-sandboxing --bare -y
fi
if ! opam switch list --short 2>/dev/null | grep -qx "$SWITCH"; then
  step "OCaml 5.3 switch (a few minutes on a cold container)"
  opam switch create "$SWITCH" ocaml-base-compiler.5.3.0 -y
fi
eval "$(opam env --switch="$SWITCH" --set-switch)"
if ! command -v melc >/dev/null 2>&1 || ! command -v ocamlformat >/dev/null 2>&1; then
  step "dune + melange + ocamlformat"
  opam install -y dune melange ocamlformat
fi

step "just"
if ! command -v just >/dev/null 2>&1; then
  cargo install just --locked
fi

step "bun packages"
if ! command -v bun >/dev/null 2>&1; then
  echo "  bun is missing; install it from https://bun.com/ and re-run" >&2
  exit 1
fi
(cd "$PROJECT_DIR" && bun install --no-summary)

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export PATH=\"$HOME/.cargo/bin:$HOME/.bun/bin:\$PATH\""
    opam env --switch="$SWITCH" --set-switch
  } >> "$CLAUDE_ENV_FILE"
fi

printf '\n== ready: ocaml %s | melange %s | bun %s | just %s\n' \
  "$(ocaml -vnum 2>/dev/null || echo missing)" \
  "$(opam list --installed --short melange 2>/dev/null | tr -d '\n' || echo missing)" \
  "$(bun --version 2>/dev/null || echo missing)" \
  "$(just --version 2>/dev/null || echo missing)"
