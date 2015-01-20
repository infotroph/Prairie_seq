Prairie Seq
===========

Code and data for sequencing of root & soil samples from the restored prairie at the EBI Energy Farm
------------------------------------------------------------------------------

This analysis is intended to be fully automated and repeatable. If I succeed in that, any change to the code or data should propagate through the downstream parts of the analysis simply by running $(make).

Repository layout:
- notes/
	Bits of text -- reminders from the authors to ourselves, sketches for paper sections, instructions. All hand-written; make doesn't touch anything in this directory.
- Python/
	Python scripts for data cleanup.
- rawdata/ 
	Datasets in the form they came to us. If any file here changes, it's probably because we redid a whole lot of labwork. Subdirectories of note:
	GelDoc: 
		TIFF images of gels, named by timestamp and each accompanied by a CSV mapping lane numbers to sample IDs. The paper lab notebook should contain an annotated printout of each image that is stored here. 
		NOTE: Depending which software you use to look at them, the TIFF images might appear black. This is because they're stored with a linear gamma, and some programs (e.g. Photoshop) try to account for this on display, while others (e.g. Preview on OS X) wait for you to give explicit instructions. I recommend letting the Make script convert them to jpeg and looking at those.
- README.txt
	This file. Keep it up-to-date.

Items that will exist soon, but don't yet:
- data/
	Fully processed, cleaned-up, ready-to-analyze datasets. Everything in this dataset should be reproducible at any time by rerunning the relevant set of scripts. 
- Makefile	
	The script that runs the whole analysis. After making any change to data or code, update outputs by running the command $(make) in this directory. All analyses that need updating after the change, and none of the ones that don't need updating, will be rerun.
