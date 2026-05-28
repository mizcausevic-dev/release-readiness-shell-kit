#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later

set -euo pipefail

sample_threads() {
  cat <<'EOF'
RR-101|checkout-runtime|platform-release|1.5|0.18|3|false|true|Tax retry spikes and rollback artifact still unproven
RR-118|identity-proxy|identity-platform|4.0|0.42|1|true|false|SSO claim mapping changed late in the window
RR-124|analytics-pipeline|data-platform|7.0|0.63|0|true|false|Freshness monitor was noisy but stable after backfill
RR-137|content-edge|webops|2.5|0.24|2|false|true|CDN purge plan and schema parity still need signoff
EOF
}

status_for_thread() {
  local window_hours="$1" error_budget="$2" blocked="$3" rollback_ready="$4" freeze_active="$5"
  if [[ "$freeze_active" == "true" || "$rollback_ready" == "false" || "$blocked" -ge 3 || "$error_budget" == 0.18 || "$window_hours" == 1.5 ]]; then
    echo "red"
  elif [[ "$blocked" -ge 1 || "$error_budget" < 0.50 || "$window_hours" < 5 ]]; then
    echo "yellow"
  else
    echo "green"
  fi
}

decision_for_status() {
  local status="$1"
  case "$status" in
    red) echo "hold" ;;
    yellow) echo "conditional-ship" ;;
    *) echo "ship" ;;
  esac
}

action_for_status() {
  local status="$1" service="$2"
  case "$status" in
    red) echo "Freeze ${service}, assign rollback owner, and re-run preflight before launch." ;;
    yellow) echo "Keep ${service} on watch and clear remaining blockers before release review." ;;
    *) echo "Maintain ship posture for ${service} and preserve proof for the next window." ;;
  esac
}

analyze_threads() {
  local output="${1:-}"
  local lines=()
  local red=0 yellow=0 green=0 total_blocked=0

  while IFS='|' read -r id service owner window_hours error_budget blocked rollback_ready freeze_active top_risk; do
    [[ -z "${id}" ]] && continue
    local status decision action
    status="$(status_for_thread "$window_hours" "$error_budget" "$blocked" "$rollback_ready" "$freeze_active")"
    decision="$(decision_for_status "$status")"
    action="$(action_for_status "$status" "$service")"

    case "$status" in
      red) ((red+=1)) ;;
      yellow) ((yellow+=1)) ;;
      green) ((green+=1)) ;;
    esac
    ((total_blocked+=blocked))

    lines+=("${id}|${service}|${owner}|${window_hours}|${error_budget}|${blocked}|${rollback_ready}|${freeze_active}|${status}|${decision}|${top_risk}|${action}")
  done < <(sample_threads)

  local avg_blocked="0.0"
  if [[ ${#lines[@]} -gt 0 ]]; then
    avg_blocked="$(awk -v total="$total_blocked" -v count="${#lines[@]}" 'BEGIN { printf "%.1f", total / count }')"
  fi

  if [[ -n "$output" ]]; then
    mkdir -p "$(dirname "$output")"
    {
      printf 'summary|total_threads|%s\n' "${#lines[@]}"
      printf 'summary|red_threads|%s\n' "$red"
      printf 'summary|yellow_threads|%s\n' "$yellow"
      printf 'summary|green_threads|%s\n' "$green"
      printf 'summary|avg_blocked_dependencies|%s\n' "$avg_blocked"
      for line in "${lines[@]}"; do
        printf 'thread|%s\n' "$line"
      done
    } > "$output"
  else
    printf 'summary|total_threads|%s\n' "${#lines[@]}"
    printf 'summary|red_threads|%s\n' "$red"
    printf 'summary|yellow_threads|%s\n' "$yellow"
    printf 'summary|green_threads|%s\n' "$green"
    printf 'summary|avg_blocked_dependencies|%s\n' "$avg_blocked"
    for line in "${lines[@]}"; do
      printf 'thread|%s\n' "$line"
    done
  fi
}

summary_value() {
  local report="$1" key="$2"
  awk -F'|' -v key="$key" '$1=="summary" && $2==key { print $3 }' "$report"
}

html_escape() {
  local text="${1:-}"
  text="${text//&/&amp;}"
  text="${text//</&lt;}"
  text="${text//>/&gt;}"
  text="${text//\"/&quot;}"
  printf '%s' "$text"
}

