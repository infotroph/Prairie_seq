#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=1,mem=2gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -N pair_pandaseq
#PBS -d rawdata/miseq

SHORT_JOBID=`echo $PBS_JOBID | sed 's/\..*//'`

RAW_FWDREADS=plant_its/Plant_ITS2_Delucia_Fluidigm_R1.fastq
RAW_REVREADS=plant_its/Plant_ITS2_Delucia_Fluidigm_R2.fastq
RAW_INDEX=plant_its/Plant_ITS2_Delucia_Fluidigm_I1.fastq

OUTDIR=plant_its_pandaseq_joined
mkdir -p "$OUTDIR"

# Joining paired-end reads from all reads sorted as 'Plant ITS2'
# in primer-sorted files from sequencing center.
# Start by trimming off primers and low-quality ends, and discard reads with the wrong primers --
# ~all 1.28M reads have our forward plant ITS2 primer (ATGCGATACTTGGTGTGAAT)
# but ~190k of the reverse reads have our 'fungal' ITS2 reverse primer (TCCTCCGCTTATTGATATGC)
# instead of the expected GACGCTTCTCCAGACTACAAT.
# Chimeras? Tag-switching? In any case we probably don't want them.

module load cutadapt

# -q 20: trim ends when 'average' quality drops below 20 (see cutadapt docs for gory details)
# --trimmed only: throw out anything not matching these primers
cutadapt \
	-g ATGCGATACTTGGTGTGAAT \
	-G GACGCTTCTCCAGACTACAAT \
	--error-rate=0.1 \
	-q 20 \
	--trimmed-only \
	-o "$OUTDIR"/R1_trim.fastq \
	-p "$OUTDIR"/R2_trim.fastq \
	"$RAW_FWDREADS" \
	"$RAW_REVREADS"

module purge
module load qiime

# Make a list of readnames we kept,
# converting read 1 indicator '1:N:0:' to index read indicator '2:N:0:'
sed -En 's/^@(HWI.*) 1:N:0:/\1 2:N:0:/p' \
        "$OUTDIR"/R1_trim.fastq \
        > "$OUTDIR"/tmp_R1_trim_names.txt

# Filter index reads to match trimmed reads
time filter_fasta.py \
        --input_fasta_fp "$RAW_INDEX" \
        --output_fasta_fp "$OUTDIR"/I1_trim.fastq \
        --seq_id_fp "$OUTDIR"/tmp_R1_trim_names.txt

module purge
module load pandaseq/2.10

# Pair ends.
# Using pandaseq defaults for these settings:
# -O (max overlap) unset
# -L (max length) unset
#	Haven't considered either of these carefully, don't expect them to matter.
#	May revisit later.
# -o (min overlap) unset
#	Default allows as little as 1 base overlap, but setting higher seems to
# 	force sequences to assemble at higher overlaps even if lower probabililty.
#	Instead, we leave -o unset and then remove the short overlaps after assembly
#	via -C min_overlapbits.

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
# -d (output flags)
#	Default is BFSrk.
#	Changed B to b so it doesn't log an INFO line for every dang read.
# -A (end-pairing algorithm)
# 	default is simple_bayesian.
#	Using rdp_mle, which is presented (Cole et al 2014, 10.1093/nar/gkt1244)
# 	as a corrected/improved version of the simple_bayesian algorithm.
# -t (alignment quality threshold)
#	default is 0.6, max advised is 0.9 (Masella et al 2012 10.1186/1471-2105-13-31)
#	In my testing this didn't affect results much, but using 0.8 because it does
#	eliminate a few bogus-looking assignments that aren't caught at 0.6.
# -C min_overlapbits:20 (Filter low-overlap reads after assembling)
#	default is to not filter.
#	argument is minimum "bits saved" -- see Cole et al 2014 10.1093/nar/gkt1244,
#	but for reads pretrimmed to q >= 20 it apporaches 2 bits per base of overlap,
#	i.e. 10-11 bases to equal 20 bits saved.

(time pandaseq \
	-f "$OUTDIR"/R1_trim.fastq \
	-r "$OUTDIR"/R2_trim.fastq \
	-i "$OUTDIR"/I1_trim.fastq \
	-w "$OUTDIR"/pspaired.fastq \
	-U "$OUTDIR"/failed_pspair.fastq \
	-C min_overlapbits:20 \
	-d bFSrk \
	-A rdp_mle \
	-l 25 \
	-k 10 \
	-T 1 \
	-t 0.8 \
	-F
) 2>&1 | tee -a "$OUTDIR"/pandaseq_"$SHORT_JOBID".log

# Pandaseq puts barcodes on the end of the sequence IDs.
# qiime expects barcode read IDs to be *identical* to forward reads, so we:

# * strip the barcodes off the Pandaseq IDs,
sed -E 's/^(@HWI.*):.*/\1/' \
	"$OUTDIR"/pspaired.fastq \
	> "$OUTDIR"/pspaired_cleanid.fastq
# 	(N.B. Don't delete this yet! Will need it for split_libraries_fastq)

# * strip the run ID ("2:N:0:") off the raw barcode IDs,
sed -E 's/^(@HWI.*) 2:N:0:$/\1/' \
	"$OUTDIR"/I1_trim.fastq \
	> "$OUTDIR"/raw_barcode_tmp.fastq

# * and store a table of clean read IDs.
sed -En 's/^@(HWI.*):.*/\1/p' \
	"$OUTDIR"/pspaired.fastq \
	> "$OUTDIR"/tmp_readnames.txt


# Now subset the barcodes to include only sequences pandaseq was able to assemble.
module purge
module load qiime
time filter_fasta.py \
	--input_fasta_fp "$OUTDIR"/raw_barcode_tmp.fastq \
	--output_fasta_fp "$OUTDIR"/barcodes_pspaired.fastq \
	--seq_id_fp "$OUTDIR"/tmp_readnames.txt

rm "$OUTDIR"/raw_barcode_tmp.fastq \
	"$OUTDIR"/tmp_readnames.txt \
	"$OUTDIR"/tmp_R1_trim_names.txt
