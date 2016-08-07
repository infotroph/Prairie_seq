Prairie Seq
===========

Code and data for sequencing of root & soil samples from the restored prairie at the EBI Energy Farm
------------------------------------------------------------------------------

This analysis is intended to be fully automated and repeatable. If I succeed in that, any change to the code or data should propagate through the downstream parts of the analysis simply by running $(make). **N.B. as of 2016-08-06, the Makefile is badly out of date** and will not be updated until CKB gets the sequence analysis pipeline working correctly. Will update this readme when fixed.

Repository layout:
- bash/, Python/, R/
	Scripts, with each language in its own directory.
- data/
	Fully processed, cleaned-up, ready-to-analyze datasets. Everything in this directory should be reproducible at any time by rerunning the relevant set of scripts. 
- figs/
	Graphs plotted from clean datasets. Everything in this directory should be reproducible at any time by rerunning the relevant set of scripts.
- Makefile	
	The script that runs the whole analysis. After making any change to data or code, update outputs by running the command $(make) in the project root directory. All analyses that need updating after the change, and none of the ones that don't need updating, will be rerun.
- notes/
	Bits of text -- reminders from the authors to ourselves, sketches for paper sections, instructions. All hand-written; make doesn't touch anything in this directory.
- project-log.md
	Running log of changes to the project. Add to the bottom, don't edit what came earlier.
- protocols/
	Instructions for doing the work.
- rawdata/ 
	Datasets in the form they came to us. If any file here changes, it's probably because we redid a whole lot of labwork. Subdirectories of note:
	GelDoc/ 
		TIFF images of gels, named by timestamp and each accompanied by a CSV mapping lane numbers to sample IDs. The paper lab notebook should contain an annotated printout of each image that is stored here. 
		NOTE: Depending which software you use to look at them, the TIFF images might appear black. This is because they're stored with a linear gamma, and some programs (e.g. Photoshop) try to account for this on display, while others (e.g. Preview on OS X) wait for you to give explicit instructions. I recommend letting the Make script convert them to jpeg and looking at those.
	miseq/
		Raw sequencing data and large intermediate files. This directory is ignored by Git because the files are too large, so put your copy of the data here and keep it backed up by some non-Git method.
	ncbi_its2/
		Reference sequences and taxonomy assignments for all the NCBI Nculeotide search results for "internal transcribed spacer 2" downloaded on 2016-07-06; one file for all Viridiplantae and one for only the genera known from Xaiohui Feng's aboveground vegetation surveys. TODO: Move generated refseq files from here to data/.
	nanodrop/
		Text files are raw output from the Nanodrop (in ND1000 data viewer, choose Reports > "Save Report..." > "Export Report Table Only"). Record all readings in the paper lab notebook as well.
		Save corrections to individual readings in nanodrop_corrections.csv: timestamp and `savedID` must match timestamp and ID in raw output. If `newID` is specified, the cleanup script will use it to replace the sample ID. If newID is blank, the script will delete that observation from the cleaned dataset.
	qpcr/
		CSV output from the Bio-Rad droplet PCR machine, for melting temperature analysis and checking template concentrations. Each run produces 12 CSV files, many of which we may never use but might as well save -- they're all small. For each run, you'll need to make and add a 13th file named "<date>_platekey.csv", which should have 96 lines mapping sample characteristics for each well of the plate. 
- README.txt
	This file. Keep it up-to-date.


## Note on line endings:

Most Unix tools, including the ones we rely on to see line-by-line changes between commits, assume that every line of a text file ends with a newline character ("LF" or "\n"). Files generated in Windows usually have a carriage return *and* a newline ("CRLF" or "\r\n"), which causes other annoyances but does get recognized as the end of a line.

Excel for Mac, on the other hand, creates CSVs that use CR with no LF as their line ending (the Classic Mac standard, abandoned everywhere else for ~20 years). This makes diff treat the entire file as one long line, making it near-impossible to see what actually changed.

If you use this repository on a Mac, you should:

* set up a pre-commit hook so that Git will check CSV files and warn you before committing one with CR-only line endings. In the project root directory, run

	ln -s ../../bash/check_line_endings.sh .git/hooks/pre-commit

* To change the line endings in any CSVs created by Excel before you commit them, run

	./bash/fix-eol.sh your_file_here.csv


