#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=1,mem=40gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -N pair_pandaseq_20160711
#PBS -d /home/a-m/black11/no_backup/Fluidigm_2015813/

module load pandaseq

SHORT_JOBID=`echo $PBS_JOBID | sed 's/\..*//'`

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
# Non-default settings that aren't obvious from their names:
# -B to allow files with no barcode/tag. TODO: consider converting index reads into tags before assembling?
(time pandaseq \
	-f plant_its/Plant_ITS2_Delucia_Fluidigm_R1.fastq \
	-r plant_its/Plant_ITS2_Delucia_Fluidigm_R2.fastq \
	-g plant_its_pandaseq_joined/log.txt \
	-p ATGCGATACTTGGTGTGAAT \
	-q GACGCTTCTCCAGACTACAAT \
	-u plant_its_pandaseq_joined/unpaired.txt \
	-B \
	-w plant_its_pandaseq_joined/plant_its2_pspaired.fasta 
) 2>&1 | tee -a plant_its_pandaseq_joined/torque_"$SHORT_JOBID".log
