#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=1,mem=2gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -N pair_pandaseq
#PBS -d rawdata/miseq

module load pandaseq/2.10

SHORT_JOBID=`echo $PBS_JOBID | sed 's/\..*//'`

RAWDIR=plant_its
OUTDIR=plant_its_pandaseq_joined
mkdir -p "$OUTDIR"

# Attempting to join paired-end reads from all reads sorted as 'Plant ITS2'
# in primer-sorted files from sequencing center.
# N.B. Reverse file appears to contain some reads from 'universal' ITS primer 
# (TCCTCCGCTTATTGATATGC) -- ~183k out of 1.28M total,
# compared to ~830k from intended primer GACGCTTCTCCAGACTACAAT
# Forward read seems ~uncontaminated: ATGCGATACTTGGTGTGAAT in ~1.1M of 1.28M total reads

# TODO: Do I need to re-sort files or otherwise filter the universal reverse seqs out? Are there plant ITS seqs hiding in the universal primer reverse files?

# Using pandaseq defaults for these settings:
# -o (min overlap) 1
#	Manual says increasing this doesn't usually change much,
#	because seqs with little overlap tend to fail the alignment quality tests anyway.
# -O (max overlap) unset
# -L (max length) unset
#	Haven't considered either of these carefully, don't expect them to matter.
#	May revisit later.
# -t (alignment quality threshold)
#	default is 0.6, max advised is 0.9 (Masella et al 2012 10.1186/1471-2105-13-31)
#	I tried 0.6,0.7,0.8, 0.9, saw only small reductions in either 
#	total sequence count or number of singletons 
#	==> doesn't seem to make a huge difference for this dataset.
#	May revisit later after the rest of the pipeline is set.

# Rationale for non-default settings:
# -l (minimum length after primers are removed)
#	arbitrarily chosen, just needed to be >0 to avoid returning empty strings from a few reads
# -k (number of locations to store per k-mer)
#	Needs to be high to avoid lots of 'FML' errors from repetitive sequences.
#	Pandaseq manual says this should be small and "no more than 10"
#	I tested values 1-10, all <10 produce lots of FMLs. Still get a few with 10, but not oodles.
# -T (number of thread to spawn)
#	Keeping this at 1 because it runs in ~5 minutes even with 1 thread.
#	Would be faster with >1 thread, but output would be in a different order than the input,
#	which makes downstream filtering of barcodes enough more annoying than the speed hit.
# -F (write output as fastq)
#	This seems to be the easiest way to get output from pandaseq into QIIME.
#	Depending whether QIIME actually uses the quality scores in the barcode file,
#	might be worth dropping this and producing a single FASTA with integrated barcodes.

(time pandaseq \
	-f "$RAWDIR"/Plant_ITS2_Delucia_Fluidigm_R1.fastq \
	-r "$RAWDIR"/Plant_ITS2_Delucia_Fluidigm_R2.fastq \
	-i "$RAWDIR"/Plant_ITS2_Delucia_Fluidigm_I1.fastq \
	-w "$OUTDIR"/pspaired.fastq \
	-U "$OUTDIR"/failed_pspair.fastq \
	-g "$OUTDIR"/log.txt \
	-p ATGCGATACTTGGTGTGAAT \
	-q GACGCTTCTCCAGACTACAAT \
	-l 25 \
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
