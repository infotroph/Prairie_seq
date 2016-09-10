#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=11,mem=20gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -N plant_its_extract_its2
#PBS -d .
#PBS -t 0-3

# Use HMMs to extract the ITS2 region without any of the surrounding conserved 5.8S or SSU. 
# TODO: 
#	Consider whether we're checking the right groups (currently higher plants, fungi, oomycetes, mosses, liverworts, but no algae and no metazoans)
#	Test anchor regions: Do we want to leave some conserved bases at the end for alignment purposes?
#	Do I want to save partial regions? If so, how short? --partial 10 is probably too short for useful BLAST results.

SHORT_JOBID=`echo $PBS_JOBID | sed 's/\..*//'`

anchor_methods=("0" "10" "20" "hmm")
ANCHOR="${anchor_methods[$PBS_ARRAYID]}"


INFILE=rawdata/miseq/plant_its_sl/seqs_unique_mc2_nonchimera.fasta
OUTDIR=rawdata/miseq/plant_its2_extracted_a"$ANCHOR"
LOG=tmp/ITSextract_a"$ANCHOR"_"$SHORT_JOBID".log

mkdir -p "$OUTDIR"

module load ITSx/1.0.11

md5sum "$INFILE" >> "$LOG"

(time ITSx \
	-i "$INFILE" \
	-o "$OUTDIR"/ITSx_out \
	-t "Tracheophyta,Fungi,Bryophyta,Oomycota,Marchantiophyta" \
	--preserve T \
	--cpu 10 \
	--anchor "$ANCHOR" \
	--save_regions ITS2 \
	--partial 10
) 2>&1 | tee -a "$LOG"

md5sum "$OUTDIR"/* >> "$LOG"

# Next script will pick OTUs. 
# Our lives will be easier there if all files are collected in one place,
# which is easier to do now than then.
mkdir -p rawdata/miseq/plant_its_otu
ln -sf \
	"$PWD"/"$OUTDIR"/ITSx_out.ITS2.fasta \
	rawdata/miseq/plant_its_otu/its2_a"$ANCHOR".fasta
if [ ! -e rawdata/miseq/plant_its_otu/its2_whole.fasta ]; then
	ln -s \
		"$PWD"/"$INFILE" \
		rawdata/miseq/plant_its_otu/its2_whole.fasta
fi
