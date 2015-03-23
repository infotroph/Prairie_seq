# Lists o' targets
RAWGELS := $(notdir $(wildcard rawdata/GelDoc/*.tif))
GELS := $(addprefix data/GelDoc/,$(subst tif,jpg,$(RAWGELS)))

RAWQPCR = \
	rawdata/qpcr/admin_2015-03-19_20-49-05_BR003082_prairie16s-Melt_Curve_RFU_Results_SYBR.csv \
	rawdata/qpcr/2015-03-19_platekey.csv

NANODROP = data/nanodrop.csv \
	figs/ctab_yield.pdf 

QPCR = data/multi_ctab_melt_summary.csv \
	data/multi_ctab_melt_curves.csv \
	data/multi_ctab_melt_distance_ordresults.txt \
	figs/multi_ctab_peakfit.pdf \
	figs/multi_ctab_melt_npeak_tm.pdf \
	figs/multi_ctab_melt_curves.pdf \
	figs/multi_ctab_melt_distance.pdf

ALL = $(GELS) $(NANODROP) $(QPCR)

# Phony rules to let us build subsets by themselves
all: $(ALL)
nanodrop: $(NANODROP)
gels: $(GELS)
qpcr: $(QPCR)
clean: rm $(ALL)
.PHONY: all gels nanodrop qpcr clean 

# Now for the rules that actually build things
data/GelDoc/%.jpg: \
		Python/gel-labeler.py \
		rawdata/GelDoc/%.tif \
		rawdata/GelDoc/%.csv
	./$^ $@

data/nanodrop.csv: \
		R/nanodrop_clean.R \
		rawdata/nanodrop/*.txt \
		rawdata/nanodrop/nanodrop_corrections.csv
	Rscript R/nanodrop_clean.R rawdata/nanodrop/*.txt

figs/ctab_yield.pdf: \
		R/ctab_yield.R \
		data/nanodrop.csv 
	Rscript $^

data/multi_ctab_melt_summary.csv \
	data/multi_ctab_melt_curves.csv \
	figs/multi_ctab_peakfit.pdf: \
		R/qpcr_curve.R \
		$(RAWQPCR)
	Rscript $^

figs/multi_ctab_melt_npeak_tm.pdf: \
		R/plot_melt_summary.R \
		data/multi_ctab_melt_summary.csv
	Rscript $^

figs/multi_ctab_melt_curves.pdf: \
		R/plot_melt_curve.R \
		data/multi_ctab_melt_curves.csv
	Rscript $^

figs/multi_ctab_melt_distance.pdf data/multi_ctab_melt_distance_ordresults.txt: \
		R/plot_melt_distance.R \
		data/multi_ctab_melt_curves.csv
	Rscript $^