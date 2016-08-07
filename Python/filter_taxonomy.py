#!/usr/bin/env python

'''
Filter a QIIME-compatible taxonomy file to remove any taxa not present in the given reference set.

Usage: filter_taxonomy.py taxfile.txt refseqs.fasta

Original by Jon Leff, Jai Ram Rideout and Greg Caporaso, illustrating how to build a fungal ITS reference database.
Lightly modified by Chris Black to build a (bootleg, poorly-validated) plant ITS reference set.
'''

from sys import argv, stdout
from cogent.parse.fasta import MinimalFastaParser

def strip_tax(tax_fp, fasta_fp, out):
	otu_ids = []
	for seq_id,_ in MinimalFastaParser(open(fasta_fp,'U')):
	    otu_ids.append(seq_id)
	otu_ids = set(otu_ids)

	for line in open(tax_fp,'U'):
	    if line.strip().split()[0] in otu_ids:
	        out.write(line)
	close(fasta_fp)
	close(tax_fp)

strip_tax(argv[0], argv[1], stdout)
