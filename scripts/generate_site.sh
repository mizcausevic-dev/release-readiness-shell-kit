#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/src/release_readiness_shell.sh"

REPORT_DIR="${ROOT_DIR}/site/.generated"
REPORT_FILE="${REPORT_DIR}/report.txt"
SITE_DIR="${ROOT_DIR}/site"
BASE_URL="https://release.kineticgain.com"

mkdir -p "$REPORT_DIR" "$SITE_DIR"
analyze_threads "$REPORT_FILE"

total_threads="$(summary_value "$REPORT_FILE" total_threads)"
red_threads="$(summary_value "$REPORT_FILE" red_threads)"
yellow_threads="$(summary_value "$REPORT_FILE" yellow_threads)"
green_threads="$(summary_value "$REPORT_FILE" green_threads)"
avg_blocked="$(summary_value "$REPORT_FILE" avg_blocked_dependencies)"

thread_rows="$(awk -F'|' '
  $1=="thread" {
    printf "<tr><td><b>%s</b><br><span class=\"section-note\">%s</span></td><td>%s</td><td>%s</td><td>%s</td><td><span class=\"status %s\">%s</span></td><td>%s</td></tr>\n",
      $3, $2, $6, $7, $8=="true"?"Yes":"No", $10=="red"?"bad":($10=="yellow"?"warn":"green"), toupper($10), $12
  }' "$REPORT_FILE")"

release_cards="$(awk -F'|' '
  $1=="thread" {
    printf "<div class=\"card\"><div class=\"eyebrow\">%s · %s</div><h3>%s</h3><p>%s blocked dependencies, error budget %s, rollback ready: %s.</p><p>%s</p></div>\n",
      $2, $4, $3, $7, $6, $8=="true"?"yes":"no", $13
  }' "$REPORT_FILE")"

preflight_rows="$(awk -F'|' '
  $1=="thread" {
    printf "<tr><td><b>%s</b></td><td>%s hrs</td><td>%s</td><td>%s</td><td>%s</td></tr>\n",
      $3, $5, $6, $8=="true"?"ready":"not ready", $9=="true"?"freeze":"clear"
  }' "$REPORT_FILE")"

rollback_rows="$(awk -F'|' '
  $1=="thread" {
    printf "<tr><td><b>%s</b></td><td>%s</td><td>%s</td><td>%s</td></tr>\n",
      $3, $8=="true"?"Ready":"Not ready", $12, $13
  }' "$REPORT_FILE")"

base_css=':root{--bg:#070a0f;--panel:#0b1220;--line:rgba(120,255,170,.18);--line2:rgba(120,255,170,.10);--text:#e9f3ff;--muted:rgba(233,243,255,.72);--muted2:rgba(233,243,255,.55);--bert:#37ff8b;--bert2:#19c7ff;--warn:#ffcc66;--bad:#ff5c7a;--plum:#b88cff;--shadow:0 18px 60px rgba(0,0,0,.55);--mono:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,"Courier New",monospace;--sans:ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif}*{box-sizing:border-box}html,body{height:100%}body{margin:0;font-family:var(--sans);color:var(--text);background:radial-gradient(1200px 600px at 20% -10%, rgba(55,255,139,.18), transparent 60%),radial-gradient(900px 520px at 90% 0%, rgba(25,199,255,.16), transparent 55%),radial-gradient(1000px 600px at 50% 110%, rgba(55,255,139,.10), transparent 60%),linear-gradient(180deg,#05070c 0%,#070a0f 35%,#05070c 100%)}.grid-bg{position:fixed;inset:0;pointer-events:none;opacity:.12;z-index:-1;background-image:linear-gradient(to right, rgba(55,255,139,.14) 1px, transparent 1px),linear-gradient(to bottom, rgba(55,255,139,.10) 1px, transparent 1px);background-size:46px 46px;mask-image:radial-gradient(900px 600px at 40% 10%, #000 60%, transparent 100%)}.wrap{max-width:1280px;margin:0 auto;padding:24px 22px 80px}.topbar{display:flex;justify-content:space-between;align-items:flex-start;gap:14px;border-bottom:1px solid var(--line2);padding-bottom:14px;margin-bottom:22px;font-family:var(--mono);font-size:11px;letter-spacing:.16em;color:var(--muted);text-transform:uppercase}.topbar .left{color:var(--bert)}.topbar .right{text-align:right}.herorow{display:grid;grid-template-columns:1.45fr .85fr;gap:18px}@media (max-width:1000px){.herorow{grid-template-columns:1fr}}.hero,.mini,.tablewrap,.card{background:linear-gradient(180deg, rgba(11,18,32,.95), rgba(8,14,26,.92));border:1px solid var(--line);border-radius:22px;box-shadow:var(--shadow)}.hero{padding:28px 28px 24px;border-top:2px solid var(--bert2)}.hero h1{font-size:60px;line-height:.97;margin:0 0 18px;font-weight:800;letter-spacing:-.5px}@media (max-width:700px){.hero h1{font-size:40px}}.hero p,.mini p,.card p{color:var(--muted);font-size:15px;line-height:1.55}.chiprow{display:flex;flex-wrap:wrap;gap:8px}.meta-chip,.pill{font-family:var(--mono);font-size:11px;padding:7px 12px;border-radius:999px;border:1px solid var(--line);background:rgba(6,10,18,.4);color:var(--muted)}.side{display:flex;flex-direction:column;gap:14px}.mini{padding:18px}.mini .lbl,.section-note{font-family:var(--mono);font-size:10px;letter-spacing:.18em;text-transform:uppercase;color:var(--bert2)}.mini h3{margin:8px 0 6px;font-size:28px;line-height:1.02}.section{margin-top:34px}.sh{display:flex;justify-content:space-between;align-items:baseline;gap:14px;padding-bottom:10px;border-bottom:1px solid var(--line2);margin-bottom:14px}.sh h2{margin:0;font-size:24px;font-weight:600}.sh .note{font-family:var(--mono);font-size:11px;color:var(--muted2);letter-spacing:.16em;text-transform:uppercase}.kpis{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}@media (max-width:900px){.kpis{grid-template-columns:repeat(2,1fr)}}@media (max-width:640px){.kpis{grid-template-columns:1fr}}.kpi,.card{border:1px solid var(--line);border-radius:16px;padding:16px;background:linear-gradient(180deg, rgba(11,18,32,.85), rgba(8,14,26,.65))}.kpi .v{font-family:var(--mono);font-size:28px;font-weight:700}.kpi .lbl{font-family:var(--mono);font-size:10px;letter-spacing:.18em;text-transform:uppercase;color:var(--muted);margin-top:6px}.kpi .h{font-size:12px;color:var(--muted);line-height:1.45;margin-top:8px}.green{color:var(--bert)}.cyan{color:var(--bert2)}.warn{color:var(--warn)}.plum{color:var(--plum)}.bad{color:var(--bad)}.cards{display:grid;grid-template-columns:repeat(3,1fr);gap:14px}@media (max-width:1000px){.cards{grid-template-columns:1fr}}.card h3{margin:8px 0 8px;font-size:22px}.card .eyebrow{font-family:var(--mono);font-size:10px;letter-spacing:.18em;text-transform:uppercase;color:var(--bert)}table{width:100%;border-collapse:collapse}th,td{padding:13px 14px;text-align:left;font-size:13.5px;vertical-align:top}thead th{font-family:var(--mono);font-size:11px;letter-spacing:.16em;text-transform:uppercase;color:var(--muted2);border-bottom:1px solid var(--line);background:rgba(11,18,32,.5)}tbody tr:hover{background:rgba(55,255,139,.03)}tbody td{color:var(--muted);border-bottom:1px solid var(--line2)}.tablewrap{padding:0;overflow:hidden}.status{display:inline-block;padding:4px 9px;border-radius:6px;border:1px solid currentColor;font-family:var(--mono);font-size:10px;letter-spacing:.1em;text-transform:uppercase}.quote{margin-top:34px;border:1px solid rgba(55,255,139,.22);background:radial-gradient(700px 200px at 0% 0%, rgba(55,255,139,.10), transparent 60%),linear-gradient(180deg, rgba(11,18,32,.92), rgba(8,14,26,.88));border-radius:18px;padding:24px 26px}.quote .lbl{font-family:var(--mono);font-size:11px;color:var(--bert);letter-spacing:.22em;text-transform:uppercase}.quote .q{margin-top:12px;font-size:32px;line-height:1.25;font-weight:600;max-width:1000px}footer{margin-top:30px;padding-top:14px;border-top:1px dashed var(--line2);display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap;font-family:var(--mono);font-size:11px;color:var(--muted2);letter-spacing:.08em}a{color:var(--bert2);text-decoration:none}'

write_page() {
  local path="$1" title="$2" description="$3" canonical="$4" content="$5"
  mkdir -p "$(dirname "$path")"
  cat > "$path" <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title}</title>
  <meta name="description" content="${description}">
  <meta name="robots" content="index,follow">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${description}">
  <meta property="og:type" content="website">
  <meta property="og:url" content="${canonical}">
  <link rel="canonical" href="${canonical}">
  <style>${base_css}</style>
</head>
<body>
  <div class="grid-bg"></div>
  <div class="wrap">
    ${content}
  </div>
</body>
</html>
EOF
}

overview_content="$(cat <<EOF
<div class="topbar"><div class="left">language atlas · shell / bash release surface</div><div class="right"><div>release.kineticgain.com</div><div>platform engineering · launch governance</div></div></div>
<div class="herorow">
  <section class="hero">
    <div class="chiprow"><span class="meta-chip">Bash analysis</span><span class="meta-chip">release preflight</span><span class="meta-chip">rollback posture</span><span class="meta-chip">freeze windows</span></div>
    <h1>Release readiness shell kit for launch pressure, blockers, and rollback posture.</h1>
    <p>A Bash-native operator surface for Platform Engineering teams: score launch windows, blocked dependencies, rollback readiness, and freeze pressure from one portable runbook-oriented analysis path.</p>
    <div class="chiprow"><span class="pill">Route: /release-lane/</span><span class="pill">Route: /preflight-matrix/</span><span class="pill">Route: /rollback-posture/</span></div>
  </section>
  <aside class="side">
    <div class="mini"><div class="lbl">Threads in review</div><h3>${total_threads}</h3><p>Total modeled release threads in the current launch board.</p></div>
    <div class="mini"><div class="lbl">Escalated threads</div><h3>${red_threads}</h3><p>Launches that should hold until rollback or dependency posture improves.</p></div>
    <div class="mini"><div class="lbl">Avg blocked deps</div><h3>${avg_blocked}</h3><p>Average blocked dependency count across the current release queue.</p></div>
  </aside>
</div>
<section class="section"><div class="sh"><h2>Control-plane summary</h2><div class="note">Four KPIs from one Bash analysis path</div></div>
  <div class="kpis">
    <div class="kpi"><div class="v cyan">${total_threads}</div><div class="lbl">Threads</div><div class="h">Modeled release threads inside the shell-run report.</div></div>
    <div class="kpi"><div class="v bad">${red_threads}</div><div class="lbl">Hold posture</div><div class="h">Launches with freeze or rollback blockers that should not ship.</div></div>
    <div class="kpi"><div class="v warn">${yellow_threads}</div><div class="lbl">Conditional ship</div><div class="h">Threads that can ship only if remaining blockers clear in time.</div></div>
    <div class="kpi"><div class="v green">${green_threads}</div><div class="lbl">Clear lanes</div><div class="h">Threads currently fit for launch without further escalation.</div></div>
  </div>
</section>
<section class="section"><div class="sh"><h2>Release thread matrix</h2><div class="note">Blocked deps, rollback readiness, freeze pressure</div></div>
  <div class="tablewrap"><table><thead><tr><th>Service</th><th>Blocked Deps</th><th>Error Budget</th><th>Freeze Active</th><th>Status</th><th>Top Risk</th></tr></thead><tbody>${thread_rows}</tbody></table></div>
</section>
<section class="section"><div class="sh"><h2>Programs to review first</h2><div class="note">Buyer-readable remediation sequence</div></div><div class="cards">${release_cards}</div></section>
<div class="quote"><div class="lbl">Why this matters</div><div class="q">A shell release kit is monetizable when the same Bash analysis can become a preflight template pack, a rollback drill starter, or embedded release-governance support.</div></div>
<footer><div>discipline · platform release operations</div><div>focus · blockers / rollback / freeze posture</div><div>overview snapshot</div></footer>
EOF
)"

release_lane_content="$(cat <<EOF
<div class="topbar"><div class="left">release readiness shell kit · release lane</div><div class="right"><div>platform engineering</div><div>launch review board</div></div></div>
<section class="hero"><h1>Launch threads stay tied to explicit next actions.</h1><p>The release lane keeps dependency drag, error budget, rollback readiness, and freeze pressure visible in one route so teams stop making vague launch calls.</p></section>
<section class="section"><div class="cards">${release_cards}</div></section>
EOF
)"

preflight_content="$(cat <<EOF
<div class="topbar"><div class="left">release readiness shell kit · preflight matrix</div><div class="right"><div>preflight review</div></div></div>
<section class="hero"><h1>Preflight checks stay portable and buyer-readable.</h1><p>This route shows the minimum release facts a platform team can gather in shell: time to window, blocked dependencies, rollback state, and freeze pressure.</p></section>
<section class="section"><div class="tablewrap"><table><thead><tr><th>Service</th><th>Window</th><th>Blocked Deps</th><th>Rollback</th><th>Freeze</th></tr></thead><tbody>${preflight_rows}</tbody></table></div></section>
EOF
)"

rollback_content="$(cat <<EOF
<div class="topbar"><div class="left">release readiness shell kit · rollback posture</div><div class="right"><div>rollback drill packet</div></div></div>
<section class="hero"><h1>Rollback posture and launch action stay auditable.</h1><p>The rollback route shows which threads still need a named rollback owner and which ones can proceed with conditional or full ship posture.</p></section>
<section class="section"><div class="tablewrap"><table><thead><tr><th>Service</th><th>Rollback</th><th>Decision</th><th>Recommended Action</th></tr></thead><tbody>${rollback_rows}</tbody></table></div></section>
EOF
)"

verification_content="$(cat <<EOF
<div class="topbar"><div class="left">release readiness shell kit · verification</div><div class="right"><div>bash only</div></div></div>
<section class="hero"><h1>One Bash analysis path, one static proof surface.</h1><p>The same shell module produces the release analysis, site pages, smoke checks, and README proof assets. No app server is required to validate the operator surface.</p></section>
<section class="section"><div class="cards">
  <div class="card"><div class="eyebrow">Validation</div><h3>Shell runtime</h3><p>Validated with Git Bash demo, tests, site generation, smoke checks, and proof asset render.</p></div>
  <div class="card"><div class="eyebrow">Routes</div><h3>Static proof surface</h3><p>/ · /release-lane/ · /preflight-matrix/ · /rollback-posture/ · /verification/ · /docs/</p></div>
  <div class="card"><div class="eyebrow">Commercial path</div><h3>Templates and consulting</h3><p>Template pack planned, with embedded runbook and release-governance support by engagement.</p></div>
</div></section>
EOF
)"

docs_content="$(cat <<EOF
<div class="topbar"><div class="left">release readiness shell kit · docs</div><div class="right"><div>kinetic gain embedded</div></div></div>
<section class="hero"><h1>Platform release proof for preflight, rollback, and freeze-window operations.</h1><p>This repo sits in the Language Atlas and Industry Atlas at once: real shell, Platform Engineering framing, and a monetizable path into preflight packs, rollback drills, and launch-governance engagements.</p></section>
<section class="section"><div class="cards">
  <div class="card"><div class="eyebrow">Tier 1</div><h3>Public proof</h3><p>Open-source release operator routes generated directly from Bash analysis.</p></div>
  <div class="card"><div class="eyebrow">Tier 2</div><h3>Template pack planned</h3><p>Release preflight and rollback checklists packaged for platform teams.</p></div>
  <div class="card"><div class="eyebrow">Tier 4</div><h3>Embedded by engagement</h3><p>Kinetic Gain can adapt the release kit for a platform team, launch board, or release-control process.</p></div>
</div></section>
EOF
)"

write_page "${SITE_DIR}/index.html" "Release readiness shell kit" "Bash-native platform release operator surface for blockers, rollback posture, and freeze windows." "${BASE_URL}" "${overview_content}"
write_page "${SITE_DIR}/release-lane/index.html" "Release lane · Release readiness shell kit" "Launch board and next-action review for release threads." "${BASE_URL}/release-lane/" "${release_lane_content}"
write_page "${SITE_DIR}/preflight-matrix/index.html" "Preflight matrix · Release readiness shell kit" "Portable Bash preflight posture for launch review." "${BASE_URL}/preflight-matrix/" "${preflight_content}"
write_page "${SITE_DIR}/rollback-posture/index.html" "Rollback posture · Release readiness shell kit" "Rollback readiness and launch decision posture." "${BASE_URL}/rollback-posture/" "${rollback_content}"
write_page "${SITE_DIR}/verification/index.html" "Verification · Release readiness shell kit" "Validation and commercial path for the shell release surface." "${BASE_URL}/verification/" "${verification_content}"
write_page "${SITE_DIR}/docs/index.html" "Docs · Release readiness shell kit" "Platform release documentation and monetization path." "${BASE_URL}/docs/" "${docs_content}"

cat > "${SITE_DIR}/robots.txt" <<EOF
User-agent: *
Allow: /
Sitemap: ${BASE_URL}/sitemap.xml
EOF

cat > "${SITE_DIR}/sitemap.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>${BASE_URL}</loc><lastmod>2026-05-28</lastmod></url>
  <url><loc>${BASE_URL}/release-lane/</loc><lastmod>2026-05-28</lastmod></url>
  <url><loc>${BASE_URL}/preflight-matrix/</loc><lastmod>2026-05-28</lastmod></url>
  <url><loc>${BASE_URL}/rollback-posture/</loc><lastmod>2026-05-28</lastmod></url>
  <url><loc>${BASE_URL}/verification/</loc><lastmod>2026-05-28</lastmod></url>
  <url><loc>${BASE_URL}/docs/</loc><lastmod>2026-05-28</lastmod></url>
</urlset>
EOF

printf 'Generated site at %s\n' "${SITE_DIR}"

