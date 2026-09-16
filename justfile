set shell := ["bash", "-euo", "pipefail", "-c"]

port := env_var_or_default("PORT", "4310")
admin_token := env_var_or_default("RZ_ADMIN_TOKEN", "")
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
    dune build @backend @frontend @test @probes

# Bundle the chrome: compiled ESM → one app.js, plus the static assets
bundle: compile
    rm -rf {{dist}}
    mkdir -p {{dist}}/assets
    cp frontend/static/index.html {{dist}}/index.html
    cp frontend/static/assets/*.css {{dist}}/assets/
    bun build _build/default/frontend/output/frontend/src/main.mjs --outfile {{dist}}/assets/app.js --format esm --target browser --minify

build: bundle

# Gather the static assets the Worker serves: the chrome, Themes, Font Library and skeleton
# (without preview.css, which must 404 — BAR-T2).
assets: bundle
    rm -rf dist
    mkdir -p dist/themes dist/skeleton
    cp -r {{dist}}/. dist/
    cp themes/*.css dist/themes/
    cp -r themes/fonts dist/themes/fonts
    cp -r themes/fonts dist/fonts
    cp -r skeleton/. dist/skeleton/
    rm -f dist/skeleton/preview.css

# Run the Worker locally with wrangler (needs DATABASE_URL / DATABASE_AUTH_TOKEN in .dev.vars)
worker: assets
    bunx wrangler dev --port {{port}}

# Publish to Cloudflare Workers
deploy: assets
    bunx wrangler deploy

# ── Branch previews ──────────────────────────────────────────────────────────
# One Worker + one Turso database per pull request, named cvzengarden-pr-<n>.
# Needs CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID and TURSO_API_TOKEN in the environment.
turso_org := "scull7"
turso_group := "cvzengarden"
preview_prefix := "cvzengarden-pr-"

# Create (or reuse) the preview database for PR <n> and write its secrets file (never committed)
preview-db n:
    #!/usr/bin/env bash
    set -euo pipefail
    : "${TURSO_API_TOKEN:?TURSO_API_TOKEN is not set (Turso Platform API token for {{turso_org}})}"
    name="{{preview_prefix}}{{n}}"
    api="https://api.turso.tech/v1/organizations/{{turso_org}}"
    auth="Authorization: Bearer $TURSO_API_TOKEN"
    # Turso answers {"database": {...}} on success and {"error": "..."} otherwise; a 409 means it exists.
    field() { python3 -c 'import json,sys; d=json.load(sys.stdin); v=d.get(sys.argv[1]); print(v if isinstance(v,str) else (v or {}).get(sys.argv[2],""))' "$@"; }
    created=$(curl -sS -X POST -H "$auth" -H "Content-Type: application/json" "$api/databases" \
      -d "{\"name\":\"$name\",\"group\":\"{{turso_group}}\"}")
    host=$(printf '%s' "$created" | field database Hostname)
    if [ -z "$host" ]; then
      existing=$(curl -sS -H "$auth" "$api/databases/$name")
      host=$(printf '%s' "$existing" | field database Hostname)
    fi
    if [ -z "$host" ]; then
      echo "turso: could not create or find $name: $(printf '%s' "$created" | field error x)" >&2; exit 1
    fi
    token_json=$(curl -sS -X POST -H "$auth" "$api/databases/$name/auth/tokens?expiration=30d&authorization=full-access")
    jwt=$(printf '%s' "$token_json" | field jwt x)
    if [ -z "$jwt" ]; then echo "turso: no token for $name: $(printf '%s' "$token_json" | field error x)" >&2; exit 1; fi
    admin=$(openssl rand -hex 24)
    umask 077
    printf '{"DATABASE_URL":"libsql://%s","DATABASE_AUTH_TOKEN":"%s","RZ_ADMIN_TOKEN":"%s"}\n' "$host" "$jwt" "$admin" > .preview-secrets.json
    echo "preview database $name at $host; reviewer token: $admin"

# Deploy PR <n> as its own Worker on workers.dev and attach the preview database secrets
deploy-preview n: assets (preview-db n)
    #!/usr/bin/env bash
    set -euo pipefail
    name="{{preview_prefix}}{{n}}"
    bunx wrangler deploy --env preview --name "$name"
    # --env="" targets the top level: with --env preview the secret command would suffix the name.
    bunx wrangler secret bulk .preview-secrets.json --env="" --name "$name"
    rm -f .preview-secrets.json
    echo "preview: https://$name.resumezen.workers.dev"

# Remove PR <n>'s Worker and database
destroy-preview n:
    #!/usr/bin/env bash
    set -uo pipefail
    name="{{preview_prefix}}{{n}}"
    bunx wrangler delete --env="" --name "$name" --force || echo "no Worker $name"
    curl -sS -o /dev/null -w "turso delete $name: %{http_code}\n" -X DELETE \
      -H "Authorization: Bearer $TURSO_API_TOKEN" \
      "https://api.turso.tech/v1/organizations/{{turso_org}}/databases/$name"

# Run the API + chrome on $PORT (default 4310); DATABASE_URL defaults to file:data/cvzengarden.sqlite.
# RZ_ADMIN_TOKEN unlocks the review queue at /admin; unset leaves moderation off.
serve: build
    mkdir -p data
    PORT={{port}} RZ_ADMIN_TOKEN={{admin_token}} bun _build/default/backend/output/backend/main.mjs

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

test:
    dune build @check @fmt @runtest

# Browser probes: Playwright (OCaml bindings) drives Chromium against a server the runner starts itself.
# One-time: `bunx playwright install chromium` (the web container already has a browser).
probe: build
    bun _build/default/probes/output/probes/main.mjs

verify: fmt-check lint test build probe
