#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/src/release_readiness_shell.sh"

report_file="$(mktemp)"
trap 'rm -f "${report_file}"' EXIT

analyze_threads "${report_file}"

echo "Scenario: Release readiness shell kit"
echo "Threads: $(summary_value "${report_file}" total_threads)"
echo "Escalated: $(summary_value "${report_file}" red_threads)"
echo "Conditional ship: $(summary_value "${report_file}" yellow_threads)"
echo "Avg blocked deps: $(summary_value "${report_file}" avg_blocked_dependencies)"
echo "Threads on hold:"
awk -F'|' '$1=="thread" && $10=="red" { printf " - %s (%s)\n", $3, $12 }' "${report_file}"

