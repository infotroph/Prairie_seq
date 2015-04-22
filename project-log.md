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

Added an R script to regress DNA yield against milligrams tissue used in the extraction and plot the results by species. Currently showing only extractions performed on or after 2015-01-26, when we switched from "remove the same amount of supernatant from every tube" to "remove all the supernatant and calculate volumes of later reagent additions from the tube that yielded the most." This throws out a lot of potential data, but also throws out a lot of REALLY noisy data and is a convenient bright line between "protocol development" and "full production."

## 2015-02-24, SAW & TLP

Taylor and I ran the test PCRs on a 2% gel at 1:100 dilution (10 ul per sample on the gel). We saw faint bands, but too dilute to get a good image. Will re-run tomorrow 1ul in 10ul water.

## 2015-02-25, SAW

Second attempt at gel image of PCR products. Had problems with the gel (large piece of solid EtBr came off the pipette tip and there was a hair and a few bubbles in the gel). Ran the 1ul of sample in 10ul H2O and 2ul loading buffer. Again, bands were faint but present at the expected sizes for both primer combinations (plant ITS and bacterial 16s). However, couldn't get an image that I liked before EtBr became too faint. If we want images for the posters, I suggest re-running these at 5ul sample in 1 ul loading buffer/dye and changing ladder to 1 ul ladder in 2 ul loading buffer/dye and 3ul H2O. The SYBR green rtPCR kit came in today and we should be clear to proceed with both poster projects following one more meeting with Brian and Kou San.

## 2015-03-19-23, CKB

First pass at a set of scripts to analyze the melting temperature results from multiple extraction qPCR. All are in the `R/` directory:
	
* `qpcr_curve.R` takes raw data from `rawdata/qpcr/`, smooths and normalizes the fluourescence values, performs a peak-fitting procedure, and saves the results in three files: fitted fluorescence values in `data/multi_ctab_melt_curves.csv`, a summary of number of peaks fit and the Tm of the biggest one from each sample in `data/multi_ctab_melt_summary.csv`, and a kind of ugly but useful diagnostic plot of the peak-fitting results in `figs/multi_ctab_peakfit.pdf`. It's currently set to consider only the temperatures between 80 and 90 °C; If using it for other runs, check plots and expand the range as needed.
* `plot_melt_curve.R` reads the normalized fluorescence values from `data/multi_ctab_melt_curves.csv` and plots a nice-looking graph, arranged by sample and color-coded by number of extractions, to `fgs/multi_ctab_melt_curves.pdf`.
* `order-plate.R` provides a function to sort 96-well plate well numbers correctly; I got tired of the standard lexical sort where well IDs go "A1, A10, A11, A12, A2, A3, ..., A9, B1, ...", so this is an easy way to sort things back into _plate_ order.
* `plot_melt_summary.R` takes the summary output from `data/multi_ctab_melt_summary.csv` and plots two pretty ugly and hard-to-read dotplots as one PDF at `figs/multi_ctab_melt_npeak_tm.pdf`. This whole script and its output can go away if the figures aren't helpful.
* `plot_melt_distance.R` reads the normalized fluorescence values from `data/multi_ctab_melt_curves.csv` and tries to analyze the distance between curves. It does this in several ways, most of them based on computing Euclidean distance between curves. This script does everything twice, once using normalized fluorescence values and one using their derivative (the rate of change in fluorescense with temperature). Think of it as one analysis on the melting *curves* and one analysis on the melting *peaks*. I only did this because I wasn't sure which would be easier to reason about; if they don't give the same answer at the end of the day then we've done something wrong. The analyses produced are all combined in one PDF (`figs/multi_ctab_melt_distance.pdf`) and one text file (`multi_ctab_melt_distance_ordresults.txt`):
	1. A heirachical clustering of pairwise distances, presented as a dendrogram. currently using complete linkage, but we should try other clustering methods and make sure they tell similar stories.
	2. A simple boxplot of each sample's Euclidean distance from a "reference" curve. I arbitrarily picked one of the E. Coli samples (well A11) to be the reference; it might be more sensible to at least take an average of both of them.
	3. A nonmetric multidimensional scaling plot, with "environmental" vectors (actually experimental in our case) overlaid in blue. For this and the following outputs, the three poorly amplified samples (H2O, TE, and the failed A-1 from well A1) are excluded from the dataset to keep things simpler. *The scaling of the vectors is weird right now and I'm **not at all sure** I did these multidimensional analyses correctly!* Notice the "mixed bac" centroid is sitting out in the middle of nowhere... when I run the same code in an interactive R session, the centroids all land right on top of the samples, but when run from a script it reliably looks bad. Will debug this when I get a chance, in the meantime *don't rely on this plot.*
	4. A redundancy analysis plot, showing the same pattern of points in black, and the red ~ring is the temperatures (if you zoom way in you may be able to see a few digits.) Again, I'm not convinced I did this right; the temperature structure looks artifactual.
	5. Only in the text file: A multivariate permutation test for effects of sample source (`Tissue`) and number of extractions expressed as a cubic function (`poly(Extractions,3)`). The significance of the Extractions term seems to vary a lot depending exactly how I set up the test. Here as well check my work before you trust me.

2015-03-28, CKB: 

Started an annotated bibliography for the project in `notes/bibliography.txt`. Current contents: Every paper I can find that any of us has emailed around to the group in the past year. Current format: Citation in utterly plain text, blank line, any notes about the paper (as long or short as you like), blank line, row of at least ten dashes. 

I picked this format because it's dead simple and easy for me to *export* from Papers, but we should eventually change it to something machine-readable that each of our reference management software can read *in*, because if you made me choose between "buried in an anthill" and "retype even one more list of author names ever", I'd have to think hard.

New file: messages from CKB's correespondence thus far with Pizzo and Associates, the providers of the seed for the prairie plots, about the makeup of their inoculant mix. Bottom line so far: it's probably just a single strain of _Glomus intraradices_, but there's a possibility it was a 3-species _G. intraradices_, _G. etunicatum_,  _G. deserticola_ mix. In either case, the inoculant was grown outdoors under nonsterile conditions.

2015-04-21, CKB:

Bioanalyzer results, and a quick plotting script, for TLP's Undergrad Research Symposium poster. Length calls not yet considered, no stats yet -- just pictures. TODO: These figures are NOT yet built by make! To recreate: `Rscript R/overlay_bioanalyzer_traces.R rawdata/bioanalyzer/*.csv`

