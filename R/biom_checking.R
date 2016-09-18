# Checking for effects of extraction/clustering parameters:
#	* anchor length around ITS2 (0,10,20 bases or 5.8S/26S HMM or whole amplicon)
#	* clustering threshold
#	* blast similarity cutoff
# These anlyses shouldn't be needed for routine use, but saving for posterity
# This is an edited transcript of an interactive session -- it will definitely not
# do anything useful if run as a script.

library(phyloseq)
library(tidyr)
library(dplyr)
library(ggplot2)
library(cowplot)

SEQS_FNA_LENGTH = 956812 # only constant if I don't change upstream cleanup steps!

bioms = list.files("tmp/bioms/")
b = lapply(bioms, function(x)import_biom(file.path("tmp/bioms", x)))
names(b)=sub(".biom$", "", bioms)

# Here's the list of species we *expect* to see
vouch = read.csv("rawdata/vouchers/root_voucher_fate.csv")
vouch$genus = sapply(as.character(vouch$binomial), function(x) strsplit(x, " ")[[1]][1])

# Collapse OTUs assigned to the same species/genus.
# These are slooooow, but whatever
b_spglom = lapply(b, tax_glom, "Rank8", NArm=FALSE)
b_genglom = lapply(b, tax_glom, "Rank7", NArm=FALSE)

# First run, all blast identity thresholds were the same as clustering threshold
b_sizes = (
	data.frame(
		name=bioms,
		n_clusters = sapply(b, ntaxa),
		n_rawreads_clustered = sapply(b, function(x)sum(otu_table(x))),
		n_unidentified_taxa = sapply(
			b,
			function(x)length(which(tax_table(x)[, "Rank1"] == "No blast hit"))),
		n_species = sapply(b_spglom, ntaxa),
		n_genera = sapply(b_genglom, ntaxa),
		n_unseen_sp = sapply( # species present in vouchers but not identified in unknowns
			b_spglom,
			function(x)length(setdiff(vouch$binomial, tax_table(x)[,"Rank8"]))),
		n_unexp_sp = sapply( # species "present" in unknowns but not vouchers
			b_spglom,
			function(x)length(setdiff(tax_table(x)[,"Rank8"], vouch$binomial))),
		n_unseen_gen = sapply( # genera present in vouchers but not identified in unknowns
			b_genglom,
			function(x)length(setdiff(vouch$genus, tax_table(x)[,"Rank7"]))),
		n_unexp_gen = sapply( # genera "present" in unknowns but not vouchers
			b_genglom,
			function(x)length(setdiff(tax_table(x)[,"Rank7"], vouch$genus))))
	# break filenames into anchor/similarity columns
	%>% separate(col=name, into=c("anchor", "pct_sim", "biom_file_ext"))
	%>% select(-biom_file_ext)
	%>% mutate(
		pct_rawreads_clustered = n_rawreads_clustered/SEQS_FNA_LENGTH*100,
		pct_clusters_identified = (1 - n_unidentified_taxa/n_clusters)*100,
		pct_sim = as.numeric(as.character(pct_sim)))
)

# Then I repeated the above but with BLAST percent ID fixed at 90% 
# instead of matching cluster similarity
bioms90 = list.files("tmp/bioms_id90pct")
b90 = lapply(bioms90, function(x)import_biom(file.path("tmp/bioms_id90pct", x)))
names(b90)=sub("_blast90.biom$", "", bioms90)

b90_spglom = lapply(b90, tax_glom, "Rank8", NArm=FALSE)
b90_genglom = lapply(b90, tax_glom, "Rank7", NArm=FALSE)

b90_sizes = (
	data.frame(
		name=bioms90,
		n_clusters = sapply(b90, ntaxa),
		n_rawreads_clustered = sapply(b90, function(x)sum(otu_table(x))),
		n_unidentified_taxa = sapply(
			b90,
			function(x)length(which(tax_table(x)[, "Rank1"] == "No blast hit"))),
		n_species = sapply(b90_spglom, ntaxa),
		n_genera = sapply(b90_genglom, ntaxa),
		n_unseen_sp = sapply( # species present in vouchers but not identified in unknowns
			b90_spglom,
			function(x)length(setdiff(vouch$binomial, tax_table(x)[,"Rank8"]))),
		n_unexp_sp = sapply( # species "present" in unknowns but not vouchers
			b90_spglom,
			function(x)length(setdiff(tax_table(x)[,"Rank8"], vouch$binomial))),
		n_unseen_gen = sapply( # genera present in vouchers but not identified in unknowns
			b90_genglom,
			function(x)length(setdiff(vouch$genus, tax_table(x)[,"Rank7"]))),
		n_unexp_gen = sapply( # genera "present" in unknowns but not vouchers
			b90_genglom,
			function(x)length(setdiff(tax_table(x)[,"Rank7"], vouch$genus))))
	# break filenames into anchor/similarity columns
	%>% separate(col=name, into=c("anchor", "pct_sim", "blast_sim", "biom_file_ext"))
	%>% select(-biom_file_ext)
	%>% mutate(
		pct_rawreads_clustered = n_rawreads_clustered/SEQS_FNA_LENGTH*100,
		pct_clusters_identified = (1 - n_unidentified_taxa/n_clusters)*100,
		pct_sim = as.numeric(as.character(pct_sim)))
)


# And once more with BLAST percent ID fixed at 95% 
bioms95 = list.files("tmp/bioms_id95pct")
b95 = lapply(bioms95, function(x)import_biom(file.path("tmp/bioms_id95pct", x)))
names(b95)=sub("_blast95.biom$", "", bioms95)

b95_spglom = lapply(b95, tax_glom, "Rank8", NArm=FALSE)
b95_genglom = lapply(b95, tax_glom, "Rank7", NArm=FALSE)

b95_sizes = (
	data.frame(
		name=bioms95,
		n_clusters = sapply(b95, ntaxa),
		n_rawreads_clustered = sapply(b95, function(x)sum(otu_table(x))),
		n_unidentified_taxa = sapply(
			b95,
			function(x)length(which(tax_table(x)[, "Rank1"] == "No blast hit"))),
		n_species = sapply(b95_spglom, ntaxa),
		n_genera = sapply(b95_genglom, ntaxa),
		n_unseen_sp = sapply( # species present in vouchers but not identified in unknowns
			b95_spglom,
			function(x)length(setdiff(vouch$binomial, tax_table(x)[,"Rank8"]))),
		n_unexp_sp = sapply( # species "present" in unknowns but not vouchers
			b95_spglom,
			function(x)length(setdiff(tax_table(x)[,"Rank8"], vouch$binomial))),
		n_unseen_gen = sapply( # genera present in vouchers but not identified in unknowns
			b95_genglom,
			function(x)length(setdiff(vouch$genus, tax_table(x)[,"Rank7"]))),
		n_unexp_gen = sapply( # genera "present" in unknowns but not vouchers
			b95_genglom,
			function(x)length(setdiff(tax_table(x)[,"Rank7"], vouch$genus))))
	# break filenames into anchor/similarity columns
	%>% separate(col=name, into=c("anchor", "pct_sim", "blast_sim", "biom_file_ext"))
	%>% select(-biom_file_ext)
	%>% mutate(
		pct_rawreads_clustered = n_rawreads_clustered/SEQS_FNA_LENGTH*100,
		pct_clusters_identified = (1 - n_unidentified_taxa/n_clusters)*100,
		pct_sim = as.numeric(as.character(pct_sim)))
)

b_sizes$blast_sim = "blast_equals_cluster"
b_allsizes = rbind(b_sizes, b90_sizes, b95_sizes)





# Plots of cluster number/success rate at different anchor/cluster/blast settings
plot_grid(
	ggplot(b_allsizes,
		aes(
			x=pct_sim,
			y=n_clusters,
			color=anchor))
		+geom_line()
		+geom_point()
		+theme(legend.position="none"),
	ggplot(b_allsizes,
		aes(
			x=pct_sim,
			y=pct_rawreads_clustered,
			color=anchor))
		+geom_line()
		+geom_point()
		+geom_hline(yintercept=100, lty="dashed")
		+theme(legend.position="none"),
	ggplot(b_allsizes,
		aes(
			x=pct_sim,
			y=n_unidentified_taxa,
			color=anchor,
			shape=blast_sim,
			lty=blast_sim))
		+geom_line()
		+geom_point()
		+geom_hline(yintercept=0, lty="dashed")
		+theme(
			legend.position=c(0.3, 0.7),
			legend.box.just=c(0,0)),
	ggplot(b_allsizes,
		aes(
			x=pct_sim,
			y=pct_clusters_identified,
			color=anchor,
			shape=blast_sim,
			lty=blast_sim))
		+geom_line()
		+geom_point()
		+geom_hline(yintercept=100, lty="dashed")
		+theme(legend.position="none"),
	nrow=2,
	labels="auto"
)

# How many species and genera are in the clusters we get, and how many of those are from species/genera we were/weren't expecting based on the voucher data?
plot_grid(
	ggplot(b_allsizes,
		aes(
			x=pct_sim,
			y=n_species,
			color=anchor,
			shape=blast_sim,
			lty=blast_sim))
		+geom_line()
		+geom_point()
		+geom_hline(yintercept=34, lty="dashed")
		+theme(
			legend.position=c(0.3, 0.7),
			legend.box.just=c(0,0)),
	ggplot(b_allsizes,
		aes(
			x=pct_sim,
			y=n_unseen_sp,
			color=anchor,
			shape=blast_sim,
			lty=blast_sim))
		+geom_line()
		+geom_point()
		+theme(legend.position="none"),
	ggplot(b_allsizes,
		aes(
			x=pct_sim,
			y=n_unexp_sp,
			color=anchor,
			shape=blast_sim,
			lty=blast_sim))
		+geom_line()
		+geom_point()
		+theme(legend.position="none"),
	ggplot(b_allsizes,
		aes(
			x=pct_sim,
			y=n_genera,
			color=anchor,
			shape=blast_sim,
			lty=blast_sim))
		+geom_line()
		+geom_point()
		+geom_hline(yintercept=26, lty="dashed")
		+theme(legend.position="none"),
	ggplot(b_allsizes,
		aes(
			x=pct_sim,
			y=n_unseen_gen,
			color=anchor,
			shape=blast_sim,
			lty=blast_sim))
		+geom_line()
		+geom_point()
		+theme(legend.position="none"),
	ggplot(b_allsizes,
		aes(
			x=pct_sim,
			y=n_unexp_gen,
			color=anchor,
			shape=blast_sim,
			lty=blast_sim))
		+geom_line()
		+geom_point()
		+theme(legend.position="none"),
	ncol=3,
	labels="auto"
)


## Did the mock communities contain the species we expected to see?
# This is unfinished -- I'm not convinced multiple bar plots is the best way to present this.

# find species that we included in our "voucher mix" mock communities
vouch_mix = vouch[grepl("^y", vouch$Include.in.voucher.mix.),]
vm_species = unique(vouch_mix$binomial)
vm_genera = unique(vouch_mix$genus)

# Did not save these plots -- here's a sample of the approach I was taking, but you'll probably need to edit these to get anything useful out of them.
plot_vouchers = function(physeq){
	va = prune_samples(sample_names(physeq)=="Voucher.mix.A", physeq)
	vb = prune_samples(sample_names(physeq)=="Voucher.mix.B", physeq)
	vc = prune_samples(sample_names(physeq)=="Voucher.mix.C", physeq)
	plot_grid(
		plot_bar(prune_taxa(taxa_sums(va) > 0, va), x="Rank7", fill="Rank8"),
		plot_bar(prune_taxa(taxa_sums(vb) > 0, vb), x="Rank7", fill="Rank8"),
		plot_bar(prune_taxa(taxa_sums(vc) > 0, vc), x="Rank7", fill="Rank8"),
		ncol=1)
}
plot_vouchers_spnoleg = function(physeq){
	va = prune_samples(sample_names(physeq)=="Voucher.mix.A", physeq)
	vb = prune_samples(sample_names(physeq)=="Voucher.mix.B", physeq)
	vc = prune_samples(sample_names(physeq)=="Voucher.mix.C", physeq)
	plot_grid(
		plot_bar(prune_taxa(taxa_sums(va) > 0, va), x="Rank8")+theme(axis.text.x=element_text(angle=45, hjust=1)),
		plot_bar(prune_taxa(taxa_sums(vb) > 0, vb), x="Rank8")+theme(axis.text.x=element_text(angle=45, hjust=1)),
		plot_bar(prune_taxa(taxa_sums(vc) > 0, vc), x="Rank8")+theme(axis.text.x=element_text(angle=45, hjust=1)),
		ncol=1)
}



n_known = function(physeq){
	ntaxa(prune_taxa(tax_table(physeq)[,"Rank8"] %in% vouch$Binomial, physeq))
}
find_vouchers = function(physeq){
	subset_samples(physeq, grepl("Voucher", sample_names(physeq)))
}
plot(b_sizes$pct_sim, sapply(b_spglom, function(x)n_known(find_vouchers(x))))




## Heatmaps of OTU vs sample. 
# The intuition here: both axes are sorted by NMDS similarity,
# so vertical streaks = OTUs that tend to be found in the same samples 
# = if they also look taxonomically related, these may be candidates for 
# merging into the same OTU.
# This didn't work all that well -- I realized I was basically trying to back 
# my way into a neighbor-joining tree.
heatmap_topk = function(physeq, k, ...){
	# plot a heatmap on the k most common taxa in physeq.
	# all ... are passed to plot_heatmap.
	plot_heatmap(
		prune_taxa(
			names(sort(taxa_sums(physeq), decreasing=TRUE)[1:k]), 
			physeq), 
		...)
}
heatmap_blasts = function(name, k, ...){
	plot_grid(
		heatmap_topk(b[[name]], k, ...)+theme(legend.position="none"),
		heatmap_topk(b90[[name]], k, ...)+theme(legend.position="none"),
		heatmap_topk(b95[[name]], k, ...)+theme(legend.position="none"),
		nrow=3)
}
heatmap_blasts(name="ahmm_95", k=100, taxa.label="Rank8", method="NMDS", distance="jaccard", binary=TRUE)

