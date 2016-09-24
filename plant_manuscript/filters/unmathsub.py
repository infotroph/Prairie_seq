#!/usr/bin/env python3

'''
Pandoc filter to convert inline math subscripts to text sbscripts.
Written for a very specific problem:
	Bibtex entries with "CO_{2}" are rendered by the Pandoc parser as
	[Str "CO",Math InlineMath "_{2}"],
	which is then rendered in OOXML as an inline equation that looks like
		"CO   2", with the 2 subscripted but an empty equation field between the subscript and the previous letters.
This filter solves this problem by replacing
	[Math InlineMath _"{...}"]
with a text subscript:
	[Subscript Str "..."],
thus removing the equation field entirely.

Use with caution -- will probably break real inline equations that start with a subscript.

To use this on bibliography entries, this filter needs to be downstream of pandoc-citeproc.
I do this by running pandoc twice: Once for pandoc-citeproc with native output, then pipe that output into the second run for this filter, e.g.

	pandoc infile.md \
		--bibliography biblio.bib \
		--csl style.csl \
		-t native \
	| pandoc - \
		-f native \
		--filter ./unmathsub.py \
		--reference-docx ref.docx
		-o output.docx
'''

from pandocfilters import toJSONFilter, Str, Subscript

def unmathsub(key, value, format, meta):
	if (key == 'Math'
		and len(value) == 2
		and '_{' in (x[:2] for x in value if isinstance(x, str))
		and 'InlineMath' in (x['t'] for x in value if 't' in x)):
			for x in value:
				if isinstance(x, str):
					x = Str(x.split('_{')[1].split('}')[0])
					return Subscript([x])

if __name__ == "__main__":
    toJSONFilter(unmathsub)
