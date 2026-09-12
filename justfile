set shell := ["bash", "-euo", "pipefail", "-c"]

port := env_var_or_default("PORT", "4310")
dist := "frontend/dist"

default:
    @just --list

# One-time toolchain: opam switch with OCaml 5.3 + Melange, and Bun packages
init:
    opam switch list --short | grep -qx cvz || opam switch create cvz ocaml-base-compiler.5.3.0 --yes
    opam install --switch cvz --yes dune melange ocamlformat
    bun install

# Compile every Melange target (shared, backend, frontend, tests) to _build/
compile:
    dune build @backend @frontend @test

# Bundle the chrome: compiled ESM → one app.js, plus the static assets
bundle: compile
    rm -rf {{dist}}
    mkdir -p {{dist}}/assets
    cp frontend/static/index.html {{dist}}/index.html
    cp frontend/static/assets/*.css {{dist}}/assets/
    bun build _build/default/frontend/output/frontend/src/main.mjs --outfile {{dist}}/assets/app.js --format esm --target browser --minify

build: bundle

# Run the API + chrome on $PORT (default 4310); DATABASE_URL defaults to file:data/cvzengarden.sqlite
serve: build
    mkdir -p data
    PORT={{port}} bun _build/default/backend/output/backend/main.mjs

# Recompile on change and serve (two terminals: `just watch` and `just serve`)
watch:
    dune build @backend @frontend @test --watch

# Quality gates
fmt:
    dune fmt 2>/dev/null || dune build @fmt --auto-promote

fmt-check:
    dune build @fmt

# Warnings are errors under dune's dev profile; this is the lint gate
lint: compile no-js

# The repository contract: zero hand-written JavaScript
no-js:
    @if git ls-files | grep -E '\.(js|mjs|cjs|jsx|ts|tsx)$' ; then echo "hand-written JavaScript found"; exit 1; else echo "no-js: OK"; fi
    @if git ls-files '*.html' | xargs grep -l '<script' 2>/dev/null | grep -v '^frontend/static/index.html$' ; then echo "inline <script> found"; exit 1; else echo "no-inline-script: OK"; fi

test: compile
    bun _build/default/test/output/test/main.mjs

verify: fmt-check lint test build
