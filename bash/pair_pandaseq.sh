#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=1,mem=2gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -N pair_pandaseq_20160712
#PBS -d /home/a-m/black11/no_backup/Fluidigm_2015813/

module load pandaseq/2.10

SHORT_JOBID=`echo $PBS_JOBID | sed 's/\..*//'`

OUTDIR=plant_its_pandaseq_fq_joined
mkdir -p "$OUTDIR"

# Attempting to join paired-end reads from all reads sorted as 'Plant ITS2'
# in primer-sorted files from sequencing center.
# N.B. Reverse file appears to contain some reads from 'universal' ITS primer 
# (TCCTCCGCTTATTGATATGC) -- ~183k out of 1.28M total,
# compared to ~830k from intended primer GACGCTTCTCCAGACTACAAT
# Forward read seems ~uncontaminated: ATGCGATACTTGGTGTGAAT in ~1.1M of 1.28M total reads

# TODO: Do I need to re-sort files or otherwise filter the universal reverse seqs out? Are there plant ITS seqs hiding in the universal primer reverse files?

# Using default pandaseq quality settings: 
# -o (min overlap) 1
# -O (max overlap) unset
# -t (aligment quality threshold) 0.6
# -l (min length) unset
# -L (max length) unset
#
(time pandaseq \
	-f plant_its/Plant_ITS2_Delucia_Fluidigm_R1.fastq \
	-r plant_its/Plant_ITS2_Delucia_Fluidigm_R2.fastq \
	-i plant_its/Plant_ITS2_Delucia_Fluidigm_I1.fastq \
	-w "$OUTDIR"/plant_its2_pspaired.fastq \
	-U "$OUTDIR"/unpaired.fastq \
	-g "$OUTDIR"/log.txt \
	-p ATGCGATACTTGGTGTGAAT \
	-q GACGCTTCTCCAGACTACAAT \
	-k 10 \
	-T 1 \
	-F
) 2>&1 | tee -a "$OUTDIR"/torque_"$SHORT_JOBID".log

# Pandaseq puts barcodes on the end of the sequence IDs.
# qiime expects barcode read IDs to be *identical* to forward reads, so we:

# * strip the barcodes off the Pandaseq IDs,
sed -E 's/^(@HWI.*):.*/\1/' \
	"$OUTDIR"/plant_its2_pspaired.fastq \
	> "$OUTDIR"/plant_its2_pspaired_cleanid.fastq
# 	(N.B. Don't delete this yet! Will need it for split_libraries_fastq)

# * strip the run ID ("2:N:0:") off the raw barcode IDs,
sed -E 's/^(@HWI.*) 2:N:0:$/\1/' \
	plant_its/Plant_ITS2_Delucia_Fluidigm_I1.fastq \
	> "$OUTDIR"/raw_barcode_tmp.fastq

# * and store a table of clean read IDs.
sed -En 's/^@(HWI.*):.*/\1/p' \
	"$OUTDIR"/plant_its2_pspaired.fastq \
	> "$OUTDIR"/tmp_readnames.txt


# Now subset the barcodes to include only sequences pandaseq was able to assemble.
module purge
module load qiime
time filter_fasta.py \
	--input_fasta_fp "$OUTDIR"/raw_barcode_tmp.fastq \
	--output_fasta_fp "$OUTDIR"/barcodes_pspaired.fastq \
	--seq_id_fp "$OUTDIR"/tmp_readnames.txt

rm "$OUTDIR"/raw_barcode_tmp.fastq \
	"$OUTDIR"/tmp_readnames.txt
