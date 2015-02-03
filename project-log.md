Project log for the EBI prairie root sequencing project
===================================================

Started 2015-01-20 by CKB after project was well underway. For notes on previous steps, see paper lab notebook.

##Rules:

* This log is append-only, except when something earlier is wrong enough to warrant a correction, in which case the dated correction is INSERTED immediately after the error, with the original text left in place. 
* All entries start with date and author's initials.
* Try to include plenty of "why" in your entries--you'll end up documenting the "what" and "how" pretty well elsewhere, but this log is the first place to look when you see some previous work and say "What was I thinking? _Why_ did I do _that_?!" 
* Update as copiously or as tersely as you like, but update _as you work_ and don't pretend you'll come back to fill details "soon."

## 2015-01-20, CKB

Consulted with SAW on which controls we need for extraction, PCR, sequencing. Same approach I outlined in notes/controls.txt, details on PCR and sequencing to come later. Strategy for quantifying extraction efficiency: 3-4 replicate extractions of each root voucher with varying amounts tissue, regress mg tissue against Nanodrop yield. Take maybe the three highest- and three lowest-yielding species, make a FEW two-species root tissue spike-ins (e.g. a 15 mg sp. A, 15 mg sp B and a 25 A/5 B ) to show that total DNA recovery from mixtures is similar to what's expected from same amounts of tissue extracted in separate tubes. If spike-in yield is OK from a few pairs of species with very different DNA yields per mg root, seems reasonable to assume it's also OK from untested pairs whose DNA yield is similar to each other. 

First pass at a script to convert gel images from linear-gamma tiff (i.e. completely black on my screen) to correct-gamma jpegs with automated lane annotation. 

Idea behind automated gel annotation system: For each gel image, we will store two files in the same directory. One is the raw tiff image exported from GelDoc, and the and other is a CSV with at least the following columns, named exactly as follows, all in lowercase:

* "lane" is lane number within this row of the gel, starting from the left edge.
* "row" is row number, starting from the top. This column is mandatory even if the gel only has one row of wells, in which case it will always be 1. 
* "id" is the string you want printed above that gel in the exported image. Probably ought to be <10 characters. 
* any other columns will be ignored by the annotation script, but I encourage at least a "remarks" column for any further notes on each sample, and perhaps a "full ID" column if the correct name of the sample is too long to fit in "id".

Unresolved question: Where to store other metadata about the gel (agarose concentration, batch of samples, run voltage and time...)? Considered using comment lines in the CSV, but Python's csv module doesn't provide a convenient implementation of comment filtering. May return to this later; meanwhile, make sure to record this information in the paper notebook!

Once both the tiff and the csv are saved together with the same filename, create the annotated jpeg: `./Python/gel-labeler.py rawdata/GelDoc/20150121.tiff rawdata/GelDoc/20150121.csv data/GelDoc/20150121.jpg`. Will automate this part tomorrow when I set up a makefile.

Updated README.txt to explain gel image system.


## 2015-01-21, CKB

Spent an embarrassingly long time trying to set up an initial makefile. Key piece of frustration: Make is effectively unusable on files with spaces in their name, so had to rename existing gel images to replace underscores with spaces, e.g. `'IGB 2015-01-16 16hr 22min.tif'` --> `'IGB_2015-01-16_16hr_22min.tif'` 

Now that filenames are fixed, configured Make to automatically create annotated gel images; no need to add each one to the Makefile; if you add the raw tiff and then run `make gels`, make will find them, create the annotated JPG version, and keep it updated in the future.

_NOTE_ an error message that confused me for hours today and will surely bite us again later: If `make gels` wants to create foo.jpg and cannot find one of the prerequisite files, possibly because you haven't yet saved foo.csv, Make will unhelpfully report:

	make: *** No rule to make target `data/GelDoc/foo.jpg', needed by `gels'.  Stop.

This does _not_ mean there's a problem with the make rule, it means it can't find foo.tif or foo.csv! Why doesn't it say, like, ``"cannot find foo.csv, needed by `gels'"`` instead? Beats me.

## 2015-01-26, CKB

Updated CTAB protocol to clarify that we save all the supernatant from each chloroform separation step, even if some samples yield more supernatant than others.

Updated README: protocols directory was missing from explanation of project layout.

Planning for soil DNA extraction: Scott suggests double-extracting each sample to recover more of the harder-to-extract community, will circulate a paper that shows this makes a difference.

## 2015-01-27, CKB

Modified gel labeleling script to skip any line of the CSV beginning with '#' This resolves the question posed 2015-01-20 of how to store gel metadata: Add it to the beginning of the CSV as a comment line, the script will just ignore it and it will be there if we need it later.

## 2015-01-28, CKB

Makefile bug fix: jpgs were not being remade when gel-labeler.py was updated. Fixed by adding script name to prerequisite list for data/GelDoc/*.jpg.

Testing gamma adjustment flags for gel image conversion. 

* Tried adding `-auto-gamma` to options passed to convert by gel-labeler.py, but contrast of resulting images is reliably too low. 
* Tried explicit values from `-gamma 0.5` up to `-gamma 2.3` and beyond.
* No one value seems ideal for all images, but gammas between 1.6 and 2.2 seem generally acceptable on my screen. 
* Saving script with `-gamma 2.0` for the moment, can revisit as needed.

## 2015-01-29, CKB

Added all gels run up to now: raw images as tiffs, lane IDs and notes as CSV, both in rawdata/GelDoc/. Processed images as jpeg in data/GelDoc/.

## 2015-01-30, CKB

Added scripts from Rich FitzJohn to deal with between-OS differences in CSV line endings. 

## 2015-02-02, CKB

Added a log for all CTAB extractions. Note that other scripts will rely on this log to map sample IDs to correct samples for e.g. Nanodrop results, so use the same ID in every file the sample touches. Leave not-yet-filled fields blank, enter "NA" for fields which cannot be filled.

* ID: What the tube is actually labeled. IDs should always be unique within a day, even if the day's extractions were done in several batches.
* CTAB date: What day did we do the chloroform extraction?
* Nanodrop date: What day was it Nanodropped?
* Gel date: What day did we run it on a gel?
* Tech: Who did the extraction? (even if someone else did Nanodrop or gel)
* mg tissue: How much powdered material went into the tube?
* Exclude: One-word reason to remove this sample from final analysis, blank if sample is believed OK. A non-exhaustive set of examples:
	- "Protocol" for substantial deviations from CTAB-BC protocol (e.g. tests of buffer variants, wrong volume added/removed, major timing error).
	- "Failed" if protocol followed but no DNA recovered.
	- "Outlier" if yield is way out of line with expectation (only declare this for extreme cases!)
* Notes: anything else, probably including more details on any exclude flag.

## 2015-02-03, CKB

Added raw Nanodrop files for 01-08 through 01-27. Note that these have Windows line endings, so I committed them with $(git commit --no-verify) to bypass the pre-commit hook that checks for discrepancies in line endings. Now that they are committed, any future edits to these files (hopefully few if any --don't edit the raw outputs!) will only complain if the line endings change.

In same commit, added a corrections file (rawdata/nanodrop/nanodrop_corrections.csv). This is a look-up table: Any Nanodrop reading whose timestamp and sample ID match a `datetime` and `savedID` in the corrections file will have its sample ID changed to the value of `newID`. If `newID` is empty, the observation will be deleted. Still working on the script that will perform these corrections.

Added an R script to concatenate all Nanodrop files, apply corrections, and write cleaned version to data/nanodrop.csv, committed first revision of output. Next up: compare these values against tissue mass recorded in rawdata/ctab_log.csv. This will be a separate script.

