#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=10,mem=40gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -N plant_its_unpaired-20160701
#PBS -d /home/a-m/black11/no_backup/Fluidigm_2015813/

module load qiime

SHORT_JOBID=`echo $PBS_JOBID | sed 's/\..*//'`

(time split_libraries_fastq.py \
	--sequence_read_fps plant_its/Plant_ITS2_Delucia_Fluidigm_R1.fastq \
	--barcode_read_fps plant_its/Plant_ITS2_Delucia_Fluidigm_I1.fastq \
	--output_dir plant_its_unpaired_nounassigned_sl \
	--mapping_fps plant_ITS_map.txt \
	--barcode_type 10 ) 2>&1 | tee -a "$SHORT_JOBID".log

(count_seqs.py -i plant_its_unpaired_nounassigned_sl/seqs.fna ) 2>&1 | tee -a "$SHORT_JOBID".log


(time pick_de_novo_otus.py \
	--input_fp plant_its_unpaired_nounassigned_sl/seqs.fna \
	--output_dir plant_its_unpaired_nounassigned_denovo_otu \
	--parallel \
	--jobs_to_start 10 ) 2>&1 | tee -a "$SHORT_JOBID".log
# took ~2.5 hrs to run

# biom summarize-table \
# 	-i plant_its_unpaired_denovo_otu/otu_table_mc2_w_tax_no_pynast_failures.biom
(biom summarize-table \
	-i plant_its_unpaired_nounassigned_denovo_otu/otu_table.biom ) 2>&1 | tee -a "$SHORT_JOBID".log

(time core_diversity_analyses.py \
	-o plant_its_unpaired_nounassigned_corediv \
	-i plant_its_unpaired_nounassigned_denovo_otu/otu_table.biom \
	-m plant_ITS_map.txt \
	-t plant_its_unpaired_nounassigned_denovo_otu/rep_set.tre \
	--nonphylogenetic_diversity \
	-e 1000 ) 2>&1 | tee -a "$SHORT_JOBID".log
