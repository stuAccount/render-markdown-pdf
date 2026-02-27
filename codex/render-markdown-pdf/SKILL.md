---
name: render-markdown-pdf
description: Render Markdown documents to PDF with Pandoc + XeLaTeX (including Eisvogel and full-width table filtering). Use when creating or debugging `.md` to `.pdf` output that depends on strict spacing-sensitive formatting rules for lists, images, code blocks, and table captions.
---

# Render Markdown PDF

Run this workflow to produce reliable PDF output from Markdown with the rendering stack used in this project.

## Core Workflow

1. Ensure the Markdown contains the pre-written frontmatter preamble from **Required Templates**.
2. Ensure the Lua filter file matches the template from **Required Templates**.
3. Run `scripts/markdown_preflight.py <input.md>` before rendering.
4. Run `scripts/render_pdf.sh <input.md> [output.pdf]`.
5. If rendering fails, follow troubleshooting in `references/format-rules.md`.

## Required Templates (Must Include for Rendering)

The following two templates are mandatory in this workflow and should be copy-paste ready.

### 1) Pre-written Markdown Preamble (frontmatter)

```yaml
---
title: "title"
author: "author"
date: "date"
template: eisvogel
pdf-engine: xelatex
lang: zh-CN
titlepage: true
titlepage-color: "006699"
titlepage-text-color: "FFFFFF"
toc: true
toc-own-page: true
geometry: "top=2.5cm, bottom=3.5cm, left=3cm, right=2.5cm"
header-includes: |
  \usepackage{xeCJK}
  \usepackage{fontspec}
  
  \setmainfont[Scale=0.9]{DejaVu Sans}
  \setCJKmainfont{PingFang SC}
  \setmonofont[Scale=0.9]{Menlo}

  \usepackage{float}
  \let\origfigure\figure
  \let\endorigfigure\endfigure
  \renewenvironment{figure}[1][]{%
    \origfigure[H]
    \centering
  }{%
    \endorigfigure
  }

  \usepackage{caption}
  \captionsetup{margin=20pt, font=small, labelfont=bf, labelsep=endash, skip=10pt}

  
  \usepackage{fvextra}
  \fvset{breaklines=true, breakanywhere=true}
  
  \usepackage{xurl}
  \usepackage[strings]{underscore}
  
  \usepackage{etoolbox}
  \usepackage{longtable}
  \usepackage{array}
  
  \setlength{\LTleft}{0pt}
  \setlength{\LTright}{0pt}
  \setlength{\tabcolsep}{12pt}
  \renewcommand{\arraystretch}{1.8}
  
  \AtBeginEnvironment{longtable}{
    \small
  }
  \setlength{\LTpre}{10pt}
  \setlength{\LTpost}{10pt}
  
  \usepackage{listings}
  \lstset{
    breaklines=true,
    breakatwhitespace=false,
    basicstyle=\ttfamily\small,
    columns=flexible,
  }
---
```

### 2) Pre-written Lua Filter Template (`assets/pandoc/full-width-tables.lua`)

```lua
-- Lua filter to force all tables to use full textwidth
-- by converting column specs to proportional widths

function Table(tbl)
  -- Get number of columns
  local num_cols = #tbl.colspecs
  
  if num_cols == 0 then
    return tbl
  end
  
  -- Calculate equal width for each column (proportional)
  local width = 1.0 / num_cols
  
  -- Replace all column specs with proportional width
  for i = 1, num_cols do
    local align = tbl.colspecs[i][1]  -- Keep original alignment
    tbl.colspecs[i] = {align, width}  -- Set proportional width
  end
  
  return tbl
end
```

## Toolchain Checks (Mandatory)

Run this check first:

```bash
command -v pandoc
```

- If `pandoc` is missing, ask user to install it:
  `brew install pandoc`
- Run `scripts/render_pdf.sh` even if `command -v xelatex` fails in the current shell.
  The script retries common MacTeX paths (`/Library/TeX/texbin`, `/usr/texbin`) before failing.
- If the script still reports missing `xelatex`, do not install automatically. Ask the user to install MacTeX manually because it is large:
  `brew install --cask mactex-no-gui`
- After install, ask user to refresh PATH:
  `eval "$(/usr/libexec/path_helper)"`

If Markdown frontmatter uses `template: eisvogel`, verify template presence at:
`~/.local/share/pandoc/templates/eisvogel.latex`

If missing, ask user to install it:

```bash
mkdir -p ~/.local/share/pandoc/templates
curl -L https://github.com/Wandmalfarbe/pandoc-latex-template/releases/latest/download/Eisvogel.tar.gz \
  | tar -xz -C ~/.local/share/pandoc/templates/
```

## Markdown Rules

Apply the required Markdown contract in `references/format-rules.md`. Enforce:

- Table caption line immediately after each table: `Table: ...`, then one blank line.
- Image lines as standalone Markdown image syntax, path under `images/`, with one blank line above and below.
- A blank line before every list block (critical for Pandoc parsing).
- Fenced code blocks using triple backticks with explicit language and blank lines before/after.

## Rendering Command

Use the project command:

```bash
pandoc input.md -o output.pdf -d defaults.yaml
```

Use `scripts/render_pdf.sh` to run this safely with bundled defaults and checks.

If images are under `images/` relative to the document, but rendering is launched from another directory,
set a defaults override with `resource-path` and pass it with `DEFAULTS_FILE`.

## Mermaid and Output Screenshots

- Generate flowcharts with Mermaid CLI (`mmdc`).
- Generate execution-result images with `carbon-now-cli` (`carbon-now`).
- If either tool is missing, ask the user before installing global npm tooling.

## Bundled Resources

- `assets/pandoc/defaults.yaml`: Pandoc defaults (`pdf-engine: xelatex`, `full-width-tables.lua` filter).
- `assets/pandoc/full-width-tables.lua`: Lua filter that makes table columns proportional to full text width.
- `assets/pandoc/doc_template.md`: Reference frontmatter for Eisvogel + XeLaTeX + CJK settings.
- `scripts/markdown_preflight.py`: Validates formatting rules that commonly break Pandoc rendering.
- `scripts/render_pdf.sh`: Runs preflight dependency checks and renders PDF.
- `references/format-rules.md`: Rule reference and troubleshooting checklist.
