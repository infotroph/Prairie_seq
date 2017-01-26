#!/bin/bash

printf "\n## Section information\n\n"

printf "| Text Section | Words | | Non-text Section | Count | In color? |\n"
printf "|-|-|-|-|-|-|\n" 

# Word counts for each section.
# Summary gets special treatment, because we're only allowed 200 words
# and we want to avoid counting headers, keywords, or bullet points
WORDCOUNT="|Summary|"`sed -En 's/^\*//p' abstract.md | wc -w`"|\n"
WORDCOUNT+="|Introduction|"`wc -w < intro.md`"|\n"
WORDCOUNT+="|Materials and Methods|"`wc -w < methods.md`"|\n"
WORDCOUNT+="|Results|"`wc -w < results.md`"|\n"
WORDCOUNT+="|Discussion|"`wc -w < discussion.md`"|\n"
WORDCOUNT+="|Acknowledgements|"`wc -w < acknowledgements.md`"|\n"
WORDCOUNT+="|Total in main text|"
	WORDCOUNT+=`cat intro.md methods.md results.md discussion.md acknowledgements.md|wc -w`"|\n"

# Count figures and tables.
# Note that I'm reporting all figures as "color".
# Some *are* monochrome, but not worth the trouble to track--
# New Phyt is now online-only and color is free.
FIGCOUNT="|Figures|"`grep -c '^\!\[' figures.md`" | all |\n"
TBLCOUNT="|Tables|"`ls -l *table* | wc -l`" | none |\n"
SFIGCOUNT="|Supporting Figures|"`grep -c '^\!\[' figures_supplement.md`" | all |\n"

# Now put both counts side-by-side in the same table to save space
paste <(printf "$WORDCOUNT") <(printf "$FIGCOUNT $TBLCOUNT $SFIGCOUNT")

printf "\n\n***\n"
