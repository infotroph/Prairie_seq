#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=1,mem=10gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -N get_ncbi_tax
#PBS -d /home/a-m/black11/Prairie_seq

# Download the full NCBI taxonomy database and assemble it into a mapping from taxid to lineage.
# Sample output from nt_taxonomy.txt:
# 79824	Eukaryota;Viridiplantae;Streptophyta;Liliopsida;Poales;Poaceae;Andropogon;Andropogon gerardii


TAXSRVR="ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy"
mkdir -p rawdata/ncbi_taxonomy

module load qiime

curl "$TAXSRVR/tax{dump,cat}_readme.txt" -o "rawdata/ncbi_taxonomy/tax#1_readme.txt"
curl "$TAXSRVR/taxdump.tar.{gz,gz.md5}" -o "rawdata/ncbi_taxonomy/taxdump.tar.#1"
(cd rawdata/ncbi_taxonomy \
        && md5sum -c taxdump.tar.gz.md5 \
        && tar -xvf taxdump.tar.gz \
        && cd -)

python Python/ncbidump_to_qiimetax.py \
	rawdata/ncbi_taxonomy/nodes.dmp \
	rawdata/ncbi_taxonomy/names.dmp \
	> rawdata/ncbi_taxonomy/nt_taxonomy.txt

# If you don't need all branches of the tree, I recommend
# building the whole file and then filtering afterwards, e.g.
# grep 'Yourtaxoneae' nt_taxonomy.txt > nt_just_your_taxonomy.txt

# If you want to look up taxonomy by NCBI accession number,
# you'll need the accession-to-taxid mapping file, which is 4 GB large
# and lives at $TAXSRVR/accession2taxid/nucl_gb.accession2taxid.gz,
# but I haven't played with it, so you're on your own.
# You'll probably need to edit ncbi_to_qiimetax.py heavily as well.
