#!/usr/bin/env python3
"""Populate ELM_HOME so `elm make` builds with no network access.

Claude Code on the web blocks package.elm-lang.org, so Elm cannot fetch either
the package sources or its registry. Both are recoverable without that host:

  * package sources -- every Elm package is a tagged GitHub repo, and github.com
    is reachable, so each dependency is cloned at its exact pinned tag.
  * registry.dat -- `elm make` refuses to build without it even when every
    package is already cached. It is a Data.Binary encoding of
    Deps.Registry.Registry from elm/compiler 0.19.1:
        Registry       = Int count <> Map Pkg.Name KnownVersions
        KnownVersions  = Version newest <> [Version] previous
        Pkg.Name       = putUnder256 author <> putUnder256 project
        putUnder256 s  = Word8 length <> utf8 bytes
        Version        = 3 * Word8   (major < 255, minor < 256, patch < 256)
        Int / list len = Int64 big-endian; Map serialises via toAscList, so the
                         keys must be written in ascending (author, project) order.

Idempotent: packages already present are left alone, registry.dat is rewritten
to match whatever the cache holds.
"""

from __future__ import annotations

import json
import os
import pathlib
import shutil
import struct
import subprocess
import sys
import tempfile

ELM_VERSION = "0.19.1"


def elm_home() -> pathlib.Path:
    return pathlib.Path(os.environ.get("ELM_HOME") or (pathlib.Path.home() / ".elm"))


def pinned_dependencies(elm_json: pathlib.Path) -> list[tuple[str, str, str]]:
    """Every direct and indirect dependency, as (author, project, version)."""
    spec = json.loads(elm_json.read_text(encoding="utf-8"))
    deps = spec.get("dependencies", {})
    merged: dict[str, str] = {}
    for group in ("direct", "indirect"):
        merged.update(deps.get(group, {}))
    for group in ("direct", "indirect"):
        merged.update(spec.get("test-dependencies", {}).get(group, {}))

    out = []
    for name, version in merged.items():
        author, _, project = name.partition("/")
        if author and project:
            out.append((author, project, version))
    return out


def clone_package(author: str, project: str, version: str, packages: pathlib.Path) -> bool:
    dest = packages / author / project / version
    if (dest / "src").is_dir():
        return True

    url = f"https://github.com/{author}/{project}.git"
    with tempfile.TemporaryDirectory() as tmp:
        checkout = pathlib.Path(tmp) / "pkg"
        result = subprocess.run(
            ["git", "clone", "--quiet", "--depth", "1", "--branch", version, url, str(checkout)],
            capture_output=True,
            text=True,
            timeout=180,
        )
        if result.returncode != 0:
            print(f"  FAIL {author}/{project}@{version}: {result.stderr.strip()[:160]}")
            return False
        shutil.rmtree(checkout / ".git", ignore_errors=True)
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(checkout, dest)
    return True


def put_int(value: int) -> bytes:
    return struct.pack(">q", value)


def put_under_256(text: str) -> bytes:
    raw = text.encode("utf-8")
    if len(raw) >= 256:
        raise ValueError(f"identifier too long for putUnder256: {text}")
    return struct.pack(">B", len(raw)) + raw


def put_version(version: str) -> bytes:
    major, minor, patch = (int(part) for part in version.split("."))
    if not (major < 255 and minor < 256 and patch < 256):
        raise ValueError(f"version outside the 3-byte encoding: {version}")
    return struct.pack(">BBB", major, minor, patch)


def write_registry(entries: list[tuple[str, str, str]], packages: pathlib.Path) -> pathlib.Path:
    # Map is encoded via toAscList, so keys must be in ascending byte order.
    ordered = sorted(entries, key=lambda item: (item[0].encode(), item[1].encode()))

    blob = put_int(len(ordered))          # Registry._count
    blob += put_int(len(ordered))         # Map -> association list length
    for author, project, version in ordered:
        blob += put_under_256(author) + put_under_256(project)   # key
        blob += put_version(version) + put_int(0)                # newest, no previous

    registry = packages / "registry.dat"
    registry.write_bytes(blob)
    return registry


def main() -> int:
    project_dir = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    elm_json = project_dir / "frontend" / "elm.json"
    if not elm_json.is_file():
        print(f"no {elm_json}; skipping Elm cache")
        return 0

    packages = elm_home() / ELM_VERSION / "packages"
    packages.mkdir(parents=True, exist_ok=True)

    wanted = pinned_dependencies(elm_json)
    if not wanted:
        print("elm.json lists no dependencies; skipping")
        return 0

    cached = [pkg for pkg in wanted if clone_package(*pkg, packages)]
    registry = write_registry(cached, packages)

    print(f"elm cache: {len(cached)}/{len(wanted)} packages under {packages}")
    print(f"elm registry: {registry} ({registry.stat().st_size} bytes)")
    return 0 if len(cached) == len(wanted) else 1


if __name__ == "__main__":
    sys.exit(main())
