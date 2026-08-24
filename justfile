set shell := ["bash", "-euo", "pipefail", "-c"]

probe_port := env_var_or_default("PROBE_PORT", "4310")

default:
    @just --list

# Environment bootstrap
init:
    cd frontend && npm install --no-audit --no-fund
    just check

# Session ritual (HARNESS-SPEC §3.5)
ritual:
    git status --short
    git log --oneline -10
    tail -n 30 progress.md
    pinto list

# Quality gates
check:
    cd renderer && cargo check --all-targets
    cd renderer-wasm && cargo check --all-targets
    @if [ -f backend/Cargo.toml ]; then cd backend && cargo check --all-targets; fi

fmt:
    cd renderer && cargo fmt --all -- --check
    cd renderer-wasm && cargo fmt --all -- --check
    @if [ -f backend/Cargo.toml ]; then cd backend && cargo fmt --all -- --check; fi

clippy:
    cd renderer && cargo clippy --all-targets -- -D warnings -D clippy::pedantic
    cd renderer-wasm && cargo clippy --all-targets -- -D warnings -D clippy::pedantic
    @if [ -f backend/Cargo.toml ]; then cd backend && cargo clippy --all-targets -- -D warnings -D clippy::pedantic; fi

test-rust:
    cd renderer && cargo test
    cd renderer-wasm && cargo test
    @if [ -f backend/Cargo.toml ]; then cd backend && cargo test; fi

test-frontend:
    cd frontend && PROBE_PORT={{probe_port}} npm test

test: test-rust test-frontend

# Build the renderer as a web Wasm module into frontend/static/wasm (gitignored)
wasm:
    wasm-pack build --target web renderer-wasm --out-dir ../frontend/static/wasm

# Full matrix
verify: fmt clippy test

# Run the Garden locally (static chrome)
serve port="4310":
    cd frontend && npm run build && PORT={{port}} node scripts/serve.mjs

harness-validate:
    jq -e 'type == "object"' features.json > /dev/null && echo "features.json: OK"
    pinto list --json > /dev/null && echo "pinto board: OK"
