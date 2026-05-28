#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/src/release_readiness_shell.sh"

report_file="$(mktemp)"
trap 'rm -f "${report_file}"' EXIT

bash -n "${ROOT_DIR}/src/release_readiness_shell.sh"
bash -n "${ROOT_DIR}/scripts/generate_site.sh"
bash -n "${ROOT_DIR}/scripts/run_demo.sh"
bash -n "${ROOT_DIR}/scripts/smoke_check.sh"
bash -n "${ROOT_DIR}/scripts/render_readme_assets.sh"

analyze_threads "${report_file}"

[[ "$(summary_value "${report_file}" total_threads)" == "4" ]] || { echo "Expected 4 threads." >&2; exit 1; }
[[ "$(summary_value "${report_file}" red_threads)" -ge 1 ]] || { echo "Expected at least one red thread." >&2; exit 1; }
grep -q "thread|RR-101|" "${report_file}" || { echo "Missing RR-101 in report." >&2; exit 1; }
grep -q "hold" "${report_file}" || { echo "Expected a hold decision." >&2; exit 1; }

echo "All tests passed."

