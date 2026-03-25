---
name: render-markdown-pdf
description: Render Markdown documents to PDF with Pandoc + XeLaTeX (including Eisvogel and full-width table filtering). Use when creating or debugging `.md` to `.pdf` output that depends on strict spacing-sensitive formatting rules for lists, images, code blocks, table captions, deep heading layout, and heterogeneous CJK tables.
---

# Render Markdown PDF

Run this workflow to produce reliable PDF output from Markdown with the rendering stack used in this project.

## Core Workflow

1. Ensure the Markdown contains the pre-written frontmatter preamble from **Required Templates**.
2. Ensure the Lua filter file matches the bundled version from **Required Templates**.
3. Run `scripts/markdown_preflight.py <input.md>` before rendering.
4. Run `scripts/render_pdf.sh <input.md> [output.pdf]`.
5. If you are modifying the skill itself, run `scripts/check_regressions.sh`.
6. If rendering fails, follow troubleshooting in `references/format-rules.md`.

## Required Templates (Must Include for Rendering)

Reuse the bundled template files verbatim. They are the supported baseline for heading layout, CJK fonts, and full-width table handling.

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
  \usepackage{titlesec}
  
  \IfFontExistsTF{DejaVu Sans}{
    \setmainfont[Scale=0.9]{DejaVu Sans}
  }{
    \IfFontExistsTF{Helvetica Neue}{
      \setmainfont[Scale=0.9]{Helvetica Neue}
    }{
      \setmainfont[Scale=0.9]{Arial}
    }
  }
  \IfFontExistsTF{PingFang SC}{
    \setCJKmainfont{PingFang SC}
  }{
    \setCJKmainfont{Songti SC}
  }
  \IfFontExistsTF{Menlo}{
    \setmonofont[Scale=0.9]{Menlo}
  }{
    \setmonofont[Scale=0.9]{Courier New}
  }

  \titleformat{\paragraph}[block]{\normalfont\normalsize\bfseries}{}{0pt}{}
  \titlespacing*{\paragraph}{0pt}{1.2ex plus .2ex minus .1ex}{0.8ex}
  \titleformat{\subparagraph}[block]{\normalfont\normalsize\bfseries}{}{0pt}{}
  \titlespacing*{\subparagraph}{0pt}{1.2ex plus .2ex minus .1ex}{0.8ex}

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
  \apptocmd{\tableofcontents}{\clearpage}{}{}
  \usepackage{longtable}
  \usepackage{array}
  
  \setlength{\LTleft}{0pt}
  \setlength{\LTright}{0pt}
  \setlength{\tabcolsep}{8pt}
  \renewcommand{\arraystretch}{1.5}
  
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

Use the bundled Lua filter at `assets/pandoc/full-width-tables.lua` verbatim.

- It preserves explicit Pandoc column width ratios by normalizing them to full text width.
- When width metadata is absent, it samples the header and first body rows, then allocates width by visible content length and column type.
- It keeps alignment unchanged.
- It is designed to make ordinary pipe tables work without relying on `\shortstack`, `\raisebox`, or `\parbox` hacks in table cells.

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

- Deep headings such as `####` and `#####` are supported in this skill because the template remaps `\paragraph` / `\subparagraph` to block headings.
- Table caption line immediately after each table: `Table: ...`, then one blank line.
- Prefer normal Markdown table cells. Do not default to raw TeX hacks like `\shortstack`, `\raisebox`, or `\parbox`.
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
set `RESOURCE_PATH` (or a defaults override with `resource-path`) so Pandoc can still resolve them correctly.

## Mermaid and Output Screenshots

- Generate flowcharts with Mermaid CLI (`mmdc`).
- Generate execution-result images with `carbon-now-cli` (`carbon-now`).
- If either tool is missing, ask the user before installing global npm tooling.

## Bundled Resources

- `assets/pandoc/defaults.yaml`: Pandoc defaults (`pdf-engine: xelatex`, `full-width-tables.lua` filter).
- `assets/pandoc/full-width-tables.lua`: Lua filter that keeps tables full-width while preserving explicit widths or assigning content-aware widths for heterogeneous tables.
- `assets/pandoc/doc_template.md`: Reference frontmatter for Eisvogel + XeLaTeX + CJK settings, including stable deep heading layout.
- `scripts/markdown_preflight.py`: Validates formatting rules that commonly break Pandoc rendering and emits warnings for risky table patterns.
- `scripts/render_pdf.sh`: Runs preflight checks, applies resource-path defaults, and renders PDF.
- `scripts/check_regressions.sh`: Renders bundled regression fixtures and checks heading / table layout regressions.
- `examples/regressions/`: Smoke and regression fixtures for headings, heterogeneous tables, and general CJK reports.
- `references/format-rules.md`: Rule reference and troubleshooting checklist.

## Troubleshooting Highlights

- If a `####` or deeper heading appears on the same line as the next paragraph, verify the document is using the bundled template or equivalent `titlesec` overrides.
- If IP, port, Seq/Ack, and remark columns all look squeezed or visually misaligned, avoid hand-tuned TeX in cells first; use the bundled Lua filter and inspect the rendered PDF before adding manual workarounds.
