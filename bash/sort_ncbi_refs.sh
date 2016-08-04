#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=1,mem=4gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -d /home/a-m/black11/ncbi_its2
#PBS -N sort_refs-20160724

module load qiime

# Turn *plant* ITS sequences scraped from Genbank into a reference OTU set 
# as demonstrated in the datasets linked from QIIME *fungal* ITS analysis tutorial. 

# Uses the nested reference OTUs workflow from https://github.com/qiime/nested_reference_otus, To install:
# cd ~
# git clone https://github.com/qiime/nested_reference_otus


export PYTHONPATH=$PYTHONPATH:~black11/nested_reference_otus

# sort_seqs is picky about file format; header line must be exactly as shown.
awk 'BEGIN {print "ID Number\tGenBank Number\tNew Taxon String\tSource"}
	{print $1"\t"$0"\tncbi_present"}' \
	present_genera_its2_accession_taxonomy.txt > its2_taxonomy_present.txt
awk 'BEGIN {print "ID Number\tGenBank Number\tNew Taxon String\tSource"}
	 {print $1"\t"$0"\tncbi_plants"}' \
	ncbi_all_plant_its2_accession_taxonomy.txt > its2_taxonomy_plants.txt

(
time ~black11/nested_reference_otus/scripts/sort_seqs.py \
	--input_fasta present_genera_its2.fasta \
	--input_taxonomy_map its2_taxonomy_present.txt \
	--output_fp present_genera_its2_sorted.fasta

time ~black11/nested_reference_otus/scripts/sort_seqs.py \
	--input_fasta ncbi_all_plant_its2.fasta \
	--input_taxonomy_map its2_taxonomy_plants.txt \
	--output_fp ncbi_all_plant_its2_sorted.fasta

time ~black11/nested_reference_otus/scripts/nested_reference_workflow.py \
	--input_fasta_fp present_genera_its2_sorted.fasta \
	--output_dir "presentITS_otu_97" \
	--run_id "20160724" \
	--similarity_thresholds 97

time ~black11/nested_reference_otus/scripts/nested_reference_workflow.py \
	--input_fasta_fp present_genera_its2_sorted.fasta \
	--output_dir "presentITS_otu_99" \
	--run_id "20160724" \
	--similarity_thresholds 99

# Both all-plant DBs fail clustering with "improperly formatted input file was provided" -- try binary search to check for illegal characters?
time ~black11/nested_reference_otus/scripts/nested_reference_workflow.py \
	--input_fasta_fp ncbi_all_plant_its2_sorted.fasta \
	--output_dir "plantITS_otu_97" \
	--run_id "20160724" \
	--similarity_thresholds 97

time ~black11/nested_reference_otus/scripts/nested_reference_workflow.py \
	--input_fasta_fp ncbi_all_plant_its2_sorted.fasta \
	--output_dir "plantITS_otu_99" \
	--run_id "20160724" \
	--similarity_thresholds 99
) 2>&1 | tee -a sort_refs.log
