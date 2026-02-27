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

