#PBS -S /bin/bash
#PBS -q default
#PBS -l nodes=1:ppn=4,mem=20gb
#PBS -M black11@igb.illinois.edu
#PBS -m abe
#PBS -j oe
#PBS -N plant_its_reblast
#PBS -d rawdata/miseq/plant_its_otu
#PBS -t 80,85,87,90,92,95,97,99


# Re-assigning taxonomies to try altered blast parameters without waiting for clustering to rerun. 
# Hopefully a one-off, but if you run this again that's a sign you should pull all the taxonomy assignment
# out of pick_otu.sh into its own script -- notice that's essentially what this is!

SHORT_JOBID=`echo $PBS_JOBID | sed 's/\..*//'`
anchors=("whole" "a0" "a10" "a20" "ahmm")

module load qiime
module load blast+

for a in ${anchors[*]}; do
	python ~/Prairie_seq/Python/assign_taxonomy_by_taxid.py \
		--input_fasta_fp otu_"$a"_"$PBS_ARRAYID".fasta \
		--output_fp "$a"_"$PBS_ARRAYID"_blast_taxonomies_id90pct.txt \
		--id_to_taxonomy_fp ~/Prairie_seq/rawdata/ncbi_taxonomy/nt_taxonomy.txt \
		--log_fp assigntax_id90pct_"$a"_"$PBS_ARRAYID"_"$SHORT_JOBID".log \
		--n_threads 3 \
		--min_percent_identity 90
	md5sum \
		otu_"$a"_"$PBS_ARRAYID".fasta \
		"$a"_"$PBS_ARRAYID"_blast_taxonomies_id90pct.txt \
		>> assigntax_id90pct_"$a"_"$PBS_ARRAYID"_"$SHORT_JOBID".log

	python ~/Prairie_seq/Python/assign_taxonomy_by_taxid.py \
		--input_fasta_fp otu_"$a"_"$PBS_ARRAYID".fasta \
		--output_fp "$a"_"$PBS_ARRAYID"_blast_taxonomies_id95pct.txt \
		--id_to_taxonomy_fp ~/Prairie_seq/rawdata/ncbi_taxonomy/nt_taxonomy.txt \
		--log_fp assigntax_id95pct_"$a"_"$PBS_ARRAYID"_"$SHORT_JOBID".log \
		--n_threads 3 \
		--min_percent_identity 95
	md5sum \
		otu_"$a"_"$PBS_ARRAYID".fasta \
		"$a"_"$PBS_ARRAYID"_blast_taxonomies_id95pct.txt \
		>> assigntax_id95pct_"$a"_"$PBS_ARRAYID"_"$SHORT_JOBID".log
done



module purge
module load biom-format/2.1.5

for a in ${anchors[*]}; do
	biom add-metadata \
		--input-fp "$a"_"$PBS_ARRAYID".biom \
		--output-fp "$a"_"$PBS_ARRAYID"_blast90.biom \
		--sample-metadata-fp ~/Prairie_seq/rawdata/plant_ITS_map.txt \
		--observation-metadata-fp "$a"_"$PBS_ARRAYID"_blast_taxonomies_id90pct.txt \
		--observation-header OTUID,taxonomy,evalue,taxid \
		--sc-separated taxonomy
	biom add-metadata \
		--input-fp "$a"_"$PBS_ARRAYID".biom \
		--output-fp "$a"_"$PBS_ARRAYID"_blast95.biom \
		--sample-metadata-fp ~/Prairie_seq/rawdata/plant_ITS_map.txt \
		--observation-metadata-fp "$a"_"$PBS_ARRAYID"_blast_taxonomies_id95pct.txt \
		--observation-header OTUID,taxonomy,evalue,taxid \
		--sc-separated taxonomy
done
