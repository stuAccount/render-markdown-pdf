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
