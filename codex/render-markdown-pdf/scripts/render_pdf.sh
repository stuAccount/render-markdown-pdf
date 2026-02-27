#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  render_pdf.sh <input.md> [output.pdf]

Description:
  Render Markdown to PDF with pandoc defaults bundled in this skill.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 1
fi

input_path="$1"
output_path="${2:-}"

if [[ ! -f "$input_path" ]]; then
  echo "[error] Input file not found: $input_path" >&2
  exit 1
fi

if [[ -z "$output_path" ]]; then
  stem="${input_path%.*}"
  if [[ "$stem" == "$input_path" ]]; then
    stem="$input_path"
  fi
  output_path="${stem}.pdf"
fi

if ! command -v pandoc >/dev/null 2>&1; then
  cat >&2 <<'EOF'
[error] pandoc is not installed.
Install it manually:
  brew install pandoc
EOF
  exit 127
fi

# Some shells (including app sandboxes) may not include TeX paths by default.
if ! command -v xelatex >/dev/null 2>&1; then
  if [[ -x /Library/TeX/texbin/xelatex ]]; then
    export PATH="/Library/TeX/texbin:$PATH"
  elif [[ -x /usr/texbin/xelatex ]]; then
    export PATH="/usr/texbin:$PATH"
  fi
fi

if ! command -v xelatex >/dev/null 2>&1; then
  cat >&2 <<'EOF'
[error] xelatex is not available.
MacTeX is large, so do not auto-install it. Ask the user to install it manually:
  brew install --cask mactex-no-gui
Then refresh PATH:
  eval "$(/usr/libexec/path_helper)"
Re-run this command after installation.
EOF
  exit 127
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"
defaults_file="${DEFAULTS_FILE:-$skill_dir/assets/pandoc/defaults.yaml}"

if [[ ! -f "$defaults_file" ]]; then
  echo "[error] defaults file not found: $defaults_file" >&2
  exit 1
fi

if grep -Eq '^[[:space:]]*template:[[:space:]]*["'"'"']?eisvogel["'"'"']?[[:space:]]*$' "$input_path"; then
  if [[ ! -f "$HOME/.local/share/pandoc/templates/eisvogel.latex" ]]; then
    cat >&2 <<'EOF'
[error] Eisvogel template requested by input markdown but not found.
Install manually:
  mkdir -p ~/.local/share/pandoc/templates
  curl -L https://github.com/Wandmalfarbe/pandoc-latex-template/releases/latest/download/Eisvogel.tar.gz \
    | tar -xz -C ~/.local/share/pandoc/templates/
EOF
    exit 127
  fi
fi

output_dir="$(dirname "$output_path")"
mkdir -p "$output_dir"

input_abs="$(cd "$(dirname "$input_path")" && pwd)/$(basename "$input_path")"
output_abs="$(cd "$output_dir" && pwd)/$(basename "$output_path")"
defaults_dir="$(cd "$(dirname "$defaults_file")" && pwd)"
defaults_name="$(basename "$defaults_file")"

(
  cd "$defaults_dir"
  pandoc "$input_abs" -o "$output_abs" -d "$defaults_name"
)

echo "[ok] Rendered PDF: $output_abs"
