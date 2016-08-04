#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=20,mem=100gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -N plant_its_presentref_nounassigned-20160725
#PBS -d /home/a-m/black11/no_backup/Fluidigm_2015813/

module load qiime

SHORT_JOBID=`echo $PBS_JOBID | sed 's/\..*//'`

# Starting from joined-end reads assembled by Pandaseq --
# prep these by running pair_pandaseq.sh before calling this script.

# Split libraries, assuming pandaseq did most of our quality filtering already.
# But do throw out unassigned sequences (=bad barcode reads).
# (Yes, I KNOW there seem like a lot of them, bub.
# But we don't know what sample they came from.
# There's nothing you can do, just let them go.)
(time split_libraries_fastq.py \
	--sequence_read_fps plant_its_pandaseq_joined/plant_its2_pspaired_cleanid.fastq \
	--barcode_read_fps plant_its_pandaseq_joined/barcodes_pspaired.fastq \
	--output_dir plant_its_slnoun_psp \
	--mapping_fps plant_ITS_map.txt \
	--barcode_type 10 \
	--phred_quality_threshold 0 \
	--phred_offset 33
) 2>&1 | tee -a split_nounassign-20160725.log

count_seqs.py -i plant_its_sl_psp/seqs.fna >> split_nounassign-20160725.log

(time pick_open_reference_otus.py \
	--input_fps plant_its_slnoun_psp/seqs.fna \
	--output_dir plant_its_presentref_noun_otu99_psp \
	--otu_picking_method uclust \
	--reference_fp ~black11/ncbi_its2/presentITS_otu_99/rep_set/99_otus_20160724.fasta  \
	--parameter_fp qiime_parameters.txt \
	--parallel \
	--jobs_to_start 20 \
	--suppress_align_and_tree
) 2>&1 | tee -a presentref_otu99noun-20160725.log

(time pick_open_reference_otus.py \
	--input_fps plant_its_slnoun_psp/seqs.fna \
	--output_dir plant_its_presentref_noun_otu97_psp \
	--otu_picking_method uclust \
	--reference_fp ~black11/ncbi_its2/presentITS_otu_97/rep_set/97_otus_20160724.fasta  \
	--parameter_fp qiime_parameters.txt \
	--parallel \
	--jobs_to_start 20 \
	--suppress_align_and_tree
) 2>&1 | tee -a presentref_otu97noun-20160725.log

# Remaining steps are a manual version of the align-and-tree portions of pick_open_reference_otus.py.
# Doing them by hand because pick_open_reference_otus has alignment method hard-coded to pynast,
# which needs a reference alignment, which isn't available for plant ITS region.
# Therefore:

# align de novo using MUSCLE.
(time align_seqs.py \
	--input_fasta_fp plant_its_presentref_noun_otu97_psp/rep_set.fna \
	--output_dir plant_its_presentref_noun_otu97_psp/muscle_aligned_seqs \
	--alignment_method muscle \
	--muscle_max_memory 80000
) 2>&1 | tee -a presentref_align97noun-20160725.log

(time align_seqs.py \
	--input_fasta_fp plant_its_presentref_noun_otu99_psp/rep_set.fna \
	--output_dir plant_its_presentref_noun_otu99_psp/muscle_aligned_seqs \
	--alignment_method muscle \
	--muscle_max_memory 80000
) 2>&1 | tee -a presentref_align99noun-20160725.log

# filter alignments to remove the parts of the template we didn't sequence
( time filter_alignment.py \
	--input_fasta_file plant_its_presentref_noun_otu97_psp/muscle_aligned_seqs/rep_set_aligned.fasta \
	--output_dir plant_its_presentref_noun_otu97_psp/muscle_aligned_seqs \
	--suppress_lane_mask_filter
) 2>&1 | tee -a presentref_align97noun-20160725.log

( time filter_alignment.py \
	--input_fasta_file plant_its_presentref_noun_otu99_psp/muscle_aligned_seqs/rep_set_aligned.fasta \
	--output_dir plant_its_presentref_noun_otu99_psp/muscle_aligned_seqs \
	--suppress_lane_mask_filter
) 2>&1 | tee -a presentref_align99noun-20160725.log

# Build phylogenetic tree from aligned sequences
# DISCLAIMER: I have no idea whether this tree will be informative!
(time make_phylogeny.py \
	--input_fp plant_its_presentref_noun_otu97_psp/muscle_aligned_seqs/rep_set_aligned_pfiltered.fasta \
	--result_fp plant_its_presentref_noun_otu97_psp/rep_muscle.tre \
	--log_fp plant_its_presentref_noun_otu97_psp/phylo_build.log
) 2>&1 | tee -a presentref_tree97noun-20160725.log

(time make_phylogeny.py \
	--input_fp plant_its_presentref_noun_otu99_psp/muscle_aligned_seqs/rep_set_aligned_pfiltered.fasta \
	--result_fp plant_its_presentref_noun_otu99_psp/rep_muscle.tre \
	--log_fp plant_its_presentref_noun_otu99_psp/phylo_build.log
) 2>&1 | tee -a presentref_tree99noun-20160725.log


echo "\nDiversity analysis at 97%\n" >> "$SHORT_JOBID".log

(time core_diversity_analyses.py \
	--output_dir plant_its_present97_noun_corediv \
	--input_biom_fp plant_its_presentref_noun_otu97_psp/otu_table_mc2_w_tax.biom \
	--mapping_fp plant_ITS_map.txt \
	--parameter_fp qiime_parameters.txt \
	--nonphylogenetic_diversity \
	--categories Block,Depth1,SampleType \
	--sampling_depth 2000 \
	--jobs_to_start 20 \
	--parallel
) 2>&1 | tee -a "$SHORT_JOBID".log


echo "\nDiversity analysis at 99%\n" >> "$SHORT_JOBID".log

(time core_diversity_analyses.py \
	--output_dir plant_its_present99_noun_corediv \
	--input_biom_fp plant_its_presentref_noun_otu99_psp/otu_table_mc2_w_tax.biom \
	--mapping_fp plant_ITS_map.txt \
	--parameter_fp qiime_parameters.txt \
	--nonphylogenetic_diversity \
	--categories Block,Depth1,SampleType \
	--sampling_depth 2000 \
	--jobs_to_start 20 \
	--parallel
) 2>&1 | tee -a "$SHORT_JOBID".log
