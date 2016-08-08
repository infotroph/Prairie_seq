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
    with open(fasta_fp, 'U') as ff:
        for seq_id,_ in MinimalFastaParser(ff):
            otu_ids.append(seq_id)
    otu_ids = set(otu_ids)

    with open(tax_fp,'U') as tf:
        for line in tf:
            if line.strip().split()[0] in otu_ids:
                out.write(line)

strip_tax(argv[1], argv[2], stdout)
