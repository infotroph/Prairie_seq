Prairie Seq
===========

Code and data for sequencing of root & soil samples from the restored prairie at the EBI Energy Farm
------------------------------------------------------------------------------

This analysis is intended to be fully automated and repeatable. If I succeed in that, any change to the code or data should propagate through the downstream parts of the analysis simply by running $(make).

Repository layout:
- notes/
	Bits of text -- reminders from the authors to ourselves, sketches for paper sections, instructions. All hand-written; make doesn't touch anything in this directory.
- rawdata/ 
	Datasets in the form they came to us. If any file here changes, it's probably because we redid a whole lot of labwork.
- README.txt
	This file.

Items that will exist soon, but don't yet:
- data/
	Fully processed, cleaned-up, ready-to-analyze datasets. Everything in this dataset should be reproducible at any time by rerunning the relevant set of scripts. 
- scripts/
	Tools to automate the rest of the analysis.
- Makefile	
	The script that runs the whole analysis. After making any change to data or code, update outputs by running the command $(make) in this directory. All analyses that need updating after the change, and none of the ones that don't need updating, will be rerun.
