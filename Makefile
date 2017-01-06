# Lists o' targets
RAWGELS := $(notdir $(wildcard rawdata/GelDoc/*.tif))
GELS := $(addprefix data/GelDoc/,$(subst tif,jpg,$(RAWGELS)))

# RAWQPCR = \
# 	rawdata/qpcr/admin_2015-03-19_20-49-05_BR003082_prairie16s-Melt_Curve_RFU_Results_SYBR.csv \
# 	rawdata/qpcr/2015-03-19_platekey.csv \
# 	rawdata/qpcr/admin_2015-04-21_19-36-12_BR003082_Prairie16s-Melt_Curve_RFU_Results_SYBR.csv \
# 	rawdata/qpcr/2015-04-21_platekey.csv

NANODROP = data/nanodrop.csv \
	figs/ctab_yield.pdf 

# QPCR = data/multi_ctab_melt_summary-20150319.csv \
# 	data/multi_ctab_melt_curves-20150319.csv \
# 	data/multi_ctab_melt_distance_ordresults-20150319.txt \
# 	figs/multi_ctab_peakfit-20150319.pdf \
# 	figs/multi_ctab_melt_npeak_tm-20150319.pdf \
# 	figs/multi_ctab_melt_curves-20150319.pdf \
# 	figs/multi_ctab_melt_distance-20150319.pdf \

QPCR = data/multi_ctab_melt_summary-20150421.csv \
	data/multi_ctab_melt_curves-20150421.csv \
	data/multi_ctab_melt_distance_ordresults-20150421.txt \
	figs/multi_ctab_peakfit-20150421.pdf \
	figs/multi_ctab_melt_npeak_tm-20150421.pdf \
	figs/multi_ctab_melt_curves-20150421.pdf \
	figs/multi_ctab_melt_distance-20150421.pdf

TEXTURE = figs/mass_texture.pdf

SEQPLOTS = figs/mock_gen.pdf \
	data/aboveground_abundance.txt \
	figs/agbg_genblock.pdf \
	figs/h2o.pdf \
	figs/spikes.pdf \
	figs/genus_depth.pdf \
	figs/family_depth.pdf \
	figs/ordination.pdf \
	data/adonis_out.txt \
	figs/cooccur_obs_exp.pdf \
	figs/cooccur_effect.pdf

ALL = $(GELS) $(NANODROP) $(QPCR) $(TEXTURE) $(SEQPLOTS)

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

# FIXME: All the qpcr scripts contain hardcoded output paths 
# These are currently set to write the 2015-04-21 files; 
# to run 2014-03-19 files either change paths everywhere and change which blocks are commented in the Makefile
#  or better yet FIXME FIXME FIXME.

# data/multi_ctab_melt_summary-20150319.csv \
# 	data/multi_ctab_melt_curves-20150319.csv \
# 	figs/multi_ctab_peakfit-20150319.pdf: \
# 		R/qpcr_curve.R \
# 		rawdata/qpcr/admin_2015-03-19_20-49-05_BR003082_prairie16s-Melt_Curve_RFU_Results_SYBR.csv \
# 		rawdata/qpcr/2015-03-19_platekey.csv
# 	Rscript $^

data/multi_ctab_melt_summary-20150421.csv \
	data/multi_ctab_melt_curves-20150421.csv \
	figs/multi_ctab_peakfit-20150421.pdf: \
		R/qpcr_curve.R \
		rawdata/qpcr/admin_2015-04-21_19-36-12_BR003082_Prairie16s-Melt_Curve_RFU_Results_SYBR.csv \
		rawdata/qpcr/2015-04-21_platekey.csv
	Rscript $^

# figs/multi_ctab_melt_npeak_tm-20150319.pdf: \
# 		R/plot_melt_summary.R \
# 		data/multi_ctab_melt_summary-20150319.csv
# 	Rscript $^

figs/multi_ctab_melt_npeak_tm-20150421.pdf: \
		R/plot_melt_summary.R \
		data/multi_ctab_melt_summary-20150421.csv
	Rscript $^

# figs/multi_ctab_melt_curves-20150319.pdf: \
# 		R/plot_melt_curve.R \
# 		data/multi_ctab_melt_curves-20150319.csv
# 	Rscript $^

figs/multi_ctab_melt_curves-20150421.pdf: \
		R/plot_melt_curve.R \
		data/multi_ctab_melt_curves-20150421.csv
	Rscript $^

# figs/multi_ctab_melt_distance-20150319.pdf data/multi_ctab_melt_distance_ordresults-20150319.txt: \
# 		R/plot_melt_distance.R \
# 		data/multi_ctab_melt_curves-20150319.csv
# 	Rscript $^

figs/multi_ctab_melt_distance-20150421.pdf data/multi_ctab_melt_distance_ordresults-20150421.txt: \
		R/plot_melt_distance.R \
		data/multi_ctab_melt_curves-20150421.csv
	Rscript $^

figs/mass_texture.pdf: R/plot_texture.R rawdata/giddings_rootmass.csv rawdata/soil_properties_2008.csv
		Rscript R/plot_texture.R

$(SEQPLOTS): R/plot_seqs.R \
		rawdata/bulk_CN.csv \
		data/plant_its2_otu/plant_its2_99.biom \
		rawdata/vouchers/root_voucher_fate.csv \
		rawdata/vouchers/accepted_names.csv \
		private/Xiaohui_species_comp/surveys_clean.csv
	Rscript R/plot_seqs.R
