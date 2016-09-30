#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=24,mem=20gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -N plant_its_otu
#PBS -d .
#PBS -t 80,85,87,90,92,95,97,99

# Pick OTUs by de novo clustering with vsearch, look up taxonomy,
# and assemble into a sample-by-otu table in BIOM format.

# We start from dereplicated, chimera-checked ITS2 regions. To prepare these, 
# run extract_its2.sh before calling this script.

# Trying several different similarity thresholds at once. 
# Similarities are passed as an array ("#PBS -t" line above) 
# so that they are run in parallel.

module load vsearch/2.0.4

SHORT_JOBID=`echo $PBS_JOBID | sed 's/\..*//'`

ITS2_FASTA=data/plant_its2_extracted/ITSx_out.ITS2.fasta
FULL_FASTA=data/plant_its_sl/seqs.fna
TAXONOMY_FILE=rawdata/ncbi_taxonomy/nt_taxonomy.txt
SAMPLE_MAP_FILE=rawdata/plant_ITS_map.txt
OTU_DIR=data/plant_its2_otu
mkdir -p "$OTU_DIR"

# Cluster OTUs, then build sample-to-OTU table
vsearch \
	--cluster_size "$ITS2_FASTA" \
	--centroids "$OTU_DIR"/otu_"$PBS_ARRAYID".fasta \
	--id 0."$PBS_ARRAYID" \
	--sizein \
	--sizeout \
	--strand both \
	--fasta_width 0 \
	--threads 24 \
	--maxaccepts 0 \
	--maxrejects 0 \
	--log "$OTU_DIR"/otu_"$PBS_ARRAYID"_"$SHORT_JOBID".log
md5sum \
	"$ITS2_FASTA" \
	"$OTU_DIR"/otu_"$PBS_ARRAYID".fasta \
	>> "$OTU_DIR"/otu_"$PBS_ARRAYID"_"$SHORT_JOBID".log

vsearch \
	--usearch_global "$FULL_FASTA" \
	--db "$OTU_DIR"/otu_"$PBS_ARRAYID".fasta \
	--uc "$OTU_DIR"/map_"$PBS_ARRAYID".uc \
	--strand both \
	--id 0."$PBS_ARRAYID" \
	--threads 24 \
	--maxaccepts 0 \
	--maxrejects 0 \
	--log "$OTU_DIR"/build_"$PBS_ARRAYID"_"$SHORT_JOBID".log
md5sum \
	"$FULL_FASTA" \
	"$OTU_DIR"/otu_"$PBS_ARRAYID".fasta \
	"$OTU_DIR"/map_"$PBS_ARRAYID".uc \
	>> "$OTU_DIR"/build_"$PBS_ARRAYID"_"$SHORT_JOBID".log

# Now assign taxonomy to ref seqs
module purge
module load qiime
module load blast+

python Python/assign_taxonomy_by_taxid.py \
	--input_fasta_fp "$OTU_DIR"/otu_"$PBS_ARRAYID".fasta \
	--output_fp "$OTU_DIR"/blast_taxonomies_"$PBS_ARRAYID".txt \
	--id_to_taxonomy_fp "$TAXONOMY_FILE" \
	--log_fp "$OTU_DIR"/assigntax_"$PBS_ARRAYID"_"$SHORT_JOBID".log \
	--n_threads 3 \
	--min_percent_identity "$PBS_ARRAYID"
md5sum \
	"$TAXONOMY_FILE" \
	"$OTU_DIR"/otu_"$PBS_ARRAYID".fasta \
	"$OTU_DIR"/blast_taxonomies_"$PBS_ARRAYID".txt \
	>> "$OTU_DIR"/assigntax_"$PBS_ARRAYID"_"$SHORT_JOBID".log


# Convert uc tables to biom format,
# then add taxonomy and sample metadata
module purge
module load biom-format/2.1.5

biom from-uc \
	--input-fp "$OTU_DIR"/map_"$PBS_ARRAYID".uc \
	--output-fp "$OTU_DIR"/plant_its2_"$PBS_ARRAYID".biom
biom add-metadata \
	--input-fp "$OTU_DIR"/plant_its2_"$PBS_ARRAYID".biom \
	--output-fp "$OTU_DIR"/plant_its2_"$PBS_ARRAYID"_w_tax.biom \
	--sample-metadata-fp "$SAMPLE_MAP_FILE" \
	--observation-metadata-fp "$OTU_DIR"/blast_taxonomies_"$PBS_ARRAYID".txt \
	--observation-header OTUID,taxonomy,evalue,taxid \
	--sc-separated taxonomy
# biom-format 2.1.5 seems to leave the mandatory 'type' field null, producing an invalid biom file
# (https://github.com/biocore/qiime/issues/1928, https://github.com/biocore/biom-format/issues/696, etc)
# Dumb workaround: Correct this by 'converting' from json to json
biom convert \
	--input-fp "$OTU_DIR"/plant_its2_"$PBS_ARRAYID"_w_tax.biom \
	--table-type "OTU table" \
	--to-json \
	--output-fp "$OTU_DIR"/plant_its2_"$PBS_ARRAYID".biom \
&& rm "$OTU_DIR"/plant_its2_"$PBS_ARRAYID"_w_tax.biom
