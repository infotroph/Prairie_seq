
# Done in shell, outside R

# Shorten FASTA headers to just accession-version ID
# sed -E 's/gi\|.*\|.*\|(.*)\|.*/\1/' ncbi_all_plant_its2_longid.fasta > ncbi_all_plant_its2.fasta
# sed -E 's/gi\|.*\|.*\|(.*)\|.*/\1/' present_genera_its2_longid.fasta > present_genera_its2.fasta

# now actually in R
# All paths are relative to ~/UI/prairie_seq/rawdata/ncbi_its2/

library("taxize")

make_phylo = function(x){
	x = x[x$rank != "no rank",] 
	x$name = gsub(" ", "_", x$name)
	
	paste(x$name, collapse=";")
}

present_accessions = system(
	"sed -E -n 's/>(.*)$/\\1/p' present_genera_its2.fasta", 
	intern=TRUE)

system.time({present_uids = genbank2uid(present_accessions, batch_size=250)})

present_acc_taxid = data.frame(
	accession=present_accessions,
	taxid=c(present_uids)) # c to strip attributes
write.table(
	present_acc_taxid,
	file="present_genera_its2_accessions_taxids.csv",
	sep=",",
	quote=FALSE,
	row.names=FALSE)

present_uids_uniq = unique(present_uids)
system.time({present_uniq_classification = classification(present_uids_uniq, db="ncbi")})

present_uniq_collapsed = sapply(present_uniq_classification, make_phylo)

# One taxonomy per unique taxon
present_uniq_taxonomy = data.frame(
	taxid = names(present_uniq_collapsed),
	phylogeny = present_uniq_collapsed)
write.table(
	present_uniq_taxonomy,
	file="present_genera_its2_unique_taxonomy.txt",
	row.names=FALSE,
	col.names=FALSE,
	quote=FALSE,
	sep="\t")

# One (potentially redundant) taxonomy for each accession
present_acc_taxonomy = merge(
	present_acc_taxid,
	present_uniq_taxonomy,
	all=TRUE)
write.table(
	present_acc_taxonomy[, c("accession", "phylogeny")],
	file="present_genera_its2_accession_taxonomy.txt",
	row.names=FALSE,
	col.names=FALSE,
	quote=FALSE,
	sep="\t")



cat("\nDone with the known genera, now let's try it with all taxa!\n")

all_accessions = system(
	"sed -E -n 's/>(.*)$/\\1/p' ncbi_all_plant_its2.fasta", 
	intern=TRUE)

# This will take a while -- took 20 minutes to run 6508 accessions for present_uids!
# If it scales linearly, allow ~12 hours for all 245k accessions of ncbi_all_plant_its2
# Let's break it into chunks of 1000 and save as we go.
# If it errors out, comment out the cat(...) line below, edit chunk_borders to start from [last successful row + 1], restart script.

# batch_size is number of acessions queried in one request. 
# Can sometimes get away with larger batches up to 250-ish,
# but get occasional "request URI too long" or curl errors while trying to download response.

cat(
	"rownum,accession,taxid\n",
	file="ncbi_all_plant_its2_accessions_taxids.csv")

chunk_borders = c(
	seq(from=1, to=length(all_accessions), by=1000),
	length(all_accessions))

i = chunk_borders[1]
for(j in chunk_borders[-1]){
	cat("\nRows ", i, " to ", j, "\n")
	print(system.time({chunk_uids = genbank2uid(all_accessions[i:j], batch_size=100)}))
	write.table(
		data.frame(row=i:j, accession=all_accessions[i:j], taxid=c(chunk_uids)),
		file="ncbi_all_plant_its2_accessions_taxids.csv",
		sep=",",
		quote=FALSE,
		row.names=FALSE,
		col.names=FALSE,
		append=TRUE)	
	i = j+1
}

all_acc_taxids = read.csv("ncbi_all_plant_its2_accessions_taxids.csv")
all_taxids_uniq = unique(all_acc_taxids$taxid)


# One taxonomy per unique taxon
# This took even longer than get_uids! 
# Errors on ~any transient connection problems
chunk_borders = c(
	seq(from=1, to=length(all_taxids_uniq), by=100),
	length(all_taxids_uniq))
i = chunk_borders[1]
for(j in chunk_borders[-1]){	
	cat("\nRows ", i, " to ", j, "\n")
	print(system.time({chunk_uniq_classification = classification(all_taxids_uniq[i:j], db="ncbi")}))
	chunk_uniq_collapsed = sapply(chunk_uniq_classification, make_phylo)
	write.table(
		data.frame(
			taxid = names(chunk_uniq_collapsed),
			phylogeny = chunk_uniq_collapsed),
		file="ncbi_all_plant_its2_unique_taxonomy.txt",
		row.names=FALSE,
		col.names=FALSE,
		quote=FALSE,
		sep="\t",
		append=TRUE)
	i = j+1
}

all_uniq_taxonomy = read.table(
	"ncbi_all_plant_its2_unique_taxonomy.txt",
	sep="\t",
	quote="", # some names have unmatched quotes, e.g. "Viola_sp._'D'Udine'"
	header=FALSE,
	col.names=c("taxid", "phylogeny"))

# One (potentially redundant) taxonomy for each accession
all_acc_taxonomy = merge(
	all_acc_taxids,
	all_uniq_taxonomy,
	all=TRUE)
write.table(
	all_acc_taxonomy[, c("accession", "phylogeny")],
	file="ncbi_all_plant_its2_accession_taxonomy.txt",
	row.names=FALSE,
	col.names=FALSE,
	quote=FALSE,
	sep="\t")

# Noticed afterward that this script produces FASTA files with 
# multiple lines per sequences and empty lines between entries. 
# Fixed in shell: 
# for f in *fasta; do
# 	mv "$f" "$f"_0
# 	awk '/^>/ {print "\n"$0; next} {printf("%s", $0)}' "$f"_0 > "$f"
# 	rm "$f"_0
# done
