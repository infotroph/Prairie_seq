#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=24,mem=20gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -N plant_its_otu
#PBS -d rawdata/miseq/plant_its_otu
#PBS -t 80,85,87,90,92,95,97,99

# Pick OTUs by de novo clustering with vsearch, look up taxonomy,
# and assemble into a sample-by-ptu table in BIOM format.

# We start from dereplicated, chimera-checked ITS2 regions. To prepare these, 
# run extract_its2.sh before calling this script.

# Trying several different similarity thresholds at once. 
# Similarities are passed as an array ("#PBS -t" line above) 
# so that they are run in parallel.

# Also testing several different lengths of conserved anchor on each side of the extracted ITS2 region,
# hence loops over multiple files for each step.

module load vsearch/2.0.4

SHORT_JOBID=`echo $PBS_JOBID | sed 's/\..*//'`

anchors=("whole" "a0" "a10" "a20" "ahmm")

# Cluster OTUs, then build sample-to-OTU table
for a in ${anchors[*]}; do 	
	vsearch \
		--cluster_size its2_"$a".fasta \
		--centroids otu_"$a"_"$PBS_ARRAYID".fasta \
		--id 0."$PBS_ARRAYID" \
		--sizein \
		--sizeout \
		--strand both \
		--fasta_width 0 \
		--threads 24 \
		--maxaccepts 0 \
		--maxrejects 0 \
		--log otu_"$a"_"$PBS_ARRAYID"_"$SHORT_JOBID".log
	md5sum \
		its2_"$a".fasta \
		otu_"$a"_"$PBS_ARRAYID".fasta \
		>> otu_"$a"_"$PBS_ARRAYID"_"$SHORT_JOBID".log

	vsearch \
		--usearch_global ../plant_its_sl/seqs.fna \
		--db otu_"$a"_"$PBS_ARRAYID".fasta \
		--uc "$a"_"$PBS_ARRAYID".uc \
		--strand both \
		--id 0."$PBS_ARRAYID" \
		--threads 24 \
		--maxaccepts 0 \
		--maxrejects 0 \
		--log build_"$a"_"$PBS_ARRAYID"_"$SHORT_JOBID".log
	md5sum \
		otu_"$a"_"$PBS_ARRAYID".fasta \
		"$a"_"$PBS_ARRAYID".uc \
		>> build_"$a"_"$PBS_ARRAYID"_"$SHORT_JOBID".log
done


# Now assign taxonomy to ref seqs
module purge
module load qiime
module load blast+

for a in ${anchors[*]}; do
	python ~/Prairie_seq/Python/assign_taxonomy_by_taxid.py \
		--input_fasta_fp otu_"$a"_"$PBS_ARRAYID".fasta \
		--output_fp "$a"_"$PBS_ARRAYID"_blast_taxonomies.txt \
		--id_to_taxonomy_fp ~/Prairie_seq/rawdata/ncbi_taxonomy/nt_taxonomy.txt \
		--log_fp assigntax_"$a"_"$PBS_ARRAYID"_"$SHORT_JOBID".log \
		--n_threads 3 \
		--min_percent_identity "$PBS_ARRAYID"
	md5sum \
		otu_"$a"_"$PBS_ARRAYID".fasta \
		"$a"_"$PBS_ARRAYID"_blast_taxonomies.txt \
		>> assigntax_"$a"_"$PBS_ARRAYID"_"$SHORT_JOBID".log
done


# Convert uc tables to biom format,
# then add taxonomy and sample metadata
module purge
module load biom-format/2.1.5

for a in ${anchors[*]}; do
	biom from-uc \
		--input-fp "$a"_"$PBS_ARRAYID".uc \
		--output-fp "$a"_"$PBS_ARRAYID".biom
	biom add-metadata \
		--input-fp "$a"_"$PBS_ARRAYID".biom \
		--output-fp "$a"_"$PBS_ARRAYID"_w_tax.biom \
		--sample-metadata-fp ~/Prairie_seq/rawdata/plant_ITS_map.txt \
		--observation-metadata-fp "$a"_"$PBS_ARRAYID"_blast_taxonomies.txt \
		--observation-header OTUID,taxonomy,evalue,taxid \
		--sc-separated taxonomy
	# biom-format 2.1.5 seems to leave the mandatory 'type' field null, producing an invalid biom file
	# (https://github.com/biocore/qiime/issues/1928, https://github.com/biocore/biom-format/issues/696, etc)
	# Dumb workaround: Correct this by 'converting' from json to json
	biom convert \
		--input-fp "$a"_"$PBS_ARRAYID"_w_tax.biom \
		--table-type "OTU table" \
		--to-json \
		--output-fp "$a"_"$PBS_ARRAYID".biom \
	&& rm "$a"_"$PBS_ARRAYID"_w_tax.biom
done
