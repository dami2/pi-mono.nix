#!/usr/bin/env bash
set -euo pipefail

repo_url=https://github.com/badlogic/pi-mono.git
version_file=VERSION.json
archive_base_url=https://github.com/badlogic/pi-mono/archive/refs/tags
fake_npm_deps_hash=sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=

die() { echo "$*" >&2; exit 1; }
out() { [[ -n ${GITHUB_OUTPUT:-} ]] && echo "$1=$2" >> "$GITHUB_OUTPUT"; }
need() { command -v "$1" >/dev/null || die "Missing required command: $1"; }

write_version_json() {
  local rev=$1 hash=$2 npmDepsHash=$3 tmp
  tmp=$(mktemp)
  jq \
    --arg rev "$rev" \
    --arg hash "$hash" \
    --arg npmDepsHash "$npmDepsHash" \
    '.rev = $rev
    | .hash = $hash
    | .projects["coding-agent"].npmDepsHash = $npmDepsHash' \
    "$version_file" > "$tmp"
  mv "$tmp" "$version_file"
}

need git
need jq
need nix

current_rev=$(jq -r '.rev' "$version_file")
latest_rev=$(
  git ls-remote --tags --refs "$repo_url" 'v*' \
    | awk -F/ '{print $3}' \
    | grep -E '^v[0-9]+(\.[0-9]+)*$' \
    | sort -V \
    | tail -n1
)

[[ -n "$latest_rev" ]] || die "Failed to determine latest upstream tag"

if [[ "$latest_rev" == "$current_rev" ]]; then
  echo "VERSION.json already points to $current_rev"
  out changed false
  out version "$current_rev"
  exit 0
fi

src_hash=$(nix store prefetch-file --json --unpack "${archive_base_url}/${latest_rev}.tar.gz" | jq -r .hash)

backup=$(mktemp)
log=$(mktemp)
cp "$version_file" "$backup"
trap 'cp "$backup" "$version_file" 2>/dev/null || true; rm -f "$backup" "$log"' EXIT

write_version_json "$latest_rev" "$src_hash" "$fake_npm_deps_hash"

if nix build .#coding-agent --no-link >/dev/null 2>"$log"; then
  die "Expected nix build to fail with a fake npmDepsHash, but it succeeded"
fi

npm_deps_hash=$(sed -nE 's/.*got:[[:space:]]*(sha256-[A-Za-z0-9+/=]+).*/\1/p' "$log" | tail -n1)
[[ -n "$npm_deps_hash" ]] || die "Failed to extract npmDepsHash from nix build output"

write_version_json "$latest_rev" "$src_hash" "$npm_deps_hash"
nix build .#coding-agent --no-link >/dev/null

trap - EXIT
rm -f "$backup" "$log"

echo "Updated VERSION.json to $latest_rev"
out changed true
out version "$latest_rev"
