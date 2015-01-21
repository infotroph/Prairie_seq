
RAWGELS := $(notdir $(wildcard rawdata/GelDoc/*.tif))
GELS := $(addprefix data/GelDoc/,$(subst tif,jpg,$(RAWGELS)))

gels: $(GELS)

data/GelDoc/%.jpg: rawdata/GelDoc/%.tif rawdata/GelDoc/%.csv
	./Python/gel-labeler.py $^ $@


all: gels 

.PHONY: all gels clean 
clean: rm $(ALL)