Prairie Seq
===========

Code and data for sequencing of root & soil samples from the restored prairie at the EBI Energy Farm
------------------------------------------------------------------------------

This analysis is intended to be fully automated and repeatable. If I succeed in that, any change to the code or data should propagate through the downstream parts of the analysis simply by running $(make).

Repository layout:
- bash/, Python/, R/
	Scripts, with each language in its own directory.
- data/
	Fully processed, cleaned-up, ready-to-analyze datasets. Everything in this dataset should be reproducible at any time by rerunning the relevant set of scripts. 
- figs/
	Graphs plotted from clean datasets. Everything in this directory should be reproducible at any time by rerunning the relevant set of scripts.
- Makefile	
	The script that runs the whole analysis. After making any change to data or code, update outputs by running the command $(make) in this directory. All analyses that need updating after the change, and none of the ones that don't need updating, will be rerun.
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
	nanodrop/
		Text files are raw output from the Nanodrop (in ND1000 data viewer, choose Reports > "Save Report..." > "Export Report Table Only"). Record all readings in the paper lab notebook as well.
		Save corrections to individual readings in nanodrop_corrections.csv: timestamp and `savedID` must match timestamp and ID in raw output. If `newID` is specified, the cleanup script will use it to replace the sample ID. If newID is blank, the script will delete that observation from the cleaned dataset.
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


