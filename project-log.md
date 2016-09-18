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

2015-04-21, not recorded until 2015-05-26, CKB and CRS:

QPCR results, and plot output, for CRS's Undergrad Research Symposium poster. All these changes committed in branch `sligar-URS-poster`, and the changes are messy -- ALL of the qPCR plotting scripts have hard-coded filepaths in them, at least one of them assumed E.coli is in well A11, etc. I kicked the problem down the road by editing all scripts to write to versions of filenames with `-20150421` appended, then commented out all the existing Makefile entries and replaced them with date-specific ones. This will be no easier to fix later on, but maybe we'll be less up against a deadline.
	
	* (2016-08-11, CKB: I never did fix this properly, but am merging it back into master so that the data from the poster are easily accessible. Sorry for passing the buck, future collaborators/self.)

2015-05-26 (really 27 now), CKB:

Nanodrop readings from a test of how extraction time and buffer quantity affect CTAB results. Some code duplication compared to existing CTAB processing code, but this test has multiple Nanodrop readings per weighed sample, so it's probably easier to keep as a separate dataset.

2015-05-28, CKB:
	
Changed code for buffer saturation analysis to explictly convert 'Species' from a character vector to a factor. No change in ANOVA results, but the residuals-vs-factor-levels diagnostic plot now works correctly.

Updated CTAB protocol to use 90-minute incubation and 1300-µL buffer volume as per saturation analysis results.

2015-07-07, CKB: 

LOTS of benchwork last month not recorded here -- see paper notebook! Most resulting files are still kicking around uncommitted, will annotate as I clean them up and save them.

Today's commit: started weighing bulk soil for C & N combustion analysis. Only 12 samples in; will update `bulksoil_CHN_weights.csv` as I go.

2015-09-17:

Weighing more bulk soil. First commit: samples weighed on 2015-07-14 but not typed in until now. Second commit: Samples weighed today.


## 2016-08-01, CKB

Picking this project up again after long pause. Have spent the last month doing some exploratory poking without committing anything, in either the Git sense or the sense of deciding for sure what I'm doing. Game plan for today: commit the intermediate versions I went through as I explored, with short notes on each version.

* Very first pass 2016-06-30, theoretically closely following QIIME Illumina tutorial. 
	
	- Made a QIIME mapping file as per http://qiime.org/documentation/file_formats.html#metadata-mapping-files: 
		* Tab separated
		* First three columns must be "#SampleID", "BarcodeSequence", "LinkerPrimerSequence", in that order. 
		* SampleID must only contain alphanumerics and "." (no underscores!)
		* Last column must be "Description", and "should be kept brief, if possible". I pasted the underscore-separated version of my SampleIDs here.
		* I added optional columns ReversePrimer, Block, Location (=replicate within block), Depth1 (=top of layer), Depth2 (=bottom of layer), and SampleType (root, rhizosphere, control).
	Confirmed that qiime can read it with `validate_mapping_file.py -m plant_ITS_map.txt`.

	- Working on Biocluster, starting from the already-demultiplexed Plant ITS reads in `~/no_backup/Fluidigm_2015813/Delucia_Fluidigm_PrimerSortedDemultiplexed_2015813.tgz`. First uncompressing the files (but not those from other primers):

		```
		qsub -I
		cd no_backup/Fluidigm_2015813/
		mkdir plant_demult
		tar -xvf Delucia_Fluidigm_PrimerSortedDemultiplexed_2015813.tgz --wildcards 'Plant_ITS2*' -C plant_demult
		```

	- Testing end-joining on a subset, chosen the really dumb way by asking R for 10 SampleIDs from my local copy of the barcode file:
		
		```
		bc = read.csv("~/UI/prairie_seq/rawdata/sequences/barcode_key.csv")
		sample(bc$Barcode, 10) # ==> returns
		# [1] ATGGAGCACT TTGCTTAGTC ACGTGCTCTG CACGAGATGA CGATCCTATA 
		# [6] ACGGTGCTAG TCATCATGCG GACGTGCTTC TACATGATAG GTAGCCAGTA
		```

	- Pasted those into shell array format:
		
		```
		SUBSET=(ATGGAGCACT TTGCTTAGTC ACGTGCTCTG CACGAGATGA CGATCCTATA ACGGTGCTAG TCATCATGCG GACGTGCTTC TACATGATAG GTAGCCAGTA)
		mkdir sandbox
		for b in ${SUBSET[*]}; do
			cp plant_demult/Plant_ITS2*"$b"*.fastq sandbox/
		done

		mkdir sandbox_join
		time multiple_join_paired_ends.py \
			--input_dir sandbox \
			--output_dir sandbox_join \
			--read1_indicator _R1 \
			--read2_indicator _R2
		```

	- Runs in 21 sec. Let's try it on the whole dataset!

		```
		mkdir plant_demult_join
		time multiple_join_paired_ends.py \
			--input_dir plant_demult \
			--output_dir plant_demult_join \
			--read1_indicator _R1 \
			--read2_indicator _R2
		```

	- Runs in 7:27. How many ends did we pair? Each sample is written to its own directory containing separate fastq files for joined and unjoined reads, and fastq format uses 4 lines per sequence, so:

		```
		cd plant_demult_join/
		echo "file,n_joined,n_un1,n_un2" >> join_counts.csv
		for dir in *; do
			JOINED=`wc -l "$dir"/fastqjoin.join.fastq | awk '{print $1/4}'`
			UN1=`wc -l "$dir"/fastqjoin.un1.fastq | awk '{print $1/4}'`
			UN2=`wc -l "$dir"/fastqjoin.un2.fastq | awk '{print $1/4}'`
			echo $dir,$JOINED,$UN1,$UN2 >> join_counts.csv
		done
		```

	- Stem graph of the result in R (code not saved, but probably just `counts = read.csv("join_counts.csv"); stem(counts$n_joined/counts$n_un1)`) shows mode is ~50% of reads joined, but skewed left -- barely any with more than 60% paired, many 30-40% ==> Probably need to do some quality trimming *before* pairing ends, so that mismatches from bad base calls don't prevent assembly. 
	
	- Now let's look at quality filtering. First, copy joined output to own folder... Or rather, copy whole folder and delete unjoined, because it's easier.

		```
		cp -R plant_demult_join plant_demult_joinonly
		rm plant_demult_joinonly/*/fastqjoin.un1.fastq
		rm plant_demult_joinonly/*/fastqjoin.un2.fastq

		time multiple_split_libraries_fastq.py \
			--input_dir plant_demult_joinonly \
			--output_dir plant_demult_joinonly_sl \
			--include_input_dir_path \
			--remove_filepath_in_name
		```

	- Resulting reads are mostly near 480 bases long, including primers, which is in the neighborhood I was expecting. 

	- Default quality filters doesn't remove much: a few reads with too many Ns and a few more 'read too short after quality truncation', but 'barcode errors exceed max', Illumina quality digit', and 'Barcode not in mapping file' are always zero. That last is expected because I didn't give it a mapping file -- all sample IDs are being decoded from filenames. ==> Either these reads are all very high-quality, or I need to try more stringent quality settings. Let's forge ahead and see how many OTUs they sort into.

		```
		#!/bin/bash

		#PBS -S /bin/bash
		#PBS -q default
		#PBS -l nodes=1:ppn=10,mem=8000mb
		#PBS -M black11@igb.illinois.edu
		#PBS -m abe
		#PBS -j oe
		#PBS -N seq_sandbox
		#PBS -d /home/a-m/black11/no_backup/Fluidigm_2015813/

		module load qiime

		time pick_de_novo_otus.py \
		        --input_fp sandbox_joinonly_sl/seqs.fna \
		        --output_dir sandbox_denovo_otu \
		        --parallel \
		        --jobs_to_start 10
		```

	- picks 729 OTU at default similarity level of 97%, 370 of which are singletons. Definitely more than the number of species I'm expecting! ==> Try playing more with quality filters, both before and after assembling.

	- `pick_de_novo_otus.py` attempts taxonomy assignment by default. All OTUs fail, but this is expected -- it's trying to assign against the Greengenes 16S database, so I'd be worried if our ITS sequences *did* match any of it. 

* 2016-07-01: 

	- Converting demultiplexed directory names into identifiers that QIIME will recognize seems to be harder than I expected. Let's try working from the multiplexed files instead. Extract just the Plant ITS reads from the raw tarball:

		```
		mkdir plant_its
		tar -xvf Delucia_Fluidigm_PrimerSorted_2015813.tgz \
			-C plant_its "Plant_ITS2_Delucia_Fluidigm_R1.fastq"
		tar -xvf Delucia_Fluidigm_PrimerSorted_2015813.tgz \
			-C plant_its "Plant_ITS2_Delucia_Fluidigm_R2.fastq"
		tar -xvf Delucia_Fluidigm_PrimerSorted_2015813.tgz \
			-C plant_its "Plant_ITS2_Delucia_Fluidigm_I1.fastq"
		```

	- Set up a new Torque script `run_qiime.sh` to pair ends, demultiplex and quality filter, pick de novo OTUs, and run core diversity analyses. First run exits with error:

		"Reached end of index-reads file before iterating through joined paired-end-reads file! Except for missing paired-end reads that did not survive assembly, your index and paired-end reads files must be in the same order! Also, check that the index-reads and paired-end reads have identical headers. The last joined paired-end ID processed was: 'HWI-M01323:247:000000000-AH0K5:1:1101:14380:1000 1:N:0:'"

	- As per https://groups.google.com/forum/#!topic/qiime-forum/z3DhLeO8ZyA, this is because QIIME is expecting the read 1 and index read headers to match *exactly*, but they differ by R1 headers ending in "1:N:0:" and index headers ending in "2:N:0:". Fixed that:

		```
		sed 's/2:N:0:/1:N:0:/g' plant_its/Plant_ITS2_Delucia_Fluidigm_I1.fastq  > plant_its/Plant_ITS2_Delucia_Fluidigm_I1_headers2to1.fastq
		```

	- Next run also exits with error: expects 12-base Golay (error-correcting) barcodes by default, need to specify that barcode length is 10. Fixed.

	- Started with 1286163 raw reads from plant ITS primers, only 398722 seqs (31%) survive end-pairing and quality filtering. This includes reads with unrecognized barcodes, which arguably ought to be thrown out! Paired length is extremely consistent, though: 486 ± 13 bases.

	- de novo picking produces 5456 OTU, 2953 of which are singletons! ==> Either the demultiplexing removed lots of novel plant diversity (unlikely), or this filtering approach is letting a lot of junk through. Let's see what happens if I skip end-pairing and try to analyze read 1 by itself.

	- Modified `run_qiime.sh` to skip paired-end joining. First retaining unassigned reads as before: 389842 OTU!! OK, what if we throw out unassigned reads? I don't know how much barcode read quality correlates with sequence read quality, but "we're not sure which sample this sequence came from" is a pretty sound reason to exclude no matter how confident the base calls are. Result: 354771 OTU.

	- How are these OTU distributed between samples? Core diversity analyses still error out expecting a non-empty `otu_table_mc2_w_tax_no_pynast_failures.biom`, but obtained alpha/beta diversity plots by going through the QIIME log and hand-editing the individual commands. Rarefaction curves show thousands of OTU in every sample, little difference by group. ==> I think I really need to clean up samples more before clustering. Did not save any of my hand-run diversity analysis code.

* 2016-07-02:

	- One more check before leaving diversity analyses for the moment: Added breakdowns by block, depth, sampleType. Predictably, no visible difference there either. Yes, next step is definitely to try harsher upstream quality filtering.

* 2016-07-05:

	- Stripping primers (using `extract_barcodes.py`) before splitting libraries, on the grounds that invariant sequences aren't informative and we might as well get rid of them early for smaller files/faster analyses.

	- the default quality threshold for `split_libraries_fastq.py` is to remove bases where Q <= 3 -- which translates to only a 60% chance of a correct base call! added `--phred_quality_threshold 19` to trim at Q20 as recommended by <some citations I forgot to write down, like an idiot>.

	- 939133 reads survive filtering, mean length 260 +/- 20 De novo clustering assigns 18409 OTU, with 8674 singletons.
	==> Yes, more stringent qiuality filtering does seem to help somewhat, but de novo clustering still reports orders of magnitude more OTUs than I expect to actually be present. It seems likely that our primers are picking up ITS sequences from other, more diverse groups, especially fungi. Need to filter down to just things that look like real plants.

* 2016-07-06:
	
	- Attempting to bootleg a set of representative plant ITS sequences. My basic approach is to search the NCBI nucleotide database for "internal transcribed spacer 2" and restrict it to either all green plants or to the plant genera that are known (from Xiaohui Feng's aboveground abundance surveys) to occur in the prairie -- see `rawdata/ncbi_its2/search_string.txt` for the list. Did the searches in my browser at [http://www.ncbi.nlm.nih.gov/nuccore], downloaded results as `rawdata/ncbi_its2/ncbi_all_plant_its2_longid.fasta` and `rawdata/ncbi_its2/present_genera_its2_longid.fasta`, containing 244249 and 6508 sequences respectively. Not adding the raw all-plants files to Git yet, because it's 380 MB large!

	- Shortened FASTA headers to just the accession-version ID:
		
		```
		sed -E 's/gi\|.*\|.*\|(.*)\|.*/\1/' ncbi_all_plant_its2_longid.fasta > ncbi_all_plant_its2.fasta
		sed -E 's/gi\|.*\|.*\|(.*)\|.*/\1/' present_genera_its2_longid.fasta > present_genera_its2.fasta
		```

	- Installed R package 'taxize', retrieved taxonomy assignments for every sequence using `R/make_taxonomy.R`. **BEWARE**: this script takes a VERY long time to run! It has to make thousands of calls to the NCBI taxonomy API, which is rate-limited, and I didn't do a good job of error-handling -- every transient network error produces a script crash. It does write the results out as it goes, so I spent a weekend leaving it to run and restarting it as needed with manually-updated loop indices.

	- Noticed afterward that this produces FASTA files with multiple lines per sequence and empty lines between entries. Fixed in shell: 
		```
		for f in *fasta; do
			mv "$f" "$f"_0
			awk '/^>/ {print "\n"$0; next} {printf("%s", $0)}' "$f"_0 > "$f"
			rm "$f"_0
		done
		```	

	**BEWARE** that this modified my original `*_longid.fasta` as well! If I'd run this on the raw files before `make_taxonomy.R`, I bet the fix would have carried over, but not about to rerun it to find out.

	- My loop indexing was off and I ended up double-writing all line numbers of `ncbi_all_plant_its2_accessions_taxids.csv` ending in 001. Fixed in shell:

		```
		mv ncbi_all_plant_its2_accessions_taxids.csv ncbi_all_plant_its2_accessions_taxids_.csv
		uniq ncbi_all_plant_its2_accessions_taxids_.csv > ncbi_all_plant_its2_accessions_taxids.csv
		rm ncbi_all_plant_its2_accessions_taxids_.csv
		```

	I *think* I fixed this in the script too, but did not test.

	- Not saving most of the intermediate files, but `*_accessions_taxids.csv` and `*_its2_unique_taxonomy.txt` contain all the identities that were most time-consuming to produce. If updating this database in the future with new sequences from NCBI, should be able to take set differences against these files to avoid slow taxid/taxonomy lookups -- Unless you want to check for updated taxonomies, which might be wise to do!

	- Attempted to compare OTU picked five ways: open-reference with all NCBI plant sequences as the reference, open-reference with present genera as the reference, closed-reference with all plants, closed-reference with present genera, and de novo OTU picking as I've done before. Both open-reference attempts error out with `option --otu_picking_method: invalid choice: 'blast' (choose from 'uclust', 'usearch61', 'sortmerna_sumaclust')`, both closed-reference attempts error out with `no such option: --otu_picking_method`. Not saving code changes, will try again tomorrow.

* 2016-07-11:

	- Leaving unpaired analysis for a bit to try end-pairing from a different angle. Let's try to pair up the reads using Pandaseq 2.8, which appears to have a smarter assembly agorithm than QIIME's paired-end assembler -- Pandaseq considers the FASTQ quality scores and maximizes the probability of correctly assembled reads even in the presence of middling-quality base calls. Intuitively: If you have an OK-quality call in read 1 and you align it with a matching low-quality call in read 2, this could still be stronger evidence the base is correct than if you had one excellent-quality call in read 1 and nothing from read 2.

	- Pandaseq also trims primers in the assembly process. While working on this, noticed that the reverse Plant IT@ primer listed in the report from the sequencing center **apppears to be incorrect!** Their spreadsheet says primer 'Plant_ITS4R' is `5'-GGACTACVSGGGTATCTAAT`, but scrolling through the raw read 2 files most reads appear to start with `GACGCTTCTCCAGACTACAAT`, the Chen et al reverse primer we asked for. Assuming this is a copy/paste error in the report spreadsheet and telling Pandaseq to trim `GACGCTTCTCCAGACTACAAT`. TODO: Confirm this with the sequencing center, and update my QIIME mapping file--but not sure whether to update to Chen primer or to no primer, since they're trimmed before QIIME sees them.

	- Oh hey, ~183k out of our 1.28M total reads start with `TCCTCCGCTTATTGATATGC`, which is our **fungal** ITS4R primer! For comparison, ~830k start with the intended `GACGCTTCTCCAGACTACAAT`. TODO: What's up with these -- are they plant or fungal? Do I need to remove them explicitly? Will Pandaseq or QIIME throw them out automatically? Does this mean I should check the "fungal ITS" reads for plant sequences too? Forward reads do seem to ~all be the Chen forward primer (1.1M of 1.28M start `ATGCGATACTTGGTGTGAAT`)

	- First try at Pandaseq script saved as `bash/pair_pandaseq.sh`, with mostly default settings: minimum quality 0.6 (roughly equivalent to qiime's default minimum PHRED quality of 3), minimum overlap of 1 base (documentation says this setting doesn't make much difference because short overlaps tend to fail the quality filter anyway), no minimum or maximum assembled read length.

	- Pandaseq 2.8 expects barcodes in the FASTQ headers, so ran it with `-B` ("no barcodes") option. Reports 1130304 reads as successfully paired and 151670 as unpaired, with most common overlap around 100-120 bp but a smaller peak around 205-225 bp. 

	- On closer inspection, both peaks are really clusters --  next to none < 95, smooth increase 95-101, then a drop again followed by clearly separated 1-bp spikes at 108, 113, 116, 119, 130 and at 206, 218, 221, 224 bp. This seems promising -- I bet these are length polymorphisms of common species!

	- Pandaseq spawns 24 threads by default even though I only reserved 1 processor! Need to reserve more or rerstrict threads by passing `-T`

	- How to get these results back into QIIME without barcodes? Searched around for a while, learned that Pandaseq 2.10 was released a few weeks ago and adds the ability to read a separate barcode file. Emailed Biocluster staff to request they install Pandaseq 2.10.

* 2016-07-13:

	- pandaseq 2.10 is now installed on the cluster. Revising to use it: Load module as `module load pandaseq/2.10`, limit to 1 thread (`-T 1` -- Plenty fast even single-threaded, and makes it easier to read/interpret both the output sequences and the log file), and use a larger k-mer table (`-k 10`) to avoid `FMER` errors on highly repetitive sequences.

	- OK, now how do I get the output back into a QIIME-compatible format? First thought: Make barcode file by splitting barcodes back out of FASTA header. Sample input:

		```
		>HWI-M01323:247:000000000-AH0K5:1:2119:12329:25269:ATGTCATGCT
		```

	Sample output:

		```
		>HWI-M01323:247:000000000-AH0K5:1:2119:12329:25269
		ATGTCATGCT
		```

	Method: Sed, of course! Note that the first `.*` is greedy and eats two `:`. This is as intended.

		```
		sed -En 's/^>HWI-M01323:247:000000000-AH0K5:1:(.*):(.*$)/>\1\n\2/p' plant_its2_pspaired.fasta > pspaired_barcodes.fasta
		```

	Now shorten the paired-sequence headers to match. Note no `-n` option, so sequence lines are passed through unchanged:

		```
		sed -E 's/^>HWI-M01323:247:000000000-AH0K5:1:(.*):(.*$)/>\1/' plant_its2_pspaired.fasta > pspaired_shorthead.fasta
		```

	... No, actually that's not very useful. Instead let's produce FASTQ output from pandaseq (`-F`), then extract the barcodes in qiime with `extract_barcodes.py`:

		```
		module load qiime

		extract_barcodes.py \
			--fastq1 plant_its_pandaseq_joined/plant_its2_pspaired.fastq \
			--output_dir plant_its_pandaseq_joined \
			--input_type barcode_in_label \
			--bc1_len 10 \
			--mapping_fp plant_ITS_map.txt
		```

	... no again, because this loses barcode quality information. OK, let's filter the raw barcode file on the headers from the paired file.

		```
		cd plant_its_pandaseq_joined
		for read in `sed -En 's/(^@HWI.*):.*/\1/p' plant_its2_pspaired.fastq`; do
			grep -A3 "$read" ../plant_its/Plant_ITS2_Delucia_Fluidigm_I1.fastq >> barcodes_psjoined.fastq
		done
		```

	... No, because this turns out to be VERY slow -- I'm searching all ~1.2M raw barcode reads for each one of the ~1M filtered read headers!

	- Instead: Use sed to reshape headers, then filter the raw barcode file using `filter_fasta.py`, which is much faster than my naive grep approach. See new lines in `pair_pandaseq.sh` for the details.

* 2016-07-22: 
	
	- Making `run_qiime.sh` work with Pandaseq paired input. If trying to do more with unpaired sequences in the future, the version of `run_qiime.sh` I overwrite in this commit is your place to start.

	- Pandaseq produces a few empty seqs, which qiime doesn't like. Fixed by setting Pandaseq minimum sequence length -- using 25 as a fairly arbitary value; could probably even use 1.

	- `split_libraries.py` on paired reads returns 862070 seqs, length: 424 +/- 81.

	- de novo clustering finishes and assigns 138076 OTU, with 121548 singletons -- better than before, but still not great. PyNAST filtering fails (empty file) and diversity plotting fails because of missing samples.

* 2016-07-24:

	- Looking for more information on how to use a non-default reference database. Followed some links from the [qiime fungal ITS analysis tutorial](http://qiime.org/tutorials/fungal_its_analysis.html) and eventually found an outdated but still helpful tutorial on how to [turn the UNITE fungal sequence database into a QIIME reference set](https://github.com/qiime/its-reference-otus). I installed the [nested reference workflow](https://github.com/qiime/nested_reference_otus) they mention and tried to follow along with my sequences:

		1. Sort reference sequences by taxonomic depth, then by read length within depth. This way uclust will use the most informative sequences as the seeds for its clusters.
		2. perform de novo OTU picking on the sorted reference sequences at your target similarity level, then pick the representative set to use as your reference sequences. Following the example workflow, I'll make a 97% version and a 99% version of both my all-plants ITS sequences and my genera-that-exist-in-the-plots sequences.
		3. Filter the taxonomy file to contain only the taxa in the representative set. I'm guessing I can get away with skipping this step at the expense of a slightly larger reference taxonomy file and possibly slower lookups when assigning taxonomy later.
		4. Make a QIIME parameter file and give it the filepaths to our new reference sequences -- watch out for steps that quietly default to using Greengenes, and override all of them!

	- The sorting script seems to expects a different taxonomy file format than the rest of QIIME (??): Each line must have a sequence ID, Genbank ID, taxon string, and source string, and furthermore it's picky about the column headers. I duplicated Genbank IDs to also be sequence IDs, and used `ncbi_plants` or `ncbi_present` for the source:

		```
		awk 'BEGIN {print "ID Number\tGenBank Number\tNew Taxon String\tSource"}
		{print $1"\t"$0"\tncbi_present"}' \
		present_genera_its2_accession_taxonomy.txt > its2_taxonomy_present.txt
		```

	Saved sorting/clustering code as `bash/sort_ncbi_refs.sh`. TODO: currently have a copy of the reference seqs sitting in their own directory on the cluster; will want to rework this to point toward their `rawdata/` location.

	- Picking reference seqs for present genera appears to succeed and produces 754 OTU at 97% similarity, 2284 OTU at 99% similarity. Given that the original file has 6508 seqs from 2349 taxa in it, this seems reasonable to me.

	- Picking reference seqs for all plants fails at the clustering stage  -- both 97% and 99% throw "improperly formatted input file was provided". TODO: Debug this. Meanwhile, let's try to use the present set.

* 2016-07-25:

	- First try at a QIIME parameters file. It's just a plain text file, but I guess I'll save it as `bash/qiime_parameters.txt` so it lives next to the scripts it's controlling. Sets `uclust` as reference taxonomy assignment method, `~black11/ncbi_its2/present_genera_its2_accession_taxonomy.txt` as the reference txonomy file, MUSCLE as the alignment method, and allows reverse strand matching in the references. Oh, and starts 20 parallel jobs by default and tells the Emperor plots to not freak out about missing samples.

	- Speaking of missing samples: What posesses me to keep adding `--retain_unassigned_reads` to my `split_libraries` calls anyway? If we don't know what sample it came from it's seriously no use to us and just causes trouble downstream.

	- Trying open-reference OTU picking using uclust: tries to cluster against reference DB, then clusters failed reads de novo. 97% present genera database: 85 OTU in first-round cluster, but de novo rounds blow it up to 108712, with 102069 of those being singletons (=6643 with at least two observations). Similar story from 99%: 384 OTU in first-round closed-ref, but up to 110328 after de novo, with 104048 singletons = 6280 seen twice or more.

	- alignment takes *foooooooreveeeer*: Left the script running, turned out to take 60 hours to run, or ~$50 of compute time! Probably should have killed this job rather than let it run, especially since you can probably already guess how bad an attempted multiple alignment of 6643 fairly-variable sequences looks (Pretty bad, that's how bad).

	- Taxonomy assignment doesn't give any obvious error messages, but all OTU, whether from reference set or clustered de novo, come out as unassigned. Not sure what I'm doing wrong here.

	- Ran core diversity analyses in separate scripts while waiting for alignment to finish, but saving them as part of `run_qiime.sh`. No particular surprises there -- same as in previous runs, there are too many OTUs and no visible patterns between groups.

* 2016-07-26:

	- Playing more with Pandaseq settings--want to get a sense how sensitive the quality parameters are. Set up multiple Pandaseq runs varying quality threshold (`-t`) from 0.6 to 0.9, and also holding quality at 0.6 but applying a minimum quality threshold for individual bases of the paired sequence (`-C min_phred:<number>`). For each run, noted the number of sequences paired and the number listed as removed by each of the possible quality filters, then deduplicated (`pick_otus.py --similarity 1.0`) to see how many unique sequences are assembled, then counted how many of those appear only once (`awk '{print NF}'  whichever/path/otus.txt| sort -n | uniq -c | head -n1` -- note that first column of the input is always OTU name, so rows where `NF==2` are the singletons). My theory: If quality filtering is mostly removing garbage, it should reduce the singleton count disproportionately more than it reduces counts of commonly observed (dare we say "real") OTUs.

	- For both tests: always 1286163 raw reads input, 151708 that did not align, 66842 that aligned but are listed as "slow". Seems clear both these quality filters are applied after alignment is done.

	- Result of varying `-t`:

		```
		-t	paired	unique	sglton	lowq	short
		0.6 1129100	668661	624851	  4186	1169
		0.7 1114604	658367	614801	 18837	1014
		0.8 1033167	591841	549047	100394	 894
		0.9  717157	367346	333287	416531	 767
		```

	- ==> Not a huge change. 55.3, 55.2, 53.1, 46.5% of paired reads are singletons, so increasing the quality threshold does make a little difference, but not enough to explain tens of thousands of OTUs after clustering. Estimated overlaps are essentially identical for all -- counts for the 4 most common lengths drop a bit less from 0.6 to 0.9 than the counts for less-common lengths do, but basically sequences are removed proportionally across all lengths.

	- result of varying `-C min_phred`:

		```
		min_phred	paired	unique sglton	lowq	short	lowphred
		 3			81236	 14515 12376	4186	1169 	1047864
		10 			12364	  2252  1897	4186	1169	1116736
		20			 1752 	   409   352	4186	1169	1127348
		```

	- ==> filtering by individual base quality seems infeasible -- there just aren't many sequences without *some* low-quality bases. Hand-inspecting the paired fastq file, it appears to me that Pandaseq is *very conservative (or, perhaps, realistic?) about quality calls -- seem to be a lot of positions where, for reasons I don't understand, original base calls agree in both strands but Pandaseq assigns a lower quality than either original strand. 

	- Conclusion: Not going to change either of these settings right now. TODO: After rest of pipeline settles down, consider bumping -t from 0.6 to 0.8 and see how much it affects clustered OTU counts. My prediction: Not much.

* 2016-07-29:

	- Question: How much should I worry about index read quality? `split_libraries.py` does not perform error correction on 10-nt barcodes, just throws out any read that isn't an exact match. Should I change this?

	- Approach: We loaded 144 uniquely barcoded samples into the flowcell. How many unique index sequences did we get out? FASTQ files have four lines per record, so let's just extract the second line (=sequence) and compare them as plain ASCII strings.

		```
		$ cd no_backup/Fluidigm_2015813/plant_its/
		$ sed -n 'n;p;n;n' Plant_ITS2_Delucia_Fluidigm_I1.fastq |  sort | uniq | wc -l
		44393
		```

	- How many of these 44393 sequences are exact matches to known barcodes?

		```
		$ sed -n 'n;p;n;n' Plant_ITS2_Delucia_Fluidigm_I1.fastq | sort | uniq -c | sort > tmp.txt
		$ R
		> index_counts = read.table("tmp.txt", header=FALSE, col.names=c("count", "barcode"))
		> bcmap = read.table("../plant_ITS_map.txt", header=T, comment.char="")
		> sum(index_counts[index_counts$barcode %in% bcmap$BarcodeSequence, "count"])
		[1] 1203129
		> sum(index_counts$count)
		[1] 1286163
		> 1203129/1286163
		[1] 0.9354405
		```

	- ==> Most of them.

	- How many of the remaining inexact matches are abundant enough to matter?

		```
		> index_counts[!(index_counts$barcode %in% bcmap$Barcode) & index_counts$count > 100,]
		      count    barcode
		44252   105 NCGCGGACTA
		44253   149 CCCCCCCCCC
		44254   161 NCTTGTTCAC
		44259  2296 NNNNNNNNNN
		```

	- ==> Basically none of them.

	- How many sample barcodes are in the low-abundance reads?

		```
		> merge(
		   x=index_counts[(index_counts$barcode %in% bcmap$Barcode) & index_counts$count < 1000,],
		   y=bcmap[, c("BarcodeSequence", "X.SampleID")],
		   by.x="barcode",
		   by.y="BarcodeSequence",
		   all=FALSE)

		     barcode count      X.SampleID
		1 AATGCAGTGT    25  Rhizo.2p3.0.10
		2 ACCATGAGTC    29 Rhizo.0p7.10.30
		3 ACGCAGGAGT     2 Rhizo.2p3.10.30
		4 AGAGCGCCAA   590           H2O.C
		5 AGGTAGCTCA    29       1p4.30.50
		6 CGCGACTTGT    29        3p3.0.10
		7 CTAAGTCATG    25           H2O.A
		```

	- So:
		1. Every barcode from the known set was seen at least twice, and all but two root samples had more than 1000 raw reads.
		2. "NNNNNNNNNN" is the only barcode from outside the known set that was seen more than 200 times.
		3. Unknown barcodes are only about 6.5% of the whole dataset.
		4. There is no overlap between the rarely-seen known barcodes and the commonly-seen unknown barcodes.
		Therefore there would be little payoff from trying to perform error correction to recover sequences that have, say, an N at base 1 but otherwise match a known barcode: Most samples have plenty of reads as it is, and the samples that have too few have few enough that adding five or ten more error-corrected indexes won't help them.
		5. ==> Let's continue to throw out all reads whose index is not an exact match to a known barcode.

* 2016-07-30:

	- Can I improve OTU assignment by cleaning up my reference database? Let's investigate.

	- Full plant ITS2 file contains some lines that are VERY long. Which ones are those?

		```
		awk '{if(length>10000) print NR}' ncbi_all_plant_its2.fasta
		```

	This returns the following line numbers within the file (these are NOT GIs!): 33369, 36801, 36803, 36805, 38713, 38715, 38717, 38719, 38721, 38723, 38725, 38727, 38729, 93719, 93721, 257671, 257673, 263609, 285403, 462089, 462801, 467451, 467453, 467455, 467783, 467843, 467845, 467847, 486009, 486871.

	- Manually inspected headers at (each of the above line numbers - 1) with e.g. `sed -n '33368p' ncbi_all_plant_its2_longid.fasta`. Not recording every result here, but they seem to divide into two piles: Those that are just very long ribosome sequences (e.g. full read from 18S through 26s) and chloroplast DNA, which isn't relevant to this analysis, so--waaaaitaminute:

	- These here are entire carrot chromosomes! No WONDER the raw file is so big! Carrot is already well-represented in shorter ITS seqs, so I feel OK about throwing these out entirely. Let's entirely remove any sequences whose long header contains the words 'chloroplast' or 'genome'.

		```
		sed -nE 's/.*\|(.*)\|.*[Cc]hloroplast.*/\1/p' ncbi_all_plant_its2_longid.fasta >> unwanted_accessions.txt
		sed -nE 's/.*\|(.*)\|.*[Gg]enome.*/\1/p' ncbi_all_plant_its2_longid.fasta > unwanted_accessions.txt
		```

	- In my 2016-07-06 reference sequence files, 'chloroplast' matches 1979 seqs from all-plants file, while 'genome' matches 8: 1 algal chloroplast genome that is already removed by step 1, and 7 of the above-mentioned carrot chromosomes. 22 of the chloroplast seqs, and zero of the genome seqs, are also in the present genera file.

	- Let's also trim all the reference sequences to just the region of interest by trimming off everything outside our ITS primer binding sites.

	- ==> Edited `sort_ncbi_refs.sh` to:
		1. Use QIIME's `filter_fasta.py` to remove every sequences listed in `unwanted_accessions.txt` This step alone reduces the all-plant FASTA file from 317 to 151 megabytes!
		2. Use `cutadapt` to look for sites matching our ITS primers, and trim them and everything outside of them. When no matching site is found, sequence is left unchanged.
		3. Sort by taxonomy and run the nested reference workflow as before.
		4. Use newly written script `python/filter_taxonomy.py` to subset taxonomy files to only the entries matching the reference seqs.

	- After this trim, `awk '{if(length>10000) print NR}' plant_cut.fasta` finds only three lines: 255890, 255892, 482038. These are AY342318.1, AY342317.1, AB021684.1 respectively; all three are essentially-complete ribosomal RNA genes from the liverwort Marchantia polymorpha. Moving down the length scale, four more seqs have post-trim length between 5000 and 10000: KT693223.1, KU612123.1, LT174528.1, HE610130.1; all are classified as Chlorophyta (= algae). ==> Let's stop filtering for now and try picking OTUs with these included, but looks like I might be able to refine even further if necessary.

	- A possible approach if I do want to refine more: Pull out all the  non-streptophytes (I see 12159 Chlorophyta plus 1 uncultured chlorobiont) with something like:

		```
		awk '/^ID/{next} !/Streptophyta/{print $1}' plant_taxonomy.txt > plant_nonstreptophyte_ids.txt
		filter_fasta.py \
			--input_fasta_fp plant_cut.fasta \
			--output_fasta_fp streptophytes_cut.fasta \
			--seq_id_fp plant_nonstreptophyte_ids.txt \
			--negate
		```

* 2016-07-31:

	- Updating QIIME parameter file to match updated run scripts:
		* `assign_taxonomy:assignment_method` changed from `uclust` to `blast`, as per QIIME fungal ITS tutorial (not sure if this is why my taxonomy assignments were failing before, but worth a try)
		* `align_seqs:alignment_method` changed from `muscle` to `clustalw`, but maybe I should just delete it entirely on the grounds that if ITS2 is phylogenetically uninformative in fungi it's probably not great in plants... and besides, I don't *need* phylogeny, I just need taxonomy.
		* `assign_taxonomy:id_to_taxonomy_fp`  changed from `~black11/ncbi_its2/present_genera_its2_accession_taxonomy.txt` to... Hmm. I've set this file up to change names every time I run `sort_ncbi_refs.sh`! Setting it to the current `~black11/ncbi_its2/presentITS_otu_97/rep_set/97_taxonomy_20160730.txt`, but will need to change this when I sync the cluster up with my laptop.
		* Added line `assign_taxonomy:reference_seqs_fp ~black11/ncbi_its2/presentITS_otu_97/rep_set/97_otus_20160730.fasta` (was previously setting it in `run_qiime.sh`) Will need to update this one after syncing too.
		* Added line `pick_otus:otu_picking_method uclust_ref` as shown in the ITS soils demos. Not clear on the difference between `uclust_ref` and `uclust` with a reference database might do this anyway, but this seems most likely to be correct.

## 2016-08-07, CKB

Thus ends the backlog of notes from July work. Now to stay on track and actually commit my notes as I take them. Today: Working on synchronizing repositories. I've been hand-copying things back and forth between my laptop and the cluster all month; it's time to stop that.

All the notes I committed above were committed on a `datacheck` branch that I created when I was cross-checking datasheets from the extraction portion of the project. I plan to do another round of cross-checking next time I'm at the desk with the paper notes on it, but no need to keep this branch running. Merged everything back into master.

Committed some quickly-written, crappy notes toward an overview / intro&methods skeleton of the project -- Scott, feel free to raid these for your writing.

Pushed to Github, pulled from there to Biocluster, symlinked data to an easier-to remember path: `ln -s ~/no_backup/Fluidigm_2015813/ rawdata/miseq
`, then added that directory to `.gitignore`. The raw reads and large intermediate files will **not** be committed to git -- keep them backed up elsewhere, and copy them into your local repository as needed. Noted this in the README, too.

Now editing Torque scripts to use this layout. Done so far: `pair_pandaseq.py`, with more compact logging while I'm at it -- turned off INFO BESTOLP lines, and combined the Torque log and the Pandaseq log into a single file.

My `.gitignore` edits from above are not working--ignored `private` and `rawdata/miseq` are shown as unadded directories. Looks like Git doesn't like end-of-line comments. Removed those, both now ignored correctly.

Edited paths in `sort_ncbi_refs.sh` to do initial processing in the newly-relocated `rawdata/ncbi_its` directory and then write finished reference sequences and taxonomies to `data/its2_ref/`, updated `qiime_parameters.txt` to point toward them (still using present genera clustered at 97% for the moment, will test others soon).

...OK, sort_ncbi_refs needed a lot of work:

* nested OTU workflow needs the full taxonomies for every accession, which aren't yet committed. Added new script `expand_taxonomy.R` to reconstruct these on the fly from unique taxonomies and `accession_taxid` maps.
* Ditto for reference FASTAs with accessions as names. I've committed `present_genera_its2_longid.fasta and copied the too-giant-to-commit `ncbi_all_plant_its2_longid.fasta` into the working directory, and added `awk` calls to reconstruct the short-header versions as needed.
* Put Torque job ID into directory paths and logfile names, to avoid clobbering previous versions when I rerun it.
* call `filter_taxonomy.py` in between cutadapt and otu-calling steps, to remove sequences I trimmed out. I don't think this is 100% necessary, but if nothing else it prevents the log file from being flooded with thousands of lines of complaints about it.
* `filter_taxonomy.py` had one major bug (I was reading from `argv[0]` and `argv[1]` instead of `argv[1]` and `argv[2]`, one minor(treating close as a function instead of a method), and mixed tab/space indenting. Fixed all of these.
* needed to specify path to `filter_taxonomy.py`

## 2016-08-08, CKB

Fixing up `run_qiime.sh`, which was also in worse shape than I thought:

* `pick_open_reference_otus.py` requires that the OTU-picking method be passed in the script call and *NOT* in the parameters file (???), while the taxonomy file still must be passed in the parameter file. Currently generating temporary parameter files on the fly for each different reference method -- this is gross and I need to remove that as soon as I settle on a reference DB.
* Had some baffling moments trying to figure out the interaction between Torque working directory as set by `#PBS -d` (interpreted relative to the $(pwd) it was qsub'd from, doesn't know how to expand `~`) and relative paths across symlinked directory boundaries ('../../' did not go where I expected). Current solution: Specify Torque working directory as `#PBS -d .`, and make a note to always submit the script as `cd ~/Prairie_seq && qsub bash/run_qiime.sh`.
* updated paths to write most logs to `tmp/`
* `pick_open_reference_otus.py` refuses to overwrite existing OTU output directories. Punting on this for now by manually removing previous runs before submitting each time.
* Probably will end up deleting most of the align-and-tree commands, but not going to think about them until otu picking is working right. Added an `exit` to bail from script rather than delete/comment these.

BLAST is not finding reference and taxonomy files. Wasted an hour reverifying paths in `qiime_parameters` and rerunning `pick_open_reference_otus.py` before realizing BLAST apparently runs with a different working directory. Changed reference and taxonomy paths in `qiime_parameters` from relative to absolute, BLAST now runs happily. So much for avoiding absolute paths.

Ran `run_qiime.sh` to get picked OTUs from all four reference sets. The initial closed-reference step finds more OTUS as the size of the reference file grows: 73 from present genera clustered at 97%, 202 from present genera clustered at 99% (but the OTUs picked against it are still clustered at 97%!), 183 and 362 from all-plant seqs clustered at 97 and 99% respectively.  The de novo picking step essentially makes up for this, though -- total number of OTUs is pretty similar between methods: 5923, 5994, 6603, 6545 from present 97, present 99, plant 97, plant 99 respectively. Total number of seqs retained after throwing out singletons is very similar across methods -- ranges from 721686 to 722559 with no apparent pattern.

Stalling on making any formal decision about OTU picking. Let's look at some output! copied `rawdata/miseq/plant_its_present97_otu/otu_table_mc2_w_tax.biom` to my laptop, saved for the moment as `~/UI/prairie_seq/present97_otu_mc2_w_tax_20160808.biom`. Noodling around in R:

```
library(phyloseq)

bp = import_biom("~/UI/prairie_seq/present97_otu_mc2_w_tax_20160808.biom")

psmap = read.table(
	"~/UI/prairie_seq/rawdata/plant_ITS_map.txt",
	comment.char="",
	header=T)
rownames(psmap)=psmap$X.SampleID

bpm = merge_phyloseq(bp, sample_data(psmap))

plot_bar(
	subset_samples(bpm, SampleType=="root"),
	x="Rank7",
	fill="Rank9",
	facet_grid=~Depth1)

# normalize reads within each sample
# (all colSums(otu_table(bpm_sampnorm) should == 1)
bpm_sampnorm = transform_sample_counts(bpm, function(x) x/sum(x))

# plot by normalized abundance
# sum of abundance within each depth should equal number
#of samples from that depth -- 
# can check with nrow(sample_data(subset_samples(bpm, Depth1==0)))
# ==> Depth 0-10=26 samples, 10-30=26, 30-50=23, 50-75=26, 75-100=25.
plot_bar(
	subset_samples(bpm_sampnorm, SampleType=="root"),
	x="Rank7",
	fill="Rank9",
	facet_grid=~Depth1)
```

Notable observations in this plot:
* Taxonomic ranks are messed up here -- Rank7 shows family names for the dicots, but "Poales", i.e. a whole order, for the grasses. 
* Relative grass abundance increases with depth
* Relative legume abundance seems fairly constant with depth, but composition changes: *Astragalus* is common in surface layer but not below, *Lezpedeza* shows up in 10-30 layer but not elsewhere. 
Saved a screenshot of this last plot, emailed to EHD and SAW.

Let's have a look at the controls too.

```
(plot_bar(
 	subset_samples(bpm_sampnorm, SampleType=="control"),
 	x="Rank9",
 	facet_grid=Sample~.)
 +theme(axis.text.x = element_text(angle = 45, hjust = 1)))
```

* that's an awful lot of Solidago in places it shouldn't be, including water controls and *Andropogon* voucher samples -> hence also in spike-ins.
* Seems to be a wide, relatively even array of taxa in the voucher mix samples, which is a good sign for sensitivity / PCR bias worries.

Took a very brief look at these same plots in the all-plants 97% file, but did not go into detail and did not look at the 99% files at all. My quick look says: similar patterns but with more species in the mix.

## 2016-08-09, CKB:

Still stalling on OTU decision. Meanwhile, here's my first pass at how to add bulk soil C and N values in to the analysis -- I should probably just do this once and write them in to the mapping file! Working from a quickly hand-made CSV version of the C/N analysis data sent by Mike Masters on 2016-02-17. TODO: Clean this up properly and commit it!

```
library(dplyr)

# (This is a temporary file quickly hand-extracted from Excel sheet)
soil = read.csv("~/UI/prairie_seq/rawdata/sequences/SoilCN_tmp.csv")

# Remove empty capsules (they were a zero check), average duplicates.
# N=119 -- Apparently we missed 2P2 75-100
soil_clean = (soil
	%>% filter(Block != "Empty Capsule")
	%>% select(-Notes)
	%>% group_by(Block, Sample, Upper, Lower)
	%>% summarize_all(funs(mean))
) 

#psmap is as constructed yesterday
psmap_soil = merge(
	x=psmap,
	y=soil_clean,
	by.x=c("Block", "Location", "Depth1", "Depth2"),
	by.y=c("Block", "Sample", "Upper", "Lower"),
	all.x=TRUE)
psmap_soil$Depthf = paste0(psmap_soil$Depth1, "-", psmap_soil$Depth2)
psmap_soil$CN = psmap_soil$PctC / psmap_soil$PctN

rownames(psmap_soil) = psmap_soil$X.SampleID
bpms = merge_phyloseq(bp, sample_data(psmap_soil))
# ... use as above, but now with soil C and N data!
```

## 2016-08-13, CKB:

My OTU-call testing above is still unresolved -- I'm still not sure how to evaluate the results. Leaving it on the TODO list for the moment and switching back to pre-clustering cleanup. First, a Pandaseq algorithm change: The original Pandaseq algorithm, strangely, often a paired base as of lower quality than either parent strand, even when the base calls agree! I believe this is because one of the probability calculations in Masela et al 2012 confuses p(true match|observe match) with p(observe match|true match). Cole et al 2013 (doi:10.1093/nar/gkt1244) presents an update, available in Pandaseq as `-A rdp_mle`, that corrects this and produces base quality scores that are at least equal to the better-quality parent as long as both calls agree.

This means per-read base quality in the overlap regions is now reported as WAY higher -- effectively no reads (29 out of ~1.3M) removed as LOWQ, compared to ~4000 with default algorithm. Bumped up quality threshold from 0.6 to 0.8 on the theory that the sequences removed as low-quality now really are worth removing.

Next I want to evaluate a pre-assembly trimming step: What if I use cutadapt to remove forward and reverse primers and discard reads without a recognizable primer? This should remove the ~15% of reverse reads that seem to start with ITS4R (TCCTCCGCTTATTGATATGC, our fungal primer) instead of S3R (GACGCTTCTCCAGACTACAAT, our Chen et al plant reverse primer). Should I also quality-trim the 3' end before pairing ends? My rationale is that the very ends are much more likely to contain errors, including some that might not show up in the quality score (see Schirmer et al. 2015, doi:10.1093/nar/gku1341). Maybe (I haven't crunched the probabilities) below a certain quality it's more likely that we generate a spurious alignment than that Pandaseq corrects the error bases. If a read no longer pairs after trimming, arguably it wasn't giving us very good information to start with, at least give my current permissive overlap settings (allowed to have as little as 1 base overlap).

To test:

	* ran `cutadapt` on raw reads with `-q` unset or with it set to 10 or 20. All 3 runs trim primers (`-g ATGCGATACTTGGTGTGAAT -G GACGCTTCTCCAGACTACAAT`) with allowed error rate 0.1 (= up to 2 mismatches per primer).
	* ran `filter_fasta.py` on raw index reads to match them to trimmed read files,
	* then ran `pandaseq` with no primer trimming, algorithm `rdp_mle`, kmers 10, quality threshold 0.8.

How many sequences are removed by each level of quality trimming?

```
count_seqs.py -i plant_its_pandaseq_trimjoined_noq/R1_trim.fastq,\
	plant_its_pandaseq_trimjoined_q10/R1_trim.fastq,\
	plant_its_pandaseq_trimjoined_q20/R1_trim.fastq

1035310  : plant_its_pandaseq_trimjoined_q20/R1_trim.fastq (Sequence lengths (mean +/- std): 252.5424 +/- 45.5433)
1035810  : plant_its_pandaseq_trimjoined_q10/R1_trim.fastq (Sequence lengths (mean +/- std): 279.0444 +/- 3.2391)
1035810  : plant_its_pandaseq_trimjoined_noq/R1_trim.fastq (Sequence lengths (mean +/- std): 279.9997 +/- 0.0764)
```

So not much gets trimmed at Q10, while Q20 removes ~40 bases on average (but note SD -- these are probably highly skewed). OK, what does Pandaseq do with them?

```
count_seqs.py -i plant_its_pandaseq_trimjoined_noq/pspaired.fastq,\
	plant_its_pandaseq_trimjoined_q10/pspaired.fastq,\
	plant_its_pandaseq_trimjoined_q20/pspaired.fastq

1025833  : plant_its_pandaseq_trimjoined_q20/pspaired.fastq (Sequence lengths (mean +/- std): 423.4261 +/- 58.3442)
1035642  : plant_its_pandaseq_trimjoined_q10/pspaired.fastq (Sequence lengths (mean +/- std): 450.6829 +/- 29.8456)
1035648  : plant_its_pandaseq_trimjoined_noq/pspaired.fastq (Sequence lengths (mean +/- std): 451.1088 +/- 31.0052)
```

Uh-oh. If the mean length after assembly changes, Pandaseq must be picking different overlap sites! Is this an across-the-board effect or a skew from a few dramatic changes? To find out, let's look at how the length of individual reads changes between methods... but only in as much detail as needed to figure out what's going on, because these files are giant.

	* Make a list of the readnames from each file

	```
	sed -n 's/^@HWI/HWI/p' \
		plant_its_pandaseq_trimjoined_q20/pspaired.fastq \
		> tmp_20_reads.txt
	sed -n 's/^@HWI/HWI/p' \
		plant_its_pandaseq_trimjoined_q10/pspaired.fastq \
		> tmp_10_reads.txt
	sed -n 's/^@HWI/HWI/p' \
		plant_its_pandaseq_trimjoined_noq/pspaired.fastq \
		> tmp_0_reads.txt
	```

	* Filter it down to those that are present in all three assembled files

	```
	comm -1 -2 \
		<(sort tmp_20_reads.txt) \
		<(sort tmp_10_reads.txt) \
		> tmp_2010_reads.txt
	comm -1 -2 \
		<(sort tmp_2010_reads.txt) \
		<(sort tmp_0_reads.txt)  \
		> tmp_common_reads.txt
	```

	* Construct temporary fastqs containing only those reads, all in the same order.

	```
	filter_fasta.py \
		--input_fasta_fp plant_its_pandaseq_trimjoined_noq/pspaired.fastq \
		--output_fasta_fp tmp_pstrim_noq.fastq \
		--seq_id_fp tmp_common_reads.txt
	filter_fasta.py \
		--input_fasta_fp plant_its_pandaseq_trimjoined_q10/pspaired.fastq \
		--output_fasta_fp tmp_pstrim_q10.fastq \
		--seq_id_fp tmp_common_reads.txt
	filter_fasta.py \
		--input_fasta_fp plant_its_pandaseq_trimjoined_q20/pspaired.fastq \
		--output_fasta_fp tmp_pstrim_q20.fastq \
		--seq_id_fp tmp_common_reads.txt
	```

	* compare histograms of line length:

	```
	fastqhistogram () { ( sed -n 'n;p;n;n' $1 | awk '{print length}' | sort -n | uniq -c ) }
	fastqhistogram tmp_pstrim_noq.fastq
	fastqhistogram tmp_pstrim_q10.fastq
	fastqhistogram tmp_pstrim_q20.fastq
	```

Not showing raw result (~500 lines per file), but shortest assembled read from noq is 279 bases, q10 232, q20 38! q20 has a whole smear of short reads (~6k of them evenly spread out) with lengths 38-231 -- plus a very distinct peak of ~50k reads in the 238-247 region right at the bottom tail of the lower-q read lengths! Where did those short reads move from? Let's directly compare lengths of individual lines.

```
sed -n 'n;p;n;n' tmp_pstrim_noq.fastq | awk '{print length}' > tmp_noq_lengths.txt
sed -n 'n;p;n;n' tmp_pstrim_q10.fastq | awk '{print length}' > tmp_q10_lengths.txt
sed -n 'n;p;n;n' tmp_pstrim_q20.fastq | awk '{print length}' > tmp_q20_lengths.txt
```

Plotted these a few different ways, observed that:

* Most differences betwee q0 and q10 are random-looking. A surprising number of ~300-350 base q0 contigs become ~500-550 base q10 contigs, and a bunch of q0 contigs cluster ~560 but get shortened at q10 -- these must have only a few bases of overlap, since the untrimmed q0 reads are very close to 280 bases each.
* Plotting q20 vs either q0 or q10 shows distinct bands in the scatterplot: things that were anywhere from 275 to 560 bases at lower Q get pulled in to peaks near 180, 250, 400 in the q20 version. I interpret this to mean that bogus assemblies of random length are getting pushed back to their correct position by quality trimming.
* If bogus pairings at q0 and q10 are getting turned into real pairings at q20, that should mean the number of unique sequences in the assembled q20 file is lower, right?

```
sed -n 'n;p;n;n;' tmp_pstrim_noq.fastq | sort | uniq | wc -l
# 768151
sed -n 'n;p;n;n;' tmp_pstrim_q10.fastq | sort | uniq | wc -l
# 768097
sed -n 'n;p;n;n;' tmp_pstrim_q20.fastq | sort | uniq | wc -l
# 747124
```

==> Yes, it looks like it.

## 2016-08-14, CKB

Let's go a step further and put these into QIIME and deduplicate with `pick_otus.py --similarity 1.0`. The reduction in sequences holds up, and the difference gets larger, as I move through the pathway: post- `split_libraries.py`, seqs.fna contains 980830, 980663, 922851 reads (q0, q10, q20 respectively) with 729116, 728893, 684454 unique seqs if checked by `sed | sort | uniq` and 724854, 724629, 678301 unique seqs if checked by `pick_otus` with similarity 1.0. Why the difference between `uniq` and `pick_otus`? I think this is because `pick_otus` counts unequal-length reads as identical as long as the shorter one is an exact substring of the longer one, e.g. `ATGTAA` and `ATGT` are one OTU at similarity 1.0 but two records by `uniq`. The difference is bigger than I was expecting since everything should be anchored in the same primers, but not big enough to worry me.

How many of these sequences are identical between methods?

```
comm -1 -2 \
	<(sed -n 'n;p;' plant_its_sl_noq/seqs.fna | sort | uniq) \
	<(sed -n 'n;p;' plant_its_sl_q10/seqs.fna | sort | uniq) \
	| wc -l
# 680179
comm -1 -2 \
	<(sed -n 'n;p;' plant_its_sl_q10/seqs.fna | sort | uniq) \
	<(sed -n 'n;p;' plant_its_sl_q20/seqs.fna | sort | uniq) \
	| wc -l
# 392328
comm -1 -2 \
	<(sed -n 'n;p;' plant_its_sl_noq/seqs.fna | sort | uniq) \
	<(sed -n 'n;p;' plant_its_sl_q20/seqs.fna | sort | uniq) \
	| wc -l
# 391768
```

## 2016-08-16, CKB

Not shown here, because code is basically repeating what I did above: Played around with adding a minimum overlap. At q20 Pandaseq shows an awful lot of seqs (almost 180k) with only 3 bases of overlap, which seems like essentially blunt-end joining, but most of these come out to the same lengths that are common in seqs with longer overlaps, and specifying a minimum overlap of 10 or 25 seems to mostly make Pandaseq reassemble them at a different length rather than throw them out, and the length and overlap histograms become even more spread out than before -- this looks like it's adding noise, not removing it!

Let's think this through: Most R1 reads still close to 280 bases after trimming primers and low-quality bases, with some skew dwon to ~250. R2 has many reads very close to 279, but also a distinct mound in the 200-250 base range -- R2 quality drops faster, so quality trimming removes more bases. So for a 450-base qequence where both forward and reverse reads were near the short end of their common range, that's e.g. 250+200 bases minus ~3-5 bases overlap = totally plausible as a common non-error outcome given the histograms of the inputs. So the question is how to tell if these common lengths are *correctly* assembled. What if we test how many unique sequences are *common*... if imposing a minimum overlap is really cleaning up assembly errors, we should see fewer singletons *and* more common sequences, because the singletons got converted to them. Conversely, if imposing a minimum overlap is disrupting real-but-short assemblies, we should see common sequences become less common as the bogus reassembly converts them to singletons (noise). Let's count sequences where we see more than 100 identical copies before clustering, and ask  "how many reads do these common reads account for between them?"

```
sed -n 'n;p;n;n;' path/to/pspaired.fastq | sort | uniq -c | awk '$1 > 100 {print $1}' | wc -l
sed -n 'n;p;n;n;' path/to/pspaired.fastq | sort | uniq -c | awk 'BEGIN {n=0} $1 > 100 {n=n+$1} END {print n}'
```

Answer: 181-184 seqs totalling ~112k reads from both q0 and q10, 184 seqs with 105-108k reads at q20 when minimum overlap is set to 10 ot 25, but 225 seqs totalling 124431 reads at q20 with no minimum overlap. If I move down the scale and define "common" as anything over 10 reads, the same pattern is visible: 3622 seqs contain 195745 reads at q0, 3623 containing 191410 reads q10, 3777 containing 194372 reads q20 min overlap 10, 3530 containing  186687 reads at q20 min overlap 25, and 3843 containing 209228 reads at q20 with no min overlap.

(Yes, all those numbers would get a little bigger if ran them as e.g. '$1 >= 100' instead of '$1 > 100'. But my conclusion stands and I don't care enough to redo it.)

This seems pretty clear: quality-trimming before assembly boosts the number of reads that are common and identical to each other, while imposing a minimum overlap strongly reduces the number of identical reads -- they "turn back into" singletons! Note that I really do mean "boosts the number": At q20 with no min overlap, I get the fewest total reads but they contain more sequences that are commonly seen and those common sequences account for a larger number of reads (not just a higher proportion of them). Of course this doesn't prove that the common sequences are correctly assembled or that they reflect the actual genetics of any particular plant, but it certainly makes me more confident.

## 2016-08-17, CKB

==> Bottom line on pre-assembly trimming: By removing low-quality reads from the 3' end of raw reads before end-pairing, we remove about 30-40k reads, mostly singletons, and  we re-assemble around that many again at shorter lengths that cause them to convert from singletons to matching other common sequences. Some of the assembled contigs have overlaps shorter than would normally inspire confidence, but it seems likely these tend to be correct assemblies of a sequence nearly too long to assemble rather than bogus assemblies of shorter sequences.

## 2016-08-21, CKB

Follow-up to the above conclusiont: I realized Pandaseq also has a post-assembly filter for minimum "overlap bits saved" -- we can remove them rather the short overlaps rather than smear them around. Checked Cole et al 2014 (10.1093/nar/gkt1244) for the definition: bits saved = `log2(product{i=1 to n}(P_i/P)null))`, where `P_null=0.25`, so for one base this becomes bits saved = `log2(P/Pnull) = ((1-p)*(1-q)+pq/3)/0.25`. Since we've already trimmed reads to average Q>=20, we should have p ~= q <= 0.01, for `log2((0.99^2 + 0.99^/3)/0.25) ~= 1.97` bits per base. In other words: set `min_overlapbits` to a value about twice the shortest acceptable overlap length!

Added `-C min_overlapbits:20` and reran Pandaseq.

* Removes 1025833 (no overlap filter) - 750823 (20-bit min overlap) = 275010 reads removed by filtering.
* Increases mean read length from 423.4261 +/- 58.3442 to 447.2532 +/- 9.2307.
* Reduces unique sequence count by 747211 - 508917 = 238294.
* Nearly all of that reduction is in removed singletons: 707994 - 473605 = 234389.
* Counts of common sequences also decline: for seqs seen 10 or more times from 4262 to 3768, for seqs seen 100 or more times from 229 to 175.
* Does this mean we're losing anything important? Collected all seqs that are seen 100 or more times in no-min-overlap file but are removed (or count reduced below 100!) with a 20-bit minimum overlap:

```
sed -n 'n;p;n;n;' plant_its_pandaseq_trimjoined_q20/pspaired.fastq | sort | uniq -c | awk '$1>=100{print $2}' > q20_mc100.txt
sed -n 'n;p;n;n;' plant_its_pandaseq_trimjoined_q20mb20/pspaired.fastq | sort | uniq -c | awk '$1>=100{print $2}' > q20mb20_mc100.txt

comm -1 -2 q20_mc100.txt q20mb20_mc100.txt > qcomm.txt
comm -2 -3 q20_mc100.txt q20mb20_mc100.txt > qmbrm.txt

# note that the headers are just line numbers, as unique IDs to keep BLAST happy
awk '{print ">" NR "\n" $0}' qcomm.txt > qcomm.fasta
awk '{print ">" NR "\n" $0}' qmbrm.txt > qmbrm.fasta
```

* `qcomm.fasta` contains 175 sequences that are common both with and without overlap filtering. BLASTed (via web browser) and spot-checked ~30 of the results. Found them all good with top hits that look like species we expect to see.
*  `qmbrm.fasta` contains 54 common sequences are removed by the overlap quality filter. 2 of these are 159-160 bases long, 50 are 240-244 bases, and 2 are 443-449. All combined, they account for 18161 of the reads removed.
* BLASTed (via web browser) and checked all 54 results carefully.
* All except the two ~440-base seqs have only very low-scoring BLAST hits. No hit is more than 20 bases long, and most appear to match in the conserved 5.8S only. Taxonomy of hits is inconsistent -- several seqs have their best matches to the carp genome!
* ==> The short sequences look like junk to me.
* The two 440-base seqs have good hits with high coverage, and they appear to be one grass (probably *Sorghastrum*, though top-scoring hit is a *Saccharum*) and one *Solidago* (not clear which species -- good matches to at least half a dozen species, including both *S. rigida* and *S. canadensis* with near-equal identity).
* I see plenty of hits for both *Sorghastrum* and *Solidago* in `qcomm.fasta` (i.e. sequences for these that *do* pass the overlap-quality filter), and these particular sequences only appear 102 and 100 times respectively in the unfiltered dataset.
* ==> These two sequences aren't obviously junk, but I feel good about excluding them in the service of a principled overlap-quality cutoff.

## 2016-08-23, CKB

Credit where due: Today's work is largely inspired by conversation with Shawn Brown last week -- he suggested I'm likely to have better luck doing de novo OTU clustering followed by taxonomy assignment on the clustered centroid sequences, rather than attempt an open-reference or closed-reference approach. Other recommendations of note from Shawn:

* Consider using ITSx to extract just the ITS2 region, as often recommended for fungus, rather than try to align the full amplicon -- predict that this will make clustering "messier" (i.e. more clusters at a given similarity, because conserved regions aren't contributing to the estimate) but species assignments will probably be more accurate (all sequences in a given cluster are more likely to actually be related).
* For chimera detection, there is probably no plant ITS database that's authoritatize enough to treat as a "known chimera-free" reference. Best bet is to use de novo chimera detection: assume more abundant sequences are the likely parents, look for lower-abundance sequences that are a mix of two probable parents.
* For both clustering and OTU detection, consider using vsearch instead of usearch -- it's open-source, fast, and reportedly very good, but *is* still unpublished. Probably want to at least compare its results to usearch.
* To pick a clustering threshold, try several, look at the mock community results, and pick the one that comes closest to recreating the taxonomic makeup and number of species we expect.

Today: Working on a replacement for my approach to ITS2 taxonomy. Reasoning: The IGB biocluster already has an up-to-date local copy of the full Blast databases, and by calling `blastn` directly instead of through QIIME it is possible to return taxids instead of accession numbers. This greatly reduces the size of mapping file needed -- I only need to store one taxonomy for each known taxon, instead of one per sequence! -- and will be very fast for looking up preclustered sequences. This seems much more promising than my (painfully, slowly) hand-built ITS queries.

Two new scripts: `get_taxonomies.sh` downloads and uncompresses the complete NCBI taxonomy database (~1.5 million taxa, ~275 MB uncompressed), then calls `ncbidump_to_qiimetax.py`, which uses the Cogent parsing libraries (included with qiime) to write all the taxa to one text file in the form `taxid<tab>superkingdom;kingdom;phylum;class;order;family;genus;species\n` as expected by QIIME's `assign_taxonomy.py`. Should only need to run these scripts once per machine, or as needed to freshen from the current NCBI database.

Today's version of the taxonomy file is currently 147 MB and named `rawdata/ncbi_taxonomy/nt_taxonomy.txt`). Its MD5 sum is e23d49d12809bceb2e34a3b540b86f2c and it was built 2016-08-23 from a freshly downloaded taxdump.tar.gz whose MD5 sum is bacb0c67268987f3abfba4821c73e2c6.

## 2016-08-24, CKB

Now to make a way of using this taxonomy file. The challenge here is that QIIME expects to take one FASTA or BLAST database full of reference sequences and a second file of taxonomies that have the same IDs as the sequences -- probably NCBI GIs, which are getting phased out next month! To get around this, added a new script `assign_taxonomy_by_taxid.py`, which extends the default QIIME `assign_taxonomy.py` mechanism by defining a new class of OTU picker that calls `blastn` intead of `blastall` and returns the taxid of the top hit instead of its GI. The resulting blast hit can then be looked up in `nt_taxonomy.txt` in the same way QIIME's `assign_taxonomy.py` does.

## 2016-08-25, CKB

Testing ITSx, as recommended by Shawn Brown for extracting just the ITS2 regions for clustering without 5.8S/LSU ends. None of this is added to scripts yet, just testing from an interactive session. Started from vsearch_otu/seqs_unique_mc2.fasta, which contains 39929 seqs 381.2300 +/- 115.3755 bases long. As the name implies, it was dereplicated and singletons were removed using vsearch.

```
qsub -I -lnodes=1:ppn=8,mem=40gb
cd Prairie_seq/rawdata/miseq/
module load ITSx/1.0.11
mkdir itsx_test_vsearch_uniqmc2 # hoo boy is that a mouthfull
cd itsx_test_vsearch_uniqmc2/
ITSx -i ../vsearch_otu/seqs_unique_mc2.fasta -o ITSx_out -t "Tracheophyta,Fungi" --cpu 8   
```

Started 22:45:14, finished 00:05:57 = 1:20:42 elapsed, appears to only use four cores -- probably uses two threads (forward & reverse strands) per group in -t? Let's see how the seqs got divided up:

```
count_seqs.py -i "*.fasta"
0  : ITSx_out.ITS1.fasta
0  : ITSx_out.full.fasta
87  : ITSx_out_no_detections.fasta (Sequence lengths (mean +/- std): 219.8851 +/- 109.5218)
37904  : ITSx_out.ITS2.fasta (Sequence lengths (mean +/- std): 192.7186 +/- 53.3280)
```

Not bad. Now let's dereplicate the extracted ITS2 regions again:

```
time vsearch \
	--derep_fulllength ITSx_out.ITS2.fasta \
	--sizein \
	--sizeout \
	--fasta_width 0 \
	--minuniquesize 1 \
	--output ITSx_out.ITS2_derep_after_itsx.fasta
```

Takes less than one second. The bits of log output that are of interest right now:

```
7304746 nt in 37902 seqs, min 49, max 347, avg 193
WARNING: 2 sequences shorter than 32 nucleotides discarded.
18104 unique sequences, avg cluster 16.8, median 3, max 19238
```

Also tried dereplicating with --minuniquesize 2, i.e. throw out a second round of singletons, but output is identical to version with singletons. I'm not sure whether to be surprised by this -- on the one hand the file was singleton-free before ITS extraction, but on the other we were only storing one *copy* of each sequence -- it it likely that EVERY unique full-length sequence had at least one other sequence with an exactly matching ITS2? I guess if a lot of the variations are one-base variants, not *that* unlikely.

Now clustered the dereplicated ITS2 file at 80,90 93,95,97%, e.g.

```
vsearch \
	--cluster_fast ITSx_out.ITS2_derep_after_itsx.fasta \
	--centroids ITSx_out.ITS2_derep_after_itsx_otus80.fasta \
	--id 0.80 \
	--sizein \
	--sizeout \
	--strand both \
	--relabel "OTU_" \
	--threads 10
python ~/Prairie_seq/Python/assign_taxonomy_by_taxid.py \
	-i ITSx_out.ITS2_derep_after_itsx_otus80.fasta \
	-o otus80_assigned_taxonomies.txt \
	-t ~/Prairie_seq/rawdata/ncbi_taxonomy/nt_taxonomy.txt \
	--n_threads 3 \
	--min_percent_identity 80 \
	-l otu80_assign.log
# (repeat for other percents. Left --min_percent_identity at 90 for all except the 80% file; don't expect it to matter much)
# 80%:  66 Size min 2, max 54761, avg 274.3
# 90%: 179 Size min 2, max 46162, avg 101.1
# 93%: 266 Size min 2, max 44301, avg 68.1
# 95%: 395 Size min 2, max 44289, avg 45.8
# 97%: 643 Size min 2, max 36135, avg 28.2
```

How many of these clusters are assigned as the same species by Blast taxonomy? Let's pull out the taxonomy strings and count uniques: `awk -F'\t' '{print $2}' otus80_assigned_taxonomies.txt | sort | uniq | wc -l` gives 59 species at 80%, 101 at 90%, 110 at 93%, 123 at 95%, 140 at 97%.

OK, what if I lump by genus? If I drop the `-F'\t'` from the above awk call, it splits by whitespace -> second and further words of binomial are truncated -> taxonomy string same for all members of the genus ==> 49, 63, 64, 71, 72 genera.

How does this compare to clustering full seqs before ITS2 extraction? Don't have all 5 thresholds handy, but have run 80 and 95: 80% has 35 species from 31 genera, 95% 96 species from 69 genera.

...Huh. Those genera include "No", which is from "No blast hit", but also "None", which is a placeholder value that should always be filled in by `assign_taxonomy_by_taxid.py`. Poked around for a while and found that blastn's `staxids` formatter returns a *semicolon-separated list* of taxids. If several taxa are tied for best hit, blast returns the taxids of all hits in the tie, even if `-max_target_seqs` and `-max_hsps` are both 1! TODO: fix `assign_taxonomy_by_taxid.py` to handle this.

## 2016-09-04, CKB

Updated `assign_taxonomy_by_taxid.py` to compute a consensus taxonomy when BLAST returns multiple taxa. Example: For sequence 'Voucher.mix.A_306658' (`TGCAGAATCCCGTGAACCATCGAGTTTTTGAACGCAAGTTGCGCCTGAAGCCATCCGGTTGAGGGCACGTCTGCCTGGGCGTCACGCATCACGTTGCCCCCCAAACATCTATATTTAGATGGTCTGGTTGGGGCGGAGATTGGTCTCCCGTGCCACTTGCATGGTTGACCTAAATATGAGTCTCCTCACGAGAGACGCACGGCTAGTGGTGGTTGATAACACAGTCGTCTCGTGCCGTACGTTTATGTTTGTGAGTGTCTAGACTTGTGAAAAACCTGACGCGTCGTCTTCAGATGATGCTTCGATCGCGACCCCAGGTCAGGCGGGACTACCCGCTGAGTTTAAGCATATCAATAAGCGGAGGAAAAGAAACTTACAAGGATTCCCTTAGTAACGGCGAGCGAACCGGGAATAGCCCAGCTTGAAAATCGGTCGGCTTCGTCGTCCGA`), Blast returns `53749;53751;308558` with an E value of 4.96e-173. TaxIDs 53749, 53751, 308558, are *Echinacea pallida*, *Echinacea purpurea*, *Echinacea angustifolia* respectively, so a reasonable conclusion is that this sequence is probably an *Echinacea* but we're not sure what species. 

To script this, `assign_taxonomy_by_taxid.py` now provides its own `_map_ids_to_taxonomy` method (previously inherited from `BlastTaxonAssigner`) and gains a new argument `--min_consensus_fraction`, with default 1.0. When there are multiple taxa in the result, the script computes taxonomies for all taxids and then combines them truncating levels where less than `min_consensus_fraction` agree. Note that the consensus calculations use an existing `_get_consensus_assignment` method that is part of the default QIIME `TaxonAssigner` class -- my new code just does the string/list conversion to pass things between existing methods. Result: `assign_taxonomy_by_taxid.py` previously classified 'Voucher.mix.A_306658' as 'None', but now reports it as 'Eukaryota;Viridiplantae;Streptophyta;None;Asterales;Asteraceae;Echinacea'.

## 2016-09-05, CKB

Testing whether ITSx does multithreading within taxonomic groups, or just between them. Approach: repeatedly call ITSx on the same large file (using all unique paired ITS reads including singletons, contains 675898 seqs) with multithreading enabled and 24 CPUs available, varying the number of groups requested each time and using the Biocluster web usage monitor to check CPU usage while it runs. Prediction: Since ITSx checks both the primary and complementary strands by default, expect to see about 2 processors busy per taxonomic group. If there are more than that, ITSx is multithreading the HMM comparison within groups too.

Result: All 20 groups use all available CPU, 24-27 processes. 10 groups: 16-20. 6: 10-11. 4: 6-8. 2: 2-3 if bryophyta and chlorophyta, 4-5 if tracheophyta and fungi. ==> No, ITSx does not multithread within taxonomic groups to any appreciable degree, and maybe groups with few hits don't even use all of one core. When running on the cluster, there is no need to reserve more than (2*n_groups)+1 processors.

## 2016-09-09, CKB

Let's add ITSx to the scripted workflow. Order of events: Dereplicate the paired-end reads and remove singletons, check them for chimeras, extract the ITS2 region, calculate OTU clusters, map full file (including singletons and [ptential chimeras!) back to assigned OTUs. Added three new scripts that will probably be a ~complete replacement for the current `run_qiime.sh`:

* `split_derep.sh` looks up sample barcodes and converts fastq to fasta by running `split_libraries.py` as before, then uses vsearch to dereplicate seqs.fna with a minimum unique size of 2 (i.e. it drops all global singletons) and check for suspected chimeras (de novo method -- builds three-way alignments assuming parent sequences will have higher abundance than the chimeras they generate).

	When run on current paired-end output (`pspaired.fastq`), it finds 956812 reads with usable barcodes, dereplicates them to 675898 unique sequences, drops 635969 singletons, and flags 1537 of the remaining 39929 sequences as probable chimeras, leaving 38084 unique non-chimeras for us to extract and cluster. From the vsearch log: "Taking abundance information into account, this corresponds to 5643 (1.8%) chimeras, 313878 (97.8%) non-chimeras, and 1322 (0.4%) borderline sequences in 320843 total sequences." But note that this total excludes singletons, so the chimera rate would probably be much higher if they were included -- that's part of why we excluded them!

* `extract_its2.sh` uses ITSx to extract (HMM-predicted) ITS regions from the dereplicated reads. Since it's easy to run in parallel, I'm currently checking both forward and reverse strands for five of ITSx's 20 different group-specific HMMs: Tracheophyta (=higher plants), Fungi, Bryophyta, Oomycota, Marchantiophyta (=liverworts). Not really expecting any hits for anything other than forward-strand tracheophyta, but figured if they're there I want to know. Also testing several different lengths for the `--anchor` option, i.e. how many bases of 5.8S and SSU to leave on the ends of the extracted ITS2 to aid alignment, so I'm running it four ways: 0 bases, 10 bases, 20 bases, and "HMM", which retains the whole predicted 5.8S/SSU.
	
	When run on the 38084 sequences in the current `plant_its_sl/seqs_unique_mc2_nonchimera.fasta`, identifies 37997  predicted full-length ITS2 regions, 36142 of which are predicted full-length and 1854 of which are predicted to be partial sequences (at least 10 bases). Lengths of the extracted sequences (excluding partial seqs): 192.4019 +/- 53.6139 with no anchor bases, 210.1594 +/- 57.2314 with 10, 227.9169 +/- 60.9198 with 20, 271.7381 +/- 70.2078 with HMM anchors. For comparison, the unextracted `seqs_unique_mc2_nonchimera.fasta` reads are 380.4141 +/- 115.9131 bases long. Saving a file containing the partial sequences (`ITSx_out.ITS2.full_and_partial.fasta`) in case I want them later, but for now I plan to only use the full-length sequences in `ITSx_out.ITS2.fasta`.

* `pick_otu.sh` uses vsearch to pick de novo OTUs at several different similarity thresholds, assigns taxonomy to the cluster centroids by using the taxid of the best BLAST hit in the NCBI nt database, maps the reads from the full dataset -- including duplicates, singletons, and possible chimeras! -- back to these OTUs, constructs a sample-by-OTU table in biom format, and embeds sample metadata and OTU taxonomy into the same biom file. Note that the similarity threshold gets used in all three steps: if I clustered OTUs at, say, 95% similarity, then I reason I should also need at least 95% BLAST similarity for a taxonomy hit and 95% vsearch similarity to classify a given singleton read as a member of that OTU. TODO: Is this true? I feel fairly certain about it for read-mapping (that's essentially just part of the clustering process done in a separate step for efficiency), but less sure for the BLAST threshold.

	Ran this on all four lengths of extracted ITS regions and also on whole unextracted amplicons, each one at similarities 80, 85, 87, 90, 92, 95, 97, 99% = 40 OTU tables! Will need some time to understand these, but here are quick summary numbers: Number of OTU clusters ranges from 45 (`whole_80.biom`) to 2995 (`a0_99.biom`), with between 60% (`whole_99`) and 93% (`whole_80`) of reads from the full file successfully mapped back to OTUs and between 17% (!!!, `whole_99`) and 100% (six files: 80% & 85% clusters from `a20`, `ahmm`, `whole` ) of OTUs successfully assigned a taxonomy by BLAST. After collapsing OTUs that map to the same species/genus, the total number of species identified ranges from 36 (`whole_80`) to 106 (`a0_99`) and the number of genera ranges from 31 (`whole_80`) to 57 (`a0_90`) -- for comparison, recall that our voucher list has 34 species and 26 genera, and that our mock community ("voucher mix") samples contained 31 species from 24 genera. (**correction** 2016-09-13: The list has 34 species, but we only collected vouchers from 33 -- *Coreopsis palmata* is in `voucher_descriptions.txt` with zeroes in the leaf count and root count columns.)

Also added while writing the above scripts: changed `assign_taxonomy_by_taxid.py` to return sequence IDs unaltered. Was just returning the portion before first whitespace (i.e. the 'sequence identifier' but not not any 'comment fields'), which seems to be common but not universal for FASTA-handling programs, but my life is easier in the biom-building steps if I can count on the returned IDs being identical. To make this work, needed to undo any trimming done by blast itself--if a result ID doesn't exactly match a query ID, `assign_taxonomy_by_taxid.py` now searches for prefix matches and replaces the BLAST-truncated result ID with the original full-length query ID.

## 2016-09-12, CKB

Collecting several files relating to species voucher samples, including some that haven't previously been added to Git but really really should have. Relocated all of these to live in `rawdata/vouchers/`.

## 2016-09-16, CKB

Thinking more about BLAST similarity thresholds. Does it makes sense to require the same similarity used for clustering? Let's think through the ways a given sequence could change when we lower the threshold:

	* Hit remains the same: No problem! It could still be the wrong taxonomy, but our BLAST settings don't change it.
	* No-hit remains a no-hit: No problem! We just still don't know what the sequence is.
	* No-hit becomes a hit: This could be either good or bad. If a high-scoring match exists but was below our similarity threshold, finding the hit is good. If relaxing our standards makes us accept a bad match, it's bad.
	* Hit becomes a no-hit: Should never happen. As currently configured, taxonomy script will always report the highest-scoring hit if there is one that meets the similarity and e-value cutoffs, so anything that matches at more restrictive thresholds should also match, and still have the same score, at a lower threshold.
	* Hit changes to a different hit: Again, the highest-scoring hit from a high threshold should still be available at a low threshold, so lowering the threshold will only change the taxonomy of a hit if it *increases* the score, e.g. from a very short high-similarity match to a longer match with a lower similarity but enough extra length to more than compensate. If this happens, it's a good thing!

So a higher threshold is only better if it prevents us from declaring spurious taxonomic assignments to sequences that ought correctly to be left unidentified, or in the dubious case where a "wrong" match has a lower similarity but a higher blast score than the "right" match. 

==> Tentative takeaway: Pick one lower BLAST threshold to use for all clustering levels, plan to hand-inspect final results.
	(But may need to inspect all clusters that glom to a given species, not just one of them.)
	(And this doesn't tell me *what* threshold to use.)

To find which threshold to use: 

	* Pick a set of sequences that produce reasonable mappings at a low threshold, increase until false negatives rise.
	* Find some sequences with no good hit, decrease threshold until spurious matches start. This might be easier said than done?

Not sure how to assemble those sequence sets right now; will need to think more on this.

Meanwhile, made some plots of cluster number, unique species count, etc. comparing bioms from different OTS anchor lengths, clustering thresholds, and blast identities. Hopefully this is a one-off analysis, but the script for it is long, so I saved it as `R/biom_checking.R`. To generate the fixed-blast threshold files (`*_blast90.biom`, `*.blast95.biom`), I reran `assign_taxonomy_by_taxid.py` for each centroid file and then built a new biom by re-adding the new taxonomy, using `blast/reblast.sh`. Hopefully this too is a one-off, but saving it because but would be annoying to remake if I need it again.

Now switching gears to test ITS anchor length. The stated reason for leaving anchor bases is to improve multiple sequence alignments by reducing uncertainty about end gap lengths. Therefore, testing alignment quality seems like a reasonable way of evaluating anchor length... But since (at least clustalw's) alignment scores depend on the length of the sequence and different anchor lengths necessarily produce different sequence lengths, I don't know how to compare alignment qualities directly. How about an indirect method instead, such as: comparing tree geometries. Prediction: To the extent that ITS2 is phylogenetically informative (that is, "kinda but with caveats" -- see e.g. 10.1016/S1055-7903(03)00208-2, 10.1016/j.ympev.2008.07.019), and to the extent my BLAST-based taxonomy assignments are correct, a higher-quality alignment should produce a neighbor-joining tree where closely clustered sequences are also ones assigned to closely related taxa. Let's try!

On Biocluster:

```
module load clustalw/2.1

cd Prairie_seq/rawdata/miseq/plant_it_otu/
for f in otu_*[89]0.fasta; do 
    clustalw2 -infile="$f" -align -tree -quiet
done
```

Copied the resulting guide trees (`*.dnd`) to my computer, then in R:

```
# This throws a whole bunch of warnings because only the 80% and 90% trees exist.
# just gonna ignore those for the moment.
# 'b' is a list of 40 biom files generated at differing anchor lengths 
# and cluster thresholds -- See biom_checking.R for code
trees = lapply(names(b), function(x)read_tree(paste0("~/UI/prairie_seq/tmp/otu_", x, ".dnd")))
names(trees) = names(b)

# read names in bioms contain semicolons, but clustalw converts them to unserscores.
# Phyloseq won't read them if fixed upstream, 
# but seems happy to use semicolon-containing names once read.
trees = lapply(trees, function(x){taxa_names(x) = gsub("_", ";", taxa_names(x)); x})

# "b" is a list of phyloseq objects containing all 40 biom files from
# variable-blast-threshold tests.
btre = mapply(merge_phyloseq, b, trees)
plot_tree_sp = function(name){
	(plot_tree(
		physeq=btre[[name]],
		title=name,
		label.tips="Rank8",
		color="Rank6",
		ladderize=TRUE,
		base.spacing=1e-4)
	+ theme(legend.position="none"))
}

ggsave(
	filename="~/UI/prairie_seq/tmp/its_anchor_trees.pdf",
	plot=plot_grid(
		plot_tree_sp("a0_80"),
		plot_tree_sp("a10_80"),
		plot_tree_sp("a20_80"),
		plot_tree_sp("ahmm_80"),
		plot_tree_sp("whole_80"),
		plot_tree_sp("a0_90"),
		plot_tree_sp("a10_90"),
		plot_tree_sp("a20_90"),
		plot_tree_sp("ahmm_90"),
		plot_tree_sp("whole_90"),
		nrow=2),
	width=24,
	height=24,
	units="in"
)
```

Wrote a long, rambling email to Scott about about all of this, saved as `notes/cluster_and_id_notes_20160916.txt` Figures from it are archived in `figs/static/biom_checking_20160916/`.

## 2016-09-17, CKB
	
Looking more carefully at clustalw output, it appears that the neighbor-joining trees I made yesterday are not what I thought they were -- each tree is actually the guide tree that clustalw builds from *pairwise* distances, *before* performing multiple alignment. So they probably don't tell us much about the quality of the *multiple* alignment, though we could still expect them to be informative about pairwise alignments. Additionally, I now think I'm confounding the issue by aligning cluster centroids from each method -- it would be better to align the same set of sequences from each method, make sure I'm plotting a tree built *from* the alignment instead of the guide tree, and annotate the trees with taxonomies obtained from identical Blast settings -- that way any differences in tree geometry are solely attributable to differences in anchor length.

On biocluster:

	```
	anchors=(a0 a10 a20 ahmm whole)

	# all ITS-extracted files contain 
	# the same seqs in the same order (yes, I checked),
	# and are already sorted in decreasing abundance
	# ==> head -n200 gives the 100 most abundant sequences
	for a in ${anchors[@]::4}; do
	    head -n200 its2_"$a".fasta > tmp_its2head_"$a".fasta
	done

	# For its2_whole.fasta: Order might differ, need to match on seqids instead
	module purge
	module load qiime
	sed -En 's/^>(.*)$/\1/p' tmp_its2head_a0.fasta > tmp_readnames.txt
	time filter_fasta.py \
	    --input_fasta_fp its2_whole.fasta \
	    --output_fasta_fp tmp_its2head_whole.fasta \
	    --seq_id_fp tmp_readnames.txt
	rm tmp_readnames.txt

	module purge
	module load clustalw/2.1

	# align, build tree
	for a in ${anchors[@]}; do
	    clustalw2 -infile=tmp_its2head_"$a".fasta -align > tmp_"$a"_headalign.log
	    clustalw2 -infile=tmp_its2head_"$a".aln -tree > tmp_"$a"_headtree.log
	done
	```

From the logs: length of reference alignment amd multiple alignment scores (I still don't know how to interpret these, but saving in case):

	```
	anchor,length,score
	a0,258,2032535
	a10,275,2659693
	a20,292,2881240
	ahmm,348,4233257
	whole,523,6861623
	```

Now let's assign taxonomies to each file. Again, it's the same 100 sequences and the same BLAST settings, so any differences in assigned taxonomy are attributable to the greater or lesser number of anchor bases.

	```
	module purge
	module load qiime
	module load blast+

	for a in ${anchors[@]}; do
	    echo "$a"
	    python ~/Prairie_seq/Python/assign_taxonomy_by_taxid.py \
	        --input_fasta_fp tmp_its2head_"$a".fasta \
	        --output_fp tmp_its2head_"$a"_blasttax.txt \
	        --id_to_taxonomy_fp ~/Prairie_seq/rawdata/ncbi_taxonomy/nt_taxonomy.txt \
	        --log_fp tmp_its2head_"$a"_assign.log \
	        --n_threads 2 \
	        --min_percent_identity 90
	done
	```


Copied the resulting `*.ph` and `*_blasttax.txt` back to my laptop. In R:

	```
	library(phyloseq)
	library(tidyr)
	library(RColorBrewer)

	# "ih" for "its2 head"
	ih_names = c("a0", "a10", "a20", "ahmm", "whole")

	ih_trees = lapply(ih_names, function(x){
	    read_tree(paste0("~/UI/prairie_seq/tmp/tmp_its2head_", x, ".ph"))})
	names(ih_trees) = ih_names

	ih_taxa = lapply(ih_names, function(x){
	    xt = read.table(
	        paste0("~/UI/prairie_seq/tmp/tmp_its2head_", x, "_blasttax.txt"),
	        header=FALSE,
	        sep="\t",
	        stringsAsFactors=FALSE)
	    names(xt) = c("OTUID", "taxonomy", "evalue", "taxid")
	    # clustalw truncated IDS to 30 chars! We'll just match here and hope for no collisions.
	    rownames(xt) = substr(xt$OTUID, 1, 30) 
	    
	    tax_table(as.matrix(
	        xt
	        %>% separate(
	            "taxonomy", 
	            c("superkingdom", "kingdom", "phylum", "class", "order", "family", "genus", "species"), 
	            sep=";")))
	})

	# phyloseq demands an OTU table, so we'll humor it by pulling counts from OTUID.
	ih_fakesamples = lapply(ih_taxa, function(x){
	    xt = (
	        data.frame(x[,"OTUID"])
	        %>% transmute(fakesample=as.numeric(sub(".*=(\\d+);.*", "\\1", OTUID))))
	    rownames(xt) = rownames(x)
	    otu_table(xt, taxa_are_rows=TRUE)
	})

	ih = mapply("merge_phyloseq", ih_trees, ih_taxa, ih_fakesamples)

	# Make one stable color map for all trees
	ih_families = Reduce(
	    function(x,y)union(x,y),
	    lapply(ih, function(x)tax_table(x)[,"family"]))
	ih_family_colors = brewer.pal(length(ih_families), "Dark2")
	names(ih_family_colors) = ih_families
	ihcolor = scale_colour_manual(name = "family", values = ih_family_colors)

	plot_ihtree = function(name){
	    (plot_tree(
	        ih[[name]],
	        title=name,
	        color="family",
	        label.tips="species",
	        ladderize=TRUE)
	    + ihcolor
	    +theme(legend.position=c(0.8,0.9), legend.box.just=c(0,0)))
	}

	ggsave(
	    "figs/static/biom_checking_20160916/its2_anchorhead_trees.pdf",
	    plot_grid(
	        plot_ihtree("a0"),
	        plot_ihtree("a10"),
	        plot_ihtree("a20"),
	        plot_ihtree("ahmm"),
	        plot_ihtree("whole"),
	        nrow=2),
	    width=12,
	    height=12,
	    units="in")
	```

These trees look very different from yesterday's versions! No longer seems clear that taxonomic coherence changes much, nor that grasses have any less sequence variation than other groups. Sent a correction to Scott and Evan, going to wait for their input before making a call on this.