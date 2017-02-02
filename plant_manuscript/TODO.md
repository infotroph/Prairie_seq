
For the next revision, if there is one:

* If adding Sanger seq, add leaf vouchers to methods description

* Feng 2013 census data?

* Fig 1: After review, update "Black et al submitted" as needed

* Possible citation to add: http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0169515, "Testing the Efficacy of DNA Barcodes for Identifying the Vascular Plants of Canada" -- yet more support for notion that ITS2 is great for genus ID but usually not great for species level


Post-compilation song-and-dance checklist:

* title page
	- Add newline before each subhead
	- Remove first-line indent from running head, EHD contact info
	- Update table to indicate which figures are in color
		In 2016-12-22 draft: Figs. 2, 4, 5, supporting Figs. S2, S4, S5 
	- Picky, but: Add vertical border between columns 2 & 3
* Abstract
	- newline before keywords
* Intro
	- OK
* Methods, Results, Discussion, Acks
	- Add newline before header
* Tbl 1
	- Remove first-line indent from footnote
	- line breaks between header/table and table/footnote
	- Suppress line numbers
* figures
	- Move legends to own page
	- style to compact  (Or just delete first-line indents)
	- suppress line numbers
	- right-click -> format image -> size -> lock ratio -> set size to 6.5" wide
	- Supporting figures: If caption runs off page with 6.5" wide image, reduce image size to fit.

Song-and-dance checklist used to format as a dissertation chapter:

* Checked out new branch "as-diss-chapter"
* Edited Makefile to point toward ~/UI/dissertation/ versions of 
      - style/ecology.csl -> ~/UI/dissertation/ecology.csl
      - filters/unmathsub.py -> ~/UI/dissertation/unmathsub.py
      - filters/pandoc-word-sectionsbreak.hs -> ~/UI/dissertation/pandoc-word-sectionbreak-nolinenum.hs
      - style/delucia_style.docx -> ~/UI/dissertation/diss_style.docx
* changed target filename to ckbprairie_dissch4.docx
* Set pandoc-crossref prefixes to "Figure", "Table", "Equation"
* Set chapter labels to make all figure/table refs take the form "Table 4.1", "Figure 4.S5".
* Added "##Tables and Figures" section header before table 1.
* Changed section name of supplements from "Appendix: Supplemental Figures" to "Supplement 4.S1: Supplemental Figures"
* Compiled this result, now hand-editing.
* Added "Chapter 4" above title
* Deleted authors, contact info, author contributions, keywords.
* Added newlines between sections except when header is already at top of a page.
* Table 4.1: Added newlines above and below, set footnote to compact style.
* Each figure, both regular and supplement:
      - style of image and caption to compact
      - newline between image and caption
      - Adjust image size. Since the images in this chapter are embedded PDFs, there is an extra step to preserve aspect ratio: right-click -> Format Picture... -> "lock aspect ratio" -> make a throwaway size adjustment using one of the percentage boxes ("lock aspect" doesn't take effect until you do this) -> now set image width to 6" using the "absolute" box above.
* Saved this file as `static_drafts/ckbprairie_20161129_dissformatted.docx`.
* Selected all, copied, pasted into dissertation document.
