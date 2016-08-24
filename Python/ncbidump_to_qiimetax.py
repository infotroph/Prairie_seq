#!/usr/bin/env python

'''
Arguments: two NCBI taxonomy dump files, probably named 'nodes.dmp' and 'names.dmp', in that order.
Returns (to stdout) one file mapping each taxID to a semicolon-delimited taxonomy string, as expected by QIIME

adapted by Chris Black from notes by Daniel McDonald (mcdonadt@colorado.edu), as posted 2011-03-29 to QIIME users forum
'''

from cogent.parse.ncbi_taxonomy import NcbiTaxonomyFromFiles
from sys import argv

nodefile = argv[1]
namefile = argv[2]
ranks = ['superkingdom', 'kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species']

def get_lineage(node, my_ranks):
    '''returns lineage information in my_ranks order'''
    ranks_lookup = dict([(r,idx) for idx,r in enumerate(my_ranks)])
    lineage = [None] * len(my_ranks)
    curr = node
    while curr.Parent is not None:
        if curr.Rank in ranks_lookup:
            lineage[ranks_lookup[curr.Rank]] = curr.Name
        curr = curr.Parent
    return lineage

def lineage_string(taxid):
    '''Pastes taxon levels together for printing.
    Note that 'tree' and 'ranks' are global.'''
    return ';'.join([str(x) for x in get_lineage(tree.ById[taxid], ranks)])


with open(nodefile, 'r') as nodefh:
    taxa = [int(line.split()[0]) for line in nodefh]
    nodefh.seek(0)
    with open(namefile, 'r') as namefh:
        tree = NcbiTaxonomyFromFiles(nodefh, namefh)

for t in taxa:
    print "%d\t%s" % (t,  lineage_string(t))
