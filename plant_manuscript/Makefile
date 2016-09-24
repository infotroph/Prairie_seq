# inputs
MARKDOWN = \
	title.md \
	intro.md \
	methods.md \
	results.md \
	ref_dummy.md \
	figures.md

#	abstract.md \
	keywords.md \
	discussion.md \
	acknowledgements.md \
	priors.md \
	figures_supplement.md

BIBFILE = prairie_root.bib
BIBSTYLE = style/ecology.csl
REFDOCX = style/delucia-style.docx

CROSSREFMETA = \
	-M chapters:True \
	-M chaptersDepth:1 \
	-M chapDelim:"" \
	-M chapPrefix:""

FIGURES = figures/*.png

# outputs
ALL = ckbprairie.docx

# rules
all: $(ALL)

.phony: all

filters/pandoc-word-sectionbreak: filters/pandoc-word-sectionbreak.hs
	ghc --make $^ -o $@

ckbprairie.docx: $(MARKDOWN) $(BIBFILE) $(BIBSTYLE) $(REFDOCX) $(FIGURES) \
		filters/pandoc-word-sectionbreak filters/unmathsub.py
	pandoc -s -S \
		--filter filters/pandoc-word-sectionbreak \
		--filter pandoc-crossref \
		-f markdown+implicit_figures \
		--bibliography $(BIBFILE) \
		--csl $(BIBSTYLE) \
		$(CROSSREFMETA) \
		$(MARKDOWN) \
		-t native | pandoc - \
			-f native \
			--filter filters/unmathsub.py \
			--reference-docx $(REFDOCX) \
			-o $@
