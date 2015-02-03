# Lists o' targets.
RAWGELS := $(notdir $(wildcard rawdata/GelDoc/*.tif))
GELS := $(addprefix data/GelDoc/,$(subst tif,jpg,$(RAWGELS)))
NANODROP = data/nanodrop.csv
ALL = $(GELS) $(NANODROP)

# phony rules to let us build subsets by themselves
all: $(ALL)
nandrop: $(NANODROP)
gels: $(GELS)
clean: rm $(ALL)
.PHONY: all gels nanodrop clean 

# Now for the rules that actually build things
data/GelDoc/%.jpg: Python/gel-labeler.py rawdata/GelDoc/%.tif rawdata/GelDoc/%.csv
	./$^ $@

data/nanodrop.csv: R/nanodrop_clean.R rawdata/nanodrop/*.txt
	Rscript $^
