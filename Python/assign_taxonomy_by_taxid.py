#!/usr/bin/env python

__author__ = "Chris Black"
__email__ = "chris@ckblack.org"
__version__ = "0.0.1"

import subprocess
from qiime.util import (parse_command_line_parameters, get_options_lookup,
                         make_option, load_qiime_config)
from qiime.assign_taxonomy import *

script_info = {}
script_info['brief_description'] = """Assign taxonomy to each sequence, using BLAST and a reference taxonomy keyed by taxid"""
script_info['script_description'] = """Extends the standard QIIME 1.9.1 taxonomy assignment with a method that uses BLAST+ and matches by taxid instead of by GI. That means this method does NOT work with the default greengenes reference taxonomy! 

For each query sequence, queries the specified Blast database (using megablast in blastn) and finds the taxid of the top-scoring hit (no more than one hit per query sequence), then looks up its taxonomy in the specified taxonomy mapping file. Since QIIME does not ship with blast+ by default, you'll need to make sure it's installed and available in your $PATH before calling this script. On my computing cluster I accomplish this with $(module load blast+), but your system may differ.

Output should be in the same format documented for assign_seqs.py. If it isn't, please file a bug.
"""

script_info['script_usage'] = []

script_info['script_usage'].append(("""With the default database:""", """
This only works if QIIME can find your local copy of the 'nt' database. If it can't, check whether $BLASTDB is set. The taxid lookup file ('nt_taxonomy.txt' here) must contains taxids that match those in your database.""", """%prog -i rep_seqs.fasta -t nt_taxonomy.txt"""))

script_info['script_usage'].append(("""With a custom database and optional settings:""",  """
Here we use a local Blast database (not a FASTA file!) named "localnucl" and a very stringent e-value cutoff but allow low-identity matches if they pass the other filters.""",
     """%prog -i rep_seqs.fasta -t nucl_taxonomy.txt --blast_db localnucl --blast_e_value 1e-80 --min_percent_identity 60 -o rep_taxonomy_assignments.txt -l rep_assign.log"""))


script_info['required_options'] = [
    get_options_lookup()['fasta_as_primary_input'],
    make_option('-t', '--id_to_taxonomy_fp', type="existing_filepath",
                help='Path to tab-delimited file mapping integer taxids to semicolon-separated '
                'taxonomy lists.')
]

script_info['optional_options'] = [
    make_option('-b', '--blast_db', type='blast_db',
                help='Database to blast against. Must be built with taxids '
                'that match those in your taxonomy file.'
                '[default: %default]', default='nt'),
    make_option('-e', '--blast_e_value', type='float',
                help='Maximum e-value to record an assignment '
                '[default: %default]', default=0.001),
    make_option('-p', '--min_percent_identity', type='int',
                help='Minimum percent identity to record an assignment '
                '[default: %default]', default=90),
    make_option('-o', '--output_fp', type='new_filepath',
                help='Path for result file ' +
                '[default: %default]', default='blastplus_assigned_taxonomy.txt'),
    make_option('-l', '--log_fp', type='new_filepath',
                help='Path for log file ' +
                '[default: %default]', default='blastplus_assign_taxonomy_log.txt'),
    make_option('--n_threads', type='int',
                help='Number of simultaneous threads blastn should run. '
                '[default: %default]', default=1)
]

script_info['version'] = __version__

def blastplus_seqtaxa(seqs, blast_db, max_evalue=1e7, min_percent_identity=90, num_threads=1):
    '''returns NCBI TaxIDs, **NOT** accession IDs!''' 
    seqfasta = "\n".join([">%s\n%s" % (id,seq) for id,seq in seqs])
    blastcmd = subprocess.Popen(
        ['blastn',
            '-db', blast_db,
            '-outfmt', '6 qseqid staxids evalue pident',
            '-task', 'megablast',
            '-max_target_seqs', '1',
            '-max_hsps', '1',
            '-evalue', str(max_evalue),
            '-perc_identity', str(min_percent_identity),
            '-num_threads', str(num_threads)], 
        stdout=subprocess.PIPE,
        stdin=subprocess.PIPE)
    return blastcmd.communicate(input=seqfasta)[0].strip().split('\n')

def blast_compat_id(seq_id):
    '''
    Makes IDs BLAST-compatible.

    Blast+ truncates sequence IDs at the first whitespace, 
    then *usually* strips terminal semicolons from the remainder:
    '1;', '1;;;', '1; ;;;' all come back as '1', but '1; ;0;' becomes '1;'.
    Things get even weirder if the ID contains any tabs:
    '1s ;t\t' -> '1s;', '1s ;\tt' -> '1s', '1t\t;s ' -> '1t'!
        
    Why? Your guess is as good as mine. But we'll avoid the issue by using
    only the first word of the ID and then stripping *all* trailing semicolons.
    Note that we *do not* check whether IDs are unique after stripping --
    Make sure you ensure this beforehand!
    '''
    return seq_id.split()[0].strip(';')

class BlastPlusTaxonAssigner(BlastTaxonAssigner):
    def _get_blast_hits(self, blast_db, seqs):
        max_evalue = self.Params['Max E value']
        min_percent_identity = self.Params['Min percent identity']
        blast_db = self.Params['blast_db']
        num_threads = self.Params['num_threads']
        if min_percent_identity < 1.0:
            min_percent_identity *= 100.0

        seq_ids = [blast_compat_id(s[0]) for s in seqs]

        result = {}.fromkeys(seq_ids, [])

        blast_result = blastplus_seqtaxa(
            seqs = seqs, 
            blast_db = blast_db,
            max_evalue = max_evalue,
            min_percent_identity = min_percent_identity,
            num_threads = num_threads)

        # e is a list of 4 fields from one line: [seqid, taxid, e value, pct identity]
        for e in [x.split() for x in blast_result]:
            if (e and float(e[2]) <= max_evalue 
                and float(e[3]) >= min_percent_identity):
                result[e[0]] = (e[1], float(e[2]))

        return result

    def _get_first_blast_hit_per_seq(self, blast_hits):
        # We already limited Blast+ to one hit! 
        # Just need to filter out empty results.
        for k,v in blast_hits.items():
            if not v:
                blast_hits[k] = None
        return blast_hits



def main():
    option_parser, opts, args = parse_command_line_parameters(**script_info)

    if not opts.id_to_taxonomy_fp:
        option_parser.error('--id_to_taxonomy_fp is required.')

    assigner = BlastPlusTaxonAssigner({
        'Min percent identity': opts.min_percent_identity,
        'Max E value': opts.blast_e_value,
        'id_to_taxonomy_filepath': opts.id_to_taxonomy_fp,
        'blast_db': opts.blast_db,
        'num_threads': opts.n_threads
        })

    assigner(
        seq_path=opts.input_fasta_fp,
        result_path=opts.output_fp,
        log_path=opts.log_fp
        )

if __name__ == "__main__":
    main()
