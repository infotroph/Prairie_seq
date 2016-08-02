#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=10,mem=8000mb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -N plant_its_frombig-20160701
#PBS -d /home/a-m/black11/no_backup/Fluidigm_2015813/

module load qiime

time join_paired_ends.py \
	--forward_reads_fp plant_its/Plant_ITS2_Delucia_Fluidigm_R1.fastq \
	--reverse_reads_fp plant_its/Plant_ITS2_Delucia_Fluidigm_R2.fastq \
	--index_reads_fp plant_its/Plant_ITS2_Delucia_Fluidigm_I1_headers2to1.fastq \
	--output_dir plant_its_joined

time split_libraries_fastq.py \
	--sequence_read_fps plant_its_joined/fastqjoin.join.fastq \
	--barcode_read_fps plant_its_joined/fastqjoin.join_barcodes.fastq \
	--output_dir plant_its_sl \
	--mapping_fps plant_ITS_map.txt \
	--barcode_type 10 \
	--retain_unassigned_reads
	

count_seqs.py -i plant_its_sl/seqs.fna

# Runs most of the way through, but fails at filter alignment with
# ValueError: An empty fasta file was provided. Did the alignment complete sucessfully? Did PyNAST discard all sequences due to too-stringent minimum length or minimum percent ID settings?
time pick_de_novo_otus.py \
	--input_fp plant_its_sl/seqs.fna \
	--output_dir plant_its_denovo_otu \
	--parallel \
	--jobs_to_start 10

biom summarize-table \
	-i plant_its_denovo_otu/otu_table_mc2_w_tax_no_pynast_failures.biom

# This version assumes a fully sucessful OTU clustering
# time core_diversity_analyses.py \
# 	-o plant_its_corediv \
# 	-i plant_its_denovo_otu/otu_table_mc2_w_tax_no_pynast_failures.biom \
# 	-m plant_ITS_map.txt \
# 	-t plant_its_denovo_otu/rep_set.tre \
# 	-e 1000

time filter_samples_from_otu_table.py \
	--input_fp plant_its_denovo_otu/otu_table.biom \
	--output_fp plant_its_denovo_otu/otu_table_atleast1000reads.biom \
	--output_mapping_fp plant_its_denovo_otu/plant_ITS_map_atleast1000reads.txt \
	--mapping_fp plant_ITS_map.txt \
	--min_count 1000

time core_diversity_analyses.py \
	-o plant_its_corediv \
	-i plant_its_denovo_otu/otu_table_atleast1000reads.biom \
	-m plant_its_denovo_otu/plant_ITS_map_atleast1000reads.txt \
	--nonphylogenetic_diversity \
	-c Block,Depth1,SampleType \
	-e 1000
