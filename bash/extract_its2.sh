#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=11,mem=20gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -N plant_its_extract_its2
#PBS -d .

# Use HMMs to extract the ITS2 region without any of the surrounding conserved 5.8S or SSU.

SHORT_JOBID=`echo $PBS_JOBID | sed 's/\..*//'`

INFILE=data/plant_its_sl/seqs_unique_mc2_nonchimera.fasta
OUTDIR=data/plant_its2_extracted
LOG=tmp/logs/ITSextract_"$SHORT_JOBID".log

mkdir -p "$OUTDIR"

module load ITSx/1.0.11

md5sum "$INFILE" >> "$LOG"

(time ITSx \
	-i "$INFILE" \
	-o "$OUTDIR"/ITSx_out \
	-t "Tracheophyta,Fungi,Bryophyta,Oomycota,Marchantiophyta" \
	--preserve T \
	--cpu 10 \
	--anchor 0 \
	--save_regions ITS2
) 2>&1 | tee -a "$LOG"

md5sum "$OUTDIR"/* >> "$LOG"
