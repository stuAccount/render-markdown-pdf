#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"
template_file="$skill_dir/assets/pandoc/doc_template.md"
defaults_file="$skill_dir/assets/pandoc/defaults.yaml"
preflight_script="$script_dir/markdown_preflight.py"
render_script="$script_dir/render_pdf.sh"
fixtures_dir="$skill_dir/examples/regressions"
defaults_dir="$(cd "$(dirname "$defaults_file")" && pwd)"
defaults_name="$(basename "$defaults_file")"
resource_path="$fixtures_dir:$fixtures_dir/images:$skill_dir"

usage() {
  cat <<'EOF'
Usage:
  check_regressions.sh

Description:
  Render bundled regression fixtures and check for heading/table layout regressions.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

for cmd in python3 pandoc pdftotext; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[error] Missing required command for regression checks: $cmd" >&2
    exit 127
  fi
done

if [[ ! -f "$template_file" ]]; then
  echo "[error] Missing template file: $template_file" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

compose_fixture() {
  local fixture_path="$1"
  local composed_path="$2"

  cat "$template_file" > "$composed_path"
  printf '\n' >> "$composed_path"
  cat "$fixture_path" >> "$composed_path"
}

render_fixture() {
  local fixture_name="$1"
  local fixture_path="$fixtures_dir/$fixture_name"
  local stem="${fixture_name%.md}"
  local composed_path="$tmp_dir/${stem}.composed.md"
  local output_pdf="$tmp_dir/${stem}.pdf"

  python3 "$preflight_script" "$fixture_path"
  compose_fixture "$fixture_path" "$composed_path"
  RESOURCE_PATH="$resource_path" "$render_script" "$composed_path" "$output_pdf"
}

render_fixture "headings_runin_regression.md"
render_fixture "heterogeneous_table_regression.md"
render_fixture "cjk_report_smoke.md"

headings_txt="$tmp_dir/headings_runin_regression.txt"
pdftotext "$tmp_dir/headings_runin_regression.pdf" "$headings_txt"

python3 - "$headings_txt" <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="ignore").replace("\r\n", "\n")
checks = [
    (r"3\.\s*RTT\s*与吞吐量测量", r"根据抓包时间戳："),
    (r"5\.\s*问题回答", r"问题\s*3："),
]

for heading_pattern, paragraph_pattern in checks:
    same_line = re.search(
        heading_pattern + r"[^\n]*" + paragraph_pattern,
        text,
    )
    if same_line:
        raise SystemExit(
            "heading regression: heading and following paragraph were extracted on the same line"
        )

    separated = re.search(
        heading_pattern + r"\s*\n\s*" + paragraph_pattern,
        text,
    )
    if not separated:
        raise SystemExit(
            "heading regression: expected a line break between heading and following paragraph"
        )
PY

table_source="$tmp_dir/heterogeneous_table_regression.composed.md"
table_tex="$tmp_dir/heterogeneous_table_regression.tex"
(
  cd "$defaults_dir"
  pandoc "$table_source" -t latex -o "$table_tex" -d "$defaults_name" --resource-path="$resource_path"
)

python3 - "$table_tex" <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="ignore")
match = re.search(r"\\begin\{longtable\}.*?\\end\{longtable\}", text, re.S)
if not match:
    raise SystemExit("table regression: failed to locate longtable block in generated LaTeX")

block = match.group(0)
widths = re.findall(r"\\real\{([0-9.]+)\}", block)
if len(widths) < 2:
    widths = re.findall(r"([0-9]+\.[0-9]+)\s*\\(?:line|column)width", block)

if len(widths) < 2:
    raise SystemExit("table regression: failed to extract multiple column widths from generated LaTeX")

rounded = {round(float(width), 4) for width in widths}
if len(rounded) == 1:
    raise SystemExit("table regression: generated LaTeX still uses equal-width columns")
PY

echo "[ok] Regression checks passed"
