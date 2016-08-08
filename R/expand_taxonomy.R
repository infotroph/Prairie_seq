
# Convert a set of sampleIDs + unique taxonIDs into a sampleID + taxonomy file

# Usage: Rscript expand_taxonomy.R samplemap.csv taxonomy.txt expanded.txt

# samplemap.csv should contain columns named:
#	"accession" (arbitrary sample IDs), 
# 	"taxid" (arbitrary taxon IDs),
#	and optionally others that will be ignored.

# taxonomy.txt should contain exactly two tab-separated columns: 
#	arbitrary taxon ID and taxonomy string (probably semicolon-delimited, but this script doesn't care)

# expanded.txt should be the path to write the expanded taxonomy.
#	It will have two unnamed tab-separated columns: 
#		- accession ID (same accessions as samplemap.csv, but probably NOT in the same order)
#		- taxonomy (same as in taxonomy.txt).
#	Note that expanded.txt does NOT contain taxon IDs --
#	if you need them, look them up from samplemap.csv.

args = commandArgs(trailingOnly=TRUE)

acc_map = read.csv(args[1])

taxonomy = read.table(
	args[2],
	sep="\t",
	quote="", # some names have unmatched quotes, e.g. "Viola_sp._'D'Udine'"
	header=FALSE,
	col.names=c("taxid", "taxonomy"))

# One (potentially redundant) taxonomy for each accession
all_acc_taxonomy = merge(
	acc_map,
	taxonomy,
	all.x=TRUE)
write.table(
	all_acc_taxonomy[, c("accession", "taxonomy")],
	file=args[3],
	row.names=FALSE,
	col.names=FALSE,
	quote=FALSE,
	sep="\t")

