
# Latex setup description

The project hosts an aesthetic and simple LaTeX style suitable for "preprint" publications such as arXiv and bio-arXiv, etc. 
It is based on the [**nips_2018.sty**](https://media.nips.cc/Conferences/NIPS2018/Styles/nips_2018.sty) style, with many changes to support dual column, Lua and Zencode syntaxt highlight, stylish tables and some more features visible in the reflow paper.

## Dependencies

On a Devuan 3.1 Beowulf:

- texlive-extra-utils
- texlive-fonts-extra
- texlive-latex-extra
- texlive-generic-extra

Docker is needed for mermaidjs rendering to file.

## Build

- make mermaid
- make

## Usage
1. Use Document class **article**. 
2. Copy **arxiv.sty** to the folder containing your tex file.
3. add `\usepackage{arxiv}` after `\documentclass{article}`.
4. The only packages used in the style file are **geometry** and **fancyheader**. Do not reimport them.

See **template.tex** 

## Project files:
1. **arxiv.sty** - the style file.
2. **reflow.tex** - article that uses the **arxiv style**.
3. **references.bib** - the bibliography source file for reflow.tex.
4. **reflow.pdf** - the output of the reflow article in arxiv style.


## Handling References when submitting to arXiv.org
The most convenient way to manage references is using an external BibTeX file and pointing to it from the main file. 
However, this requires running the [bibtex](http://www.bibtex.org/) tool to "compile" the `.bib` file and create `.bbl` file containing "bibitems" that can be directly inserted in the main tex file. 
However, unfortunately the arXiv Tex environment ([Tex Live](https://www.tug.org/texlive/)) do not do that. 
So easiest way when submitting to arXiv is to create a single self-contained .tex file that contains the references.
This can be done by running the BibTeX command on your machine and insert the content of the generated `.bbl` file into the `.tex` file and commenting out the `\bibliography{references}` that point to the external references file.

Below are the commands that should be run in the project folder:
1. Run `$ latex template`
2. Run `$ bibtex template`
3. A `template.bbl` file will be generated (make sure it is there)
4. Copy the `template.bbl` file content to `template.tex` into the `\begin{thebibliography}` command.
5. Comment out the `\bibliography{references}` command in `template.tex`.
6. You ready to submit to arXiv.org.


## General Notes:
1. This Latex setup is based on work by kourgeorge/at/gmail.com and extended by jaromil/at/dyne.org
2. If you start another project based on this project, one needs to mention/link to this project.
3. Another good looking 2 column template can be found in https://github.com/brenhinkeller/preprint-template.tex.
