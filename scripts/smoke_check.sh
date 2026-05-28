#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

scripts/generate_site.sh >/dev/null

required=(
  "site/index.html"
  "site/release-lane/index.html"
  "site/preflight-matrix/index.html"
  "site/rollback-posture/index.html"
  "site/verification/index.html"
  "site/docs/index.html"
  "site/robots.txt"
  "site/sitemap.xml"
)

for path in "${required[@]}"; do
  [[ -f "${path}" ]] || { echo "Missing generated path: ${path}" >&2; exit 1; }
done

root_html="$(cat site/index.html)"
for needle in "Release readiness shell kit" "/rollback-posture/" "platform engineering"; do
  grep -qi "${needle}" <<<"${root_html}" || { echo "Expected keyword missing from root HTML: ${needle}" >&2; exit 1; }
done

echo "Smoke check passed."

