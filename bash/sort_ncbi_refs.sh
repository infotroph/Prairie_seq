#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=1,mem=4gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -d rawdata/ncbi_its2
#PBS -N sort_refs

# Turn *plant* ITS sequences scraped from Genbank into a reference OTU set 
# as demonstrated in the datasets linked from QIIME *fungal* ITS analysis tutorial. 

# Uses sort_seqs.py and nested_reference_workflow.py, both from https://github.com/qiime/nested_reference_otus.
# To install:
# cd ~ # or wherever you like, just edit PATHs below to match
# git clone https://github.com/qiime/nested_reference_otus
# To tell this script how to find them:
export PYTHONPATH=$PYTHONPATH:~/nested_reference_otus
export PATH=$PATH:~/nested_reference_otus/scripts

echo "starting at " `date -u` >> sort_refs.log
module load qiime
SHORT_JOBID=`echo $PBS_JOBID | sed 's/\..*//'`

# First, prep reference sequences by blacklisting some unwanted categories.
# unwanted_accessions.txt was created by grepping the headers of my
# raw `ncbi_all_plant_its2_longid.fasta` for:
# 	"[Cc]hloroplast" because I'm only interested in nuclear genes,
# 	"[Gg]enome" to remove seven whole carrot chromosomes--
#		they alone take up 166 MB & we have plenty of shorter carrot ITS sequences.
# If redoing this with updated ref seqs, update your unwanted_accessions.txt as well!

(filter_fasta.py \
	--input_fasta_fp present_genera_its2.fasta \
	--output_fasta_fp present_wanted.fasta \
	--seq_id_fp unwanted_accessions.txt \
	--negate
filter_fasta.py \
	--input_fasta_fp ncbi_all_plant_its2.fasta \
	--output_fasta_fp plant_wanted.fasta \
	--seq_id_fp unwanted_accessions.txt \
	--negate
) 2>&1 | tee -a sort_refs.log


# cutadapt and qiime load incompatible Python versions, must purge between uses
module purge
module load cutadapt

# Trim off our ITS primers and everything upstream/downstream of them, if present
# Seqs with no match to primers are left untrimmed.
# --error_rate is allowable mismatches per primer (0.1 = 10% = 2 bases)
# --times 2 because otherwise cutadapt would stop after trimming just one end (???)
#
# cutadapt may complain of possible 'incomplete adapter sequences' on plant_cut.fasta
# This is just because the last base before the primer is highly conserved --
# This is in fact the whole [reverse complement of our] ITS primer.

(cutadapt \
	-g ATGCGATACTTGGTGTGAAT \
	-a ATTGTAGTCTGGAGAAGCGTC \
	--times=2 \
	--error-rate=0.1 \
	present_wanted.fasta > present_cut.fasta
cutadapt \
	-g ATGCGATACTTGGTGTGAAT \
	-a ATTGTAGTCTGGAGAAGCGTC \
	--times=2 \
	--error-rate=0.1 \
	plant_wanted.fasta > plant_cut.fasta
) 2>&1 | tee -a sort_refs.log

module purge
module load qiime

# sort_seqs is picky about file format; header line must be exactly as shown.
awk 'BEGIN {print "ID Number\tGenBank Number\tNew Taxon String\tSource"}
	 {print $1"\t"$0"\tncbi_present"}' \
	present_genera_its2_accession_taxonomy.txt > present_taxonomy.txt
awk 'BEGIN {print "ID Number\tGenBank Number\tNew Taxon String\tSource"}
	 {print $1"\t"$0"\tncbi_plants"}' \
	ncbi_all_plant_its2_accession_taxonomy.txt > plant_taxonomy.txt

(
time sort_seqs.py \
	--input_fasta present_cut.fasta \
	--input_taxonomy_map present_taxonomy.txt \
	--output_fp present_sorted.fasta

time sort_seqs.py \
	--input_fasta plant_cut.fasta \
	--input_taxonomy_map plant_taxonomy.txt \
	--output_fp plant_sorted.fasta

time nested_reference_workflow.py \
	--input_fasta_fp present_sorted.fasta \
	--output_dir "present_tmp_97" \
	--run_id "$SHORT_JOBID" \
	--similarity_thresholds 97

time nested_reference_workflow.py \
	--input_fasta_fp present_sorted.fasta \
	--output_dir "present_tmp_99" \
	--run_id "$SHORT_JOBID" \
	--similarity_thresholds 99

time nested_reference_workflow.py \
	--input_fasta_fp plant_sorted.fasta \
	--output_dir "plant_tmp_97" \
	--run_id "$SHORT_JOBID" \
	--similarity_thresholds 97

time nested_reference_workflow.py \
	--input_fasta_fp plant_sorted.fasta \
	--output_dir "plant_tmp_99" \
	--run_id "$SHORT_JOBID" \
	--similarity_thresholds 99
) 2>&1 | tee -a sort_refs.log

# Save clustered representative sequences to a more convenient path.
cp present_tmp_97/rep_set/97_otus_"$SHORT_JOBID".fasta \
	data/its_ref/ncbi_present_97.fasta
cp present_tmp_99/rep_set/99_otus_"$SHORT_JOBID".fasta \
	data/its_ref/ncbi_present_99.fasta
cp plant_tmp_97/rep_set/97_otus_"$SHORT_JOBID".fasta \
	data/its_ref/ncbi_plant_97.fasta
cp plant_tmp_99/rep_set/99_otus_"$SHORT_JOBID".fasta \
	data/its_ref/ncbi_plant_99.fasta

# filter taxonomies down to match picked sequence sets.
python filter_taxonomy.py \
	present_genera_its2_accession_taxonomy.txt \
	presentITS_otu_97/rep_set/97_otus_"$SHORT_JOBID".fasta \
	> data/its_ref/ncbi_present_97_taxonomy.txt

python filter_taxonomy.py \
	present_genera_its2_accession_taxonomy.txt \
	presentITS_otu_99/rep_set/99_otus_"$SHORT_JOBID".fasta \
	> data/its_ref/ncbi_present_99_taxonomy.txt


python filter_taxonomy.py \
	ncbi_all_plant_its2_accession_taxonomy.txt \
	plantITS_otu_97/rep_set/97_otus_"$SHORT_JOBID".fasta \
	> data/its_ref/ncbi_plant_97_taxonomy.txt

python filter_taxonomy.py \
	ncbi_all_plant_its2_accession_taxonomy.txt \
	plantITS_otu_99/rep_set/99_otus_"$SHORT_JOBID".fasta \
	> data/its_ref/ncbi_plant_99_taxonomy.txt

echo "done at " `date -u` >> sort_refs.log
