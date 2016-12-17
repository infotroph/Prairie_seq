# inputs
MARKDOWN = \
	title.md \
	abstract.md \
	intro.md \
	methods.md \
	results.md \
	discussion.md \
	acknowledgements.md \
	ref_dummy.md \
	species_table.md \
	figures.md \
	supp_dummy.md \
	figures_supplement.md

BIBFILE = prairie_root.bib
BIBSTYLE = style/new-phytologist.csl
REFDOCX = style/newphyt-style.docx

CROSSREFMETA = \
	-M chapters:True \
	-M chaptersDepth:1 \
	-M chapDelim:"" \
	-M chapPrefix:"" \
	-M figureTitle:"Fig." \
	-M tableTitle:"Table" \
	-M tblPrefix:"Table" \
	-M figPrefix:"Fig."

FIGURES = ../figs/mass_texture.pdf \
	../figs/agbg_genblock.pdf \
	../figs/family_depth.pdf \
	../figs/ordination.pdf \
	../figs/h2o.pdf \
	../figs/mock_gen.pdf \
	../figs/spikes.pdf \
	../figs/genus_depth.pdf \
	../figs/cooccur_obs_exp.pdf \
	../figs/cooccur_effect.pdf

# outputs
ALL = ckbprairie.docx

# rules
all: $(ALL)

.phony: all

filters/pandoc-word-sectionbreak: filters/pandoc-word-sectionbreak.hs
	ghc --make $^ -o $@

ckbprairie.docx: $(MARKDOWN) $(BIBFILE) $(BIBSTYLE) $(REFDOCX) $(FIGURES) \
		wordcount.sh filters/pandoc-word-sectionbreak filters/unmathsub.py
	cp title.md .title_maketmp.md
	./wordcount.sh >> .title_maketmp.md
	pandoc -s -S \
		--filter filters/pandoc-word-sectionbreak \
		--filter pandoc-crossref \
		--filter pandoc-citeproc \
		--filter filters/unmathsub.py \
		-f markdown+implicit_figures \
		--bibliography $(BIBFILE) \
		--csl $(BIBSTYLE) \
		--reference-docx $(REFDOCX) \
		$(CROSSREFMETA) \
		`echo $(MARKDOWN)|sed 's/title.md/.title_maketmp.md/'` \
		-o $@
	rm .title_maketmp.md
