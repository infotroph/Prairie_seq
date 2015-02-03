
RAWGELS := $(notdir $(wildcard rawdata/GelDoc/*.tif))
GELS := $(addprefix data/GelDoc/,$(subst tif,jpg,$(RAWGELS)))

gels: $(GELS)

data/GelDoc/%.jpg: Python/gel-labeler.py rawdata/GelDoc/%.tif rawdata/GelDoc/%.csv
	./$^ $@

data/nanodrop.csv: R/nanodrop_clean.R rawdata/nanodrop/*.txt
	Rscript $^

all: gels 

.PHONY: all gels clean 
clean: rm $(ALL)