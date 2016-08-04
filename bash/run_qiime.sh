#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=10,mem=40gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -N plant_its_pspaired-20160722
#PBS -d /home/a-m/black11/no_backup/Fluidigm_2015813/

module load qiime

SHORT_JOBID=`echo $PBS_JOBID | sed 's/\..*//'`

# Starting from joined-end reads assembled by Pandaseq --
# prep these by running pair_pandaseq.sh before calling this script.

# Note quality threshold of 0 (should mean no filtering) --
# Proceeding on the assumptions that:
#	1. Pandaseq's quality scores are conceptually different from the raw Illumima scores, and using them for further quality filtering is explicitly discouraged in the Pandaseq documentation,
# 	2. Pandaseq should have already thrown out the low quality reads because they didn't pair well.
# TEST THESE ASSUMPTIONS!
# QIIME should still filter out sequences with N's in them,
# because --sequence_max_n defaults to 0.
# TEST THAT ASSUMPTION TOO!
(time split_libraries_fastq.py \
	--sequence_read_fps plant_its_pandaseq_joined/plant_its2_pspaired_cleanid.fastq \
	--barcode_read_fps plant_its_pandaseq_joined/barcodes_pspaired.fastq \
	--output_dir plant_its_sl_psp \
	--mapping_fps plant_ITS_map.txt \
	--barcode_type 10 \
	--phred_quality_threshold 0 \
	--phred_offset 33 \
	--retain_unassigned_reads
) 2>&1 | tee -a "$SHORT_JOBID".log

(count_seqs.py -i plant_its_sl_psp/seqs.fna) 2>&1 | tee -a "$SHORT_JOBID".log

# Runs most of the way through, but fails at filter alignment with
# ValueError: An empty fasta file was provided. Did the alignment complete sucessfully? Did PyNAST discard all sequences due to too-stringent minimum length or minimum percent ID settings?
(time pick_de_novo_otus.py \
	--input_fp plant_its_sl_psp/seqs.fna \
	--output_dir plant_its_denovo_otu_psp \
	--parallel \
	--jobs_to_start 10 ) 2>&1 | tee -a "$SHORT_JOBID".log

(biom summarize-table \
	-i plant_its_denovo_otu/otu_table_mc2_w_tax_no_pynast_failures.biom
) 2>&1 | tee -a "$SHORT_JOBID".log

time filter_samples_from_otu_table.py \
	--input_fp plant_its_denovo_otu_psp/otu_table.biom \
	--output_fp plant_its_denovo_otu_psp/otu_table_atleast1000reads.biom \
	--output_mapping_fp plant_its_denovo_otu_psp/plant_ITS_map_atleast1000reads.txt \
	--mapping_fp plant_ITS_map.txt \
	--min_count 1000


(time core_diversity_analyses.py \
	-o plant_its_corediv_psp \
	-i plant_its_denovo_otu_psp/otu_table_atleast1000reads.biom \
	-m plant_its_denovo_otu_psp/plant_ITS_map_atleast1000reads.txt \
	--nonphylogenetic_diversity \
	-c Block,Depth1,SampleType \
	-e 1000 ) 2>&1 | tee -a "$SHORT_JOBID".log
