#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=20,mem=100gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -N plant_its_ncbiref
#PBS -d .

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
	--sequence_read_fps rawdata/miseq/plant_its_pandaseq_joined/pspaired_cleanid.fastq \
	--barcode_read_fps rawdata/miseq/plant_its_pandaseq_joined/barcodes_pspaired.fastq \
	--output_dir rawdata/miseq/plant_its_sl \
	--mapping_fps rawdata/plant_ITS_map.txt \
	--barcode_type 10 \
	--phred_quality_threshold 0 \
	--phred_offset 33
) 2>&1 | tee -a tmp/split_"$SHORT_JOBID".log

count_seqs.py -i rawdata/miseq/plant_its_sl/seqs.fna >> split_"$SHORT_JOBID".log

# Pick OTUs and taxonomy, using each of four possible reference sets.
# Taxonomy file has to be passed in parameters file, so a horrible hack:
# I'll copy the master qiime_parameters.txt to four temporary files,
# rewriting reference file names each time.
cp bash/qiime_parameters.txt tmp/params_pr97.txt
sed 's/present_97/present_99/' tmp/params_pr97.txt > tmp/params_pr99.txt
sed 's/present_97/plant_97/' tmp/params_pr97.txt > tmp/params_pl97.txt
sed 's/present_97/plant_99/' tmp/params_pr97.txt > tmp/params_pl99.txt

(time pick_open_reference_otus.py \
	--input_fps rawdata/miseq/plant_its_sl/seqs.fna \
	--output_dir rawdata/miseq/plant_its_present97_otu \
	--reference_fp data/its2_ref/ncbi_present_97.fasta \
	--parameter_fp tmp/params_pr97.txt \
	--otu_picking_method uclust \
	--parallel \
	--suppress_align_and_tree
) 2>&1 | tee -a tmp/pr97_"$SHORT_JOBID".log


(time pick_open_reference_otus.py \
	--input_fps rawdata/miseq/plant_its_sl/seqs.fna \
	--output_dir rawdata/miseq/plant_its_present99_otu \
	--reference_fp data/its2_ref/ncbi_present_99.fasta \
	--parameter_fp tmp/params_pr99.txt \
	--otu_picking_method uclust \
	--parallel \
	--suppress_align_and_tree
) 2>&1 | tee -a tmp/pr99_"$SHORT_JOBID".log

(time pick_open_reference_otus.py \
	--input_fps rawdata/miseq/plant_its_sl/seqs.fna \
	--output_dir rawdata/miseq/plant_its_plant97_otu \
	--reference_fp data/its2_ref/ncbi_plant_97.fasta \
	--parameter_fp tmp/params_pl97.txt \
	--otu_picking_method uclust \
	--parallel \
	--suppress_align_and_tree
) 2>&1 | tee -a tmp/pl97_"$SHORT_JOBID".log

(time pick_open_reference_otus.py \
	--input_fps rawdata/miseq/plant_its_sl/seqs.fna \
	--output_dir rawdata/miseq/plant_its_plant99_otu \
	--reference_fp data/its2_ref/ncbi_plant_99.fasta \
	--parameter_fp tmp/params_pl99.txt \
	--otu_picking_method uclust \
	--parallel \
	--suppress_align_and_tree
) 2>&1 | tee -a tmp/pl99_"$SHORT_JOBID".log

# Probably going to delete everything below, but for now let's just bail
echo "Not attempting alignment or diversity analysis. Exiting now!"
exit 

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
