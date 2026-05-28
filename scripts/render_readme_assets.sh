#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/src/release_readiness_shell.sh"

report_file="$(mktemp)"
trap 'rm -f "${report_file}"' EXIT
mkdir -p "${ROOT_DIR}/screenshots"

analyze_threads "${report_file}"

total_threads="$(summary_value "${report_file}" total_threads)"
red_threads="$(summary_value "${report_file}" red_threads)"
avg_blocked="$(summary_value "${report_file}" avg_blocked_dependencies)"
top_hold="$(awk -F'|' '$1=="thread" && $10=="red" { print $3; exit }' "${report_file}")"
top_risk="$(awk -F'|' '$1=="thread" && $10=="red" { print $12; exit }' "${report_file}")"

write_svg() {
  local path="$1" eyebrow="$2" title="$3" line1="$4" line2="$5" accent="$6"
  cat > "${path}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900" viewBox="0 0 1600 900">
  <rect width="1600" height="900" fill="#05070c"/>
  <rect x="48" y="48" width="1504" height="804" rx="30" fill="#0b1220" stroke="#17324d" stroke-width="2"/>
  <text x="96" y="118" fill="${accent}" font-family="ui-monospace,Consolas,monospace" font-size="26" letter-spacing="6">${eyebrow}</text>
  <text x="96" y="196" fill="#f2f7ff" font-family="Georgia,Times New Roman,serif" font-size="58" font-weight="700">${title}</text>
  <text x="96" y="272" fill="#b8c9df" font-family="Segoe UI,Arial,sans-serif" font-size="30">${line1}</text>
  <text x="96" y="320" fill="#b8c9df" font-family="Segoe UI,Arial,sans-serif" font-size="30">${line2}</text>
</svg>
EOF
}

write_svg "${ROOT_DIR}/screenshots/01-overview.svg" "RELEASE READINESS SHELL KIT" "Bash proof for launch blockers and rollback posture." "Threads in review: ${total_threads} · escalated: ${red_threads} · avg blocked deps: ${avg_blocked}." "Static shell-generated operator routes stay buyer-readable." "#19c7ff"
write_svg "${ROOT_DIR}/screenshots/02-release-lane.svg" "RELEASE LANE" "The riskiest launch threads stay visible first." "Top hold thread: ${top_hold}." "${top_risk}" "#37ff8b"
write_svg "${ROOT_DIR}/screenshots/03-rollback-posture.svg" "ROLLBACK POSTURE" "Rollback readiness and launch action stay explicit." "Hold threads require named rollback owners and freeze clearance." "Conditional-ship lanes stay visible before the launch window closes." "#ffcc66"
write_svg "${ROOT_DIR}/screenshots/04-verification.svg" "VERIFICATION" "The same Bash path drives analysis, pages, and proof assets." "Routes: /release-lane/ · /preflight-matrix/ · /rollback-posture/." "Template pack planned · consulting hook." "#b88cff"

echo "Rendered README assets."

