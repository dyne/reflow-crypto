# run latex enough times to iterate over bibtex
all:
	pdflatex multidarkroom
	bibtex multidarkroom
	pdflatex multidarkroom
	pdflatex multidarkroom


# docker pull minlag/mermaid-cli
mermaid = docker run --rm -v=${PWD}:/app/data minlag/mermaid-cli -w 2048 -H 1536 -i /app/data/$(1) -o /app/data/$(2)
mermaid:
	mkdir -p data
	$(call mermaid,keygen.mmd,keygen-seq.png)
	$(call mermaid,sign.mmd,sign-seq.png)
	$(call mermaid,verify.mmd,verify-seq.png)

clean:
	rm -f *blg *bbl *dvi *pdf *toc *out *aux *log *-seq.png
