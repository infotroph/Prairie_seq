#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=11,mem=1gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -o tmp/logs/
#PBS -N plant_its_split_derep
#PBS -d .

module load qiime

SHORT_JOBID=`echo $PBS_JOBID | sed 's/\..*//'`

INDIR=data/miseq/plant_its_joined
OUTDIR=data/plant_its_sl
mkdir -p "$OUTDIR"

# Starting from joined-end reads assembled by Pandaseq --
# prep these by running pair_ends.sh before calling this script.

# Split libraries. No quality filtering because pandaseq did it already,
# but do throw out unassigned sequences (=bad barcode reads).
split_libraries_fastq.py \
	--sequence_read_fps "$INDIR"/pspaired_cleanid.fastq \
	--barcode_read_fps "$INDIR"/barcodes_pspaired.fastq \
	--output_dir "$OUTDIR" \
	--mapping_fps rawdata/plant_ITS_map.txt \
	--barcode_type 10 \
	--phred_quality_threshold 0 \
	--phred_offset 33

module purge
module load vsearch/2.0.4

# dereplicate, discard singletons, remove suspected chimeras
vsearch \
	--derep_fulllength "$OUTDIR"/seqs.fna \
	--sizeout \
	--relabel_sha1 \
	--threads 10 \
	--fasta_width 0 \
	--minuniquesize 2 \
	--log tmp/dereplicate_"$SHORT_JOBID".log \
	--output - \
| vsearch \
	--uchime_denovo - \
	--nonchimeras "$OUTDIR"/seqs_unique_mc2_nonchimera.fasta \
	--chimeras "$OUTDIR"/seqs_unique_mc2_chimera.fasta \
	--sizein \
	--sizeout \
	--fasta_width 0 \
	--threads 1 \
	--log tmp/chimeracheck_"$SHORT_JOBID".log 

cat tmp/chimeracheck_"$SHORT_JOBID".log >> tmp/dereplicate_"$SHORT_JOBID".log \
	&& rm tmp/chimeracheck_"$SHORT_JOBID".log
(
echo "input:"
md5sum "$OUTDIR"/seqs.fna
echo "outputs:"
md5sum \
	"$OUTDIR"/seqs_unique_mc2_nonchimera.fasta \
	"$OUTDIR"/seqs_unique_mc2_chimera.fasta
) >> tmp/dereplicate_"$SHORT_JOBID".log
