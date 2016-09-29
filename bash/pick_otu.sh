#!/bin/bash

#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=24,mem=20gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -N plant_its_otu
#PBS -d data/plant_its2_otu
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

# Cluster OTUs, then build sample-to-OTU table
vsearch \
	--cluster_size ../plant_its2_extracted/ITSx_out.ITS2.fasta \
	--centroids otu_"$PBS_ARRAYID".fasta \
	--id 0."$PBS_ARRAYID" \
	--sizein \
	--sizeout \
	--strand both \
	--fasta_width 0 \
	--threads 24 \
	--maxaccepts 0 \
	--maxrejects 0 \
	--log otu_"$PBS_ARRAYID"_"$SHORT_JOBID".log
md5sum \
	../plant_its2_extracted/ITSx_out.ITS2.fasta \
	otu_"$PBS_ARRAYID".fasta \
	>> otu_"$PBS_ARRAYID"_"$SHORT_JOBID".log

vsearch \
	--usearch_global ../plant_its_sl/seqs.fna \
	--db otu_"$PBS_ARRAYID".fasta \
	--uc map_"$PBS_ARRAYID".uc \
	--strand both \
	--id 0."$PBS_ARRAYID" \
	--threads 24 \
	--maxaccepts 0 \
	--maxrejects 0 \
	--log build_"$PBS_ARRAYID"_"$SHORT_JOBID".log
md5sum \
	otu_"$PBS_ARRAYID".fasta \
	map_"$PBS_ARRAYID".uc \
	>> build_"$PBS_ARRAYID"_"$SHORT_JOBID".log

# Now assign taxonomy to ref seqs
module purge
module load qiime
module load blast+

python ~/Prairie_seq/Python/assign_taxonomy_by_taxid.py \
	--input_fasta_fp otu_"$PBS_ARRAYID".fasta \
	--output_fp blast_taxonomies_"$PBS_ARRAYID".txt \
	--id_to_taxonomy_fp ~/Prairie_seq/rawdata/ncbi_taxonomy/nt_taxonomy.txt \
	--log_fp assigntax_"$PBS_ARRAYID"_"$SHORT_JOBID".log \
	--n_threads 3 \
	--min_percent_identity "$PBS_ARRAYID"
md5sum \
	~/Prairie_seq/rawdata/ncbi_taxonomy/nt_taxonomy.txt \
	otu_"$PBS_ARRAYID".fasta \
	blast_taxonomies_"$PBS_ARRAYID".txt \
	>> assigntax_"$PBS_ARRAYID"_"$SHORT_JOBID".log


# Convert uc tables to biom format,
# then add taxonomy and sample metadata
module purge
module load biom-format/2.1.5

biom from-uc \
	--input-fp map_"$PBS_ARRAYID".uc \
	--output-fp plant_its2_"$PBS_ARRAYID".biom
biom add-metadata \
	--input-fp plant_its2_"$PBS_ARRAYID".biom \
	--output-fp plant_its2_"$PBS_ARRAYID"_w_tax.biom \
	--sample-metadata-fp ~/Prairie_seq/rawdata/plant_ITS_map.txt \
	--observation-metadata-fp blast_taxonomies_"$PBS_ARRAYID".txt \
	--observation-header OTUID,taxonomy,evalue,taxid \
	--sc-separated taxonomy
# biom-format 2.1.5 seems to leave the mandatory 'type' field null, producing an invalid biom file
# (https://github.com/biocore/qiime/issues/1928, https://github.com/biocore/biom-format/issues/696, etc)
# Dumb workaround: Correct this by 'converting' from json to json
biom convert \
	--input-fp plant_ots2_"$PBS_ARRAYID"_w_tax.biom \
	--table-type "OTU table" \
	--to-json \
	--output-fp plant_its2_"$PBS_ARRAYID".biom \
&& rm plant_its2_"$PBS_ARRAYID"_w_tax.biom
