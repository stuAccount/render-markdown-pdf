# Markdown-to-PDF Contract (Pandoc + XeLaTeX)

Use this checklist before rendering.

## Build Command

```bash
pandoc input.md -o output.pdf -d defaults.yaml
```

`defaults.yaml` in this skill sets:
- `pdf-engine: xelatex`
- `filters: [full-width-tables.lua]`

## Table Rules

- Use standard pipe-table Markdown.
- Put the caption immediately after the table:
  `Table: <caption>`
- Keep one blank line after the caption.
- Use alignment markers in header separator rows:
  - `:---` left
  - `:---:` center
  - `---:` right

## Image Rules

- Keep image paths relative and under `images/`:
  `![Figure title](images/example.png)`
- Keep one blank line above and below each image line.
- Keep image syntax on its own line.

## List Rules

- Use numbered lists as `1.`, `2.`, `3.`.
- Use unordered lists with `-` only.
- Keep one blank line before every list block.
- Use 4 spaces or 1 tab for nested list indentation.

## Code Block Rules

- Use triple backticks for fenced blocks.
- Always specify a language label after opening backticks.
- Keep one blank line before and after each fenced block.

## Toolchain Recovery

- Install Pandoc if missing:
  `brew install pandoc`
- If `command -v xelatex` fails, still run `scripts/render_pdf.sh` once; it retries common MacTeX paths.
- If `scripts/render_pdf.sh` still reports missing `xelatex`, ask user to install manually (do not auto-install):
  `brew install --cask mactex-no-gui`
- Refresh PATH after MacTeX install:
  `eval "$(/usr/libexec/path_helper)"`
- Install Eisvogel template if needed:

```bash
mkdir -p ~/.local/share/pandoc/templates
curl -L https://github.com/Wandmalfarbe/pandoc-latex-template/releases/latest/download/Eisvogel.tar.gz \
  | tar -xz -C ~/.local/share/pandoc/templates/
```

## Diagram and Output Images

- Use Mermaid CLI (`mmdc`) for flowchart images.
- Use `carbon-now-cli` (`carbon-now`) for execution-output screenshots.
- Confirm command flags with local `--help` because CLI options vary by version.
