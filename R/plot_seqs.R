library("phyloseq")
library("dplyr")
library("tidyr")
library("tibble")
library("ggplot2")
library("vegan")
library("cooccur")
library("viridis")
library("DeLuciatoR")
plot_grid=cowplot::plot_grid
se=plotrix::std.error
kable=knitr::kable

set.seed(123546876)

## soil C and N concentration
cn = read.csv("rawdata/bulk_CN.csv")
# Remove empty capsules (they were a zero check for the analyzer), 
# drop run QC columns, take mean of duplicates.
# N=119 -- sample 2P2 75-100 was lost before analysis
cn_clean = (cn
	%>% filter(Block != "Empty Capsule")
	%>% select(Block, Sample, Upper, Lower, PctC, PctN)
	%>% rename(Location=Sample)
	%>% group_by(Block, Location, Upper, Lower)
	%>% summarize_all(funs(mean))
)

## Sequence data
reads = import_biom("data/plant_its2_otu/plant_its2_99.biom")

# Reconfigure sequence sample_data table, add CN data.
rsd = sample_data(reads)
rsd$SampleID = rownames(rsd)
midpoints = c("0"=5, "10"=20, "30"=40, "50"=62.5, "75"=87.5, "NA"=NA)
rsd$Depth = midpoints[rsd$Depth1]
rsd$BlockLoc = paste0(rsd$Block, "_", rsd$Location)
rsd = merge(
	x=rsd,
	y=cn_clean,
	by.x=c("Block", "Location", "Depth1", "Depth2"),
	by.y=c("Block", "Location", "Upper", "Lower"),
	all.x=TRUE)
rsd$CN = rsd$PctC/rsd$PctN
rownames(rsd) = rsd$SampleID
sample_data(reads) = sample_data(rsd)

# Consolidate OTUs that mapped to same species
# (1347 OTU before, 158 species after)
r_sp = tax_glom(reads, "Rank8", NArm=FALSE)

# Subset to just roots, no rhizosphere or control samples
r_root = subset_samples(r_sp, SampleType=="root")
# Remove samples with only a few reads (<1000).
# Samples not sequenced:
#	0p7 10-30 (pipetting error, contam. with 0p8 30-50)
#	0p2 30-50 (pipetting error, contam. with 1p2 50-75)
#	3p3 50-75 (very little tissue then loading error, contam. with 0p6 0-10)
#	3p3 30-50 (not enough tissue to extract)
#	3p3 75-100 (not enough tissue to extract)
#	3p4 75-100 (not enough tissue to extract)
# Sample 1p4 30-50 was sequenced, but gave 1 raw and 0 clean reads.
# ==> N=113 before pruning. 
# Samples removed for low read counts and how many reads they had:
# 	4p2 30-50 729 
# 	0p3 30-50 575 
# 	3p3 0-10 9 
# ==> N=110 after pruning. 
r_root = prune_samples(sample_sums(r_root) > 1000, r_root)
r_root = prune_taxa(taxa_sums(r_root) > 0, r_root)

# Normalize to proportions within samples
r_root_prop = transform_sample_counts(r_root, function(x)x/sum(x))

# print(r_root_prop)







# glimpse(cn_clean)

## Voucher identities
vouch = read.csv("rawdata/vouchers/root_voucher_fate.csv")
vouch$binomial = sub("Aster hirta spp.", "Aster hirta", vouch$binomial)
accepted_names = read.csv("rawdata/vouchers/accepted_names.csv")
vouch = merge(
	x=vouch,
	y=accepted_names,
	by.x="binomial",
	by.y="Feng_binomial",
	all=TRUE)

# glimpse(vouch)


## Aboveground species data
# Currently using 2012 data, will replace with 2013 when available
abvabund = (
	read.csv("private/Xiaohui_species_comp/surveys_clean.csv")
	%>% replace_na(replace=list(
		abundance=0,
		pct_cover=0
		# NAs in height are still NAs, though.
		))
	%>% mutate(
		species = replace(
			x=as.character(species),
			list=species=="Weed 1",
			values="Taraxacum officinale"))
	%>% subset(!(species %in% c(
		"Aster pilosus", # Ignoring because only 1 plant in 1 quadrat on 1 day
		"weed", # Ignoring because not clear if these are one species or several
		"Weed 2",
		"Weed 3",
		"add new spp", # Ignoring because these are not species
		"Bare ground",
		"Total"
		)))
)
# Normalize species names in aboveground dataset to accepted form
abvabund= merge(
	abvabund,
	accepted_names,
	by.x="species",
	by.y="Feng_binomial",
	all.x=TRUE)


# glimpse(abvabund)

print("files read ✓")



## Looking at mock community controls
r_mock = subset_samples(r_sp, SampleType=="mock")
r_mock = prune_taxa(taxa_sums(r_mock)>0, r_mock)
r_mock_prop = transform_sample_counts(r_mock, function(x)x/sum(x))

# Comparing composition between the 3 PCR/sequencing replicates,
# adding points showing "expected" abundance
# Key concept for "expected": if 31 species went into the mix and 4 were silphiums, expect 4/31 of reads to come from Silphium
# ...assuming we did in fact add equimolar DNA from each species
# ...and assuming that equimolar DNA does mean equimolar ITS2
# ...etc...
#
# Let's plot once by species, once by genus.
# Green dot: proportion of template DNA expected to be from this taxon
# Black bar: Proportion of reads mapped to this taxon
# Facets: three PCR/sequencing replicates of the same template mixture
# ==> dot in column with no bar = taxon we expected but don't see;
# ==> bar in column with no dot = taxon not expected but indicated by barcode
mock_exp_sp = (vouch
	%>% filter(grepl("^y", Include.in.voucher.mix.))
	%>% rename(species=accepted_name)
	%>% group_by(species)
	%>% summarize(Abundance=n()/nrow(.)))
mock_exp_gen = (
	vouch 
	%>% filter(grepl("^y", Include.in.voucher.mix.))
	%>% mutate(genus=accepted_genus) # N.B. this overwrites previous genus column
	%>% group_by(genus)
	%>% summarize(Abundance=n()/nrow(.)))

mock_sp_plot = (ggplot(
	psmelt(r_mock_prop),
	aes(x=Rank8, weight=Abundance))
+ geom_bar(aes(fill="observed"), position="stack")
+ facet_grid(Sample~.)
+ geom_point(
	data=mock_exp_sp,
	mapping=aes(
		x=species,
		y=Abundance,
		color="expected"))
+ scale_color_manual(
	name=NULL,
	values=c("observed"="black", "expected"="green"),
	guide=guide_legend(order=1))
+ scale_fill_manual(
	name=NULL,
	values=c("observed"="black", "expected"="green"),
	guide=guide_legend(order=2))
+ xlab("Species")
+ ylab("Proportion of sample")
+ theme_ggEHD(10)
+ theme(
	aspect.ratio=0.33,
	legend.position=c(0.15, 0.92),
	legend.margin=margin(0,0,0,0,"cm"),
	legend.spacing=unit(0, "cm"),
	axis.text.x=element_text(angle=270, hjust=0, margin=margin(t=1, unit="lines")),
	axis.ticks.x=element_blank()))


mock_gen_plot = (ggplot(
	psmelt(r_mock_prop),
	aes(x=Rank7, weight=Abundance))
+ geom_bar(aes(fill="observed"), position="stack")
+ facet_grid(Sample~.)
+ geom_point(
	data=mock_exp_gen,
	mapping=aes(
		x=genus,
		y=Abundance,
		color="expected"))
+ scale_color_manual(
	name=NULL,
	values=c("observed"="black", "expected"="green"),
	guide=guide_legend(order=1))
+ scale_fill_manual(
	name=NULL,
	values=c("observed"="black", "expected"="green"),
	guide=guide_legend(order=2))
+ xlab("Genus")
+ ylab("Proportion of sample")
+ theme_ggEHD(14)
+ theme(
	aspect.ratio=0.33,
	legend.position=c(0.15, 0.92),
	legend.margin=margin(0,0,0,0,"cm"),
	legend.spacing=unit(0, "cm"),
	axis.text.x=element_text(angle=270, hjust=0, margin=margin(t=1, unit="lines")),
	axis.ticks.x=element_blank()))

ggsave_fitmax("figs/mock_sp.pdf", mock_sp_plot, maxwidth=6.5, maxheight=9)
embedFonts("figs/mock_sp.pdf")
ggsave_fitmax("figs/mock_gen.pdf", mock_gen_plot, maxwidth=6.5, maxheight=9)
embedFonts("figs/mock_gen.pdf")

print("mock communities ✓")










## Draft species-by-depth heatmap. Needs lots of work.
rr_heat = tax_glom(merge_samples(r_root, "Depth1"), "Rank7")
	# Warns about NAs introduced by coercion -- need to consider how to treat unresolved taxa
rr_heatpct = transform_sample_counts(rr_heat, function(x)100*x/sum(x))
rr_heatpct_1 = filter_taxa(
	rr_heatpct,
	function(x)max(x)>1, 
	TRUE)

# samples descending by depth, taxa descending by abundance
rrhdepth = (
	sample_data(rr_heatpct_1)[,"Depth1"] 
	%>% data.frame
	%>% rownames_to_column
	%>% arrange(desc(Depth1))
	%>% .$rowname)
rrhtax=names(sort(taxa_sums(rr_heatpct_1), decreasing=TRUE))

heatmap_draft1 = (
	plot_heatmap(
		rr_heatpct_1,
		taxa.label="Rank7",
		sample.order=rrhdepth,
		taxa.order=rrhtax,
		na.value="darkgrey", low="brown", high="yellow")
	+ xlab("Depth (cm)")
	+ coord_flip())
heatmap_abvdraft = (
	ggplot(
		data=(abvabund 
			%>% group_by(accepted_name) 
			%>% summarize(pct_cover_mean=mean(pct_cover))),
		aes(
			x=1, 
			reorder(accepted_name, desc(pct_cover_mean)),
			fill=sqrt(pct_cover_mean)))
	+ geom_tile()
	+ coord_flip()
	+ theme(axis.text.x=element_text(angle=270)))

ggsave("figs/heatmap_bgdraft.png", heatmap_draft1, width=12, height=8)
	# For reasons unclear to me, saving this heatmap as PDF produces
	# unregognizeably fuzzy tiles, but all other elements crisp.
	# Fix eventually, use PNG until then.
ggsave("figs/heatmap_abvdraft.pdf", heatmap_abvdraft)
embedFonts("figs/heatmap_abvdraft.pdf")

print("drafts of heatmaps ✓")







## Aboveground/belowground comparison

abvabund_spmean = (
	abvabund
	%>% group_by(functional_type, accepted_family, accepted_genus, accepted_name, planted) #for whole-season avg. TODO: try adding date, block with 2013 data
	%>% summarize_each(funs(mean, sd, se), abundance, pct_cover)
)

abvabund_table=(
	abvabund_spmean
	%>% ungroup()
	%>% select(
		Species=accepted_name,
		Family=accepted_family,
		`Functional type`=functional_type,
		`Planted?`=planted,
		`% cover`=pct_cover_mean,
		`sd`=pct_cover_sd)
	%>% mutate(
		Species = paste0("*", Species, "*"),
		Species=sub(
			"^\\*Baptisia\\*$",
			"unidentified *Baptisia* sp.",
			Species))
	%>% kable(digits=1)
	%>% write("data/aboveground_abundance.txt"))


abvabund_spblockmean = (
	abvabund
	%>% group_by(accepted_family, accepted_genus, accepted_name, block)
	%>% summarize_each(funs(mean, sd, se), abundance, pct_cover)
)
abvabund_genmean = (
	abvabund
	%>% group_by(accepted_family, accepted_genus)
	%>% summarize_each(funs(mean, sd, se), abundance, pct_cover)
)
abvabund_genblockmean = (
	abvabund
	%>% group_by(accepted_family, accepted_genus, block)
	%>% summarize_each(funs(mean, sd, se), abundance, pct_cover)
)

# get mean belowground abundance (averaging all depths)
r_root_prop_df = psmelt(r_root_prop)
bgabund_genblockmean = (
	r_root_prop_df
	%>% group_by(Rank6, Rank7, Block)
	%>% rename(family=Rank6, genus=Rank7)
	%>% mutate(pct_abund=Abundance*100)
	%>% summarize_each(funs(pct_reads_mean=mean, pct_reads_sd=sd, pct_reads_se=se), pct_abund))

rootshoot_abund_genblock = (
	merge(
		x=abvabund_genblockmean,
		y=bgabund_genblockmean,
		by.x=c("accepted_genus", "block"),
		by.y=c("genus", "Block"),
		all=TRUE)
	%>% mutate(
		is_poa = if_else(family=="Poaceae", "monocots", "dicots"))
	%>% filter(!is.na(is_poa)))
rootshoot_abund_genblock_lms = (
	rootshoot_abund_genblock
	%>% group_by(is_poa)
	%>% do(lmfit = lm(pct_reads_mean ~ pct_cover_mean, data=.))
	%>% summarize(
		is_poa=is_poa,
		label = paste0(
			is_poa,
			"~y*'='*",
			signif(coef(lmfit)["(Intercept)"], 2),
			"*'+'*",
			signif(coef(lmfit)["pct_cover_mean"], 2),
			"*x*','~R^2*'='*",
			signif(summary(lmfit)$r.squared, 2))))

# one point per genus *from each block*
agbg_genblock_plot = (ggplot(
	rootshoot_abund_genblock,
	aes(
		x=pct_cover_mean,
		xmin=pct_cover_mean-pct_cover_se,
		xmax=pct_cover_mean+pct_cover_se,
		y=pct_reads_mean,
		ymin=pct_reads_mean-pct_reads_se,
		ymax=pct_reads_mean+pct_reads_se,
		color=is_poa))
	+ geom_point()
	+ geom_errorbar()
	+ geom_errorbarh()
	+ geom_smooth(method="lm")
	+ xlab("Aboveground dominance (percent cover)")
	+ ylab("Belowground dominance (percent reads)")
	+ scale_color_discrete(
		breaks=rootshoot_abund_genblock_lms$is_poa,
		labels=parse(text=rootshoot_abund_genblock_lms$label))
	+ theme_ggEHD(14)
	+ theme(
		legend.title=element_blank(),
		legend.position=c(0.6, 0.9),
		legend.text.align=0) # 0=left-aligned
)

ggsave_fitmax("figs/agbg_genblock.pdf", agbg_genblock_plot, maxwidth=6, maxheight=9)
embedFonts("figs/agbg_genblock.pdf")

print("aboveground-belowground correlation ✓")










## H20 controls
# Not sure what to make of the high read counts from H2O.B.
# No obvious evidence of pipetting or labeling error,
# but may be worth looking harder.
r_h2o = subset_samples(r_sp, SampleType=="nodna")
r_h2o = prune_taxa(taxa_sums(r_h2o)>0, r_h2o)
water_bar_plot = (
	plot_bar(r_h2o, x="Rank8")
		+ facet_grid(Sample~., scale="free_y")
		+ ylab("Read count")
		+ xlab(NULL)
		+ theme_ggEHD(14)
		+ theme(
			axis.ticks.x=element_blank(),
			axis.text.x=element_text(angle=270, hjust=0),
			aspect.ratio=0.33))
ggsave_fitmax("figs/h2o.pdf", water_bar_plot, maxwidth=6.5, maxheight=9)
embedFonts("figs/h2o.pdf")
print("Water controls ✓")


## One-species and two-species controls
r_indiv = subset_samples(r_sp, SampleType %in% c("onespecies", "twospecies"))
# TODO: Couldn't I just normalize once and take all SampleType subsets from that?
r_indiv_prop = transform_sample_counts(r_indiv, function(x)x/sum(x))
r_indiv_prop_1pct = filter_taxa(r_indiv_prop, function(x)max(x)>0.01, prune=TRUE)

# Assign clearer display names.
# BUGBUG: To sort facets so one-species and two-species samples go in different rows, 
# I'm relying on manual factor ordering (same order as the rows in `spikenames`, NOT alphabetical),
# plus ggplot facet ordering (when as.table=TRUE: top->bottom, panels L->R in each row),
# plus a manually set 2-column layout.
# This is probably a bad idea and may break if ggplot facet sorting changes.
spikedat = psmelt(r_indiv_prop_1pct)
spikenames = read.csv(
	text='
		Sample, Sample_label
		Andropogon.gerardii, italic(Andropogon~gerardii)~(Ange)
		Silphium.perfoliatum, italic(Silphium~perfoliatum)~(Sipu)
		Elymus.canadensis, italic(Elymus~canadensis)~(Elca)
		Sorghastrum.nutans, italic(Sorghastrum~nutans)~(Sonu)
		Spike.Elymus.1, Ange + """1%"""~Elca
		Spike.Sorghastrum.1, Ange + """1%"""~Sonu
		Spike.Elymus.5, Ange + """5%"""~Elca
		Spike.Sorghastrum.5, Ange + """5%"""~Sonu
		Spike.Elymus.10, Ange + """10%"""~Elca
		Spike.Sorghastrum.10, Ange + """10%"""~Sonu		
	',
	stringsAsFactors=FALSE,
	strip.white=TRUE)
spikenames$Sample_label=factor(spikenames$Sample_label, levels=spikenames$Sample_label)
spikedat = merge(spikedat, spikenames)

indiv_spike_plot = (
	ggplot(spikedat, aes(x=Rank8, weight=Abundance))
	+ geom_bar(position="stack")
	+ facet_wrap(
		~Sample_label,
		ncol=2,
		labeller=label_parsed) 
	+ ylab("Read proportion")
	+ xlab(NULL)
	+ theme_ggEHD(10)
	+ theme( # "theme_squeeze_too_many_x_entries()"
		aspect.ratio=0.33,
		panel.spacing=unit(0.1, "lines"),
		axis.title.y=element_text(margin=margin(l=0,r=0.1, unit="lines")),
		axis.text.y=element_text(margin=margin(r=1, unit="lines")),
		axis.text.x=element_text(
			angle=270,
			hjust=0,
			size=8, # >:(
			margin=margin(t=1, unit="lines")),
		axis.ticks.x=element_blank()))
ggsave_fitmax("figs/spikes.pdf", indiv_spike_plot, maxwidth=6.5, maxheight=9)
embedFonts("figs/spikes.pdf")
print("Spike-ins ✓")
	


# Genus/family by depth violin plots
r_root_genprop = tax_glom(r_root_prop, "Rank7")
rr_genprop_1pct = filter_taxa(r_root_genprop, function(x)mean(x)>0.01, prune=TRUE)
r_root_famprop = tax_glom(r_root_prop, "Rank6")
rr_famprop_1pct = filter_taxa(r_root_famprop, function(x)mean(x)>0.01, prune=TRUE)

gendepth_plot = (ggplot(
	data=(psmelt(rr_genprop_1pct) 
		%>% mutate(famgen = paste0(Rank6, ":", Rank7))),
	aes(Depth, Abundance))
	+ geom_violin(aes(group=Depth))
	+ geom_point()
	+ geom_smooth(method="loess")
	+ facet_wrap(~famgen, ncol=5)
	+ xlab("Depth (cm)")
	+ ylab("Sample proportion")
	+ scale_x_reverse()
	+ coord_flip()
	+ theme_ggEHD(16)
	+ theme(aspect.ratio=1)
)

famdepth_plot = (ggplot(
	data=psmelt(rr_famprop_1pct),
	aes(Depth, Abundance))
	+ geom_violin(aes(group=Depth))
	+ geom_point()
	+ geom_smooth(method="loess")
	+ facet_wrap(~Rank6)
	+ xlab("Depth (cm)")
	+ ylab("Sample proportion")
	+ scale_x_reverse()
	+ coord_flip()
	+ theme_ggEHD()
	+ theme(aspect.ratio=2)
)

ggsave_fitmax("figs/genus_depth.pdf", gendepth_plot, maxwidth=12, maxheight=9)
embedFonts("figs/genus_depth.pdf")
ggsave_fitmax("figs/family_depth.pdf", famdepth_plot, maxwidth=12, maxheight=9)
embedFonts("figs/family_depth.pdf")
print("taxon by depth ✓")






## A quick look at rhizosphere samples. Only a few sequenced and few sequences obtained from the ones we ran, so just using raw counts.
r_rhizo = subset_samples(r_sp, SampleType=="rhizosphere")
r_rhizo = filter_taxa(r_rhizo, function(x)max(x)>0, prune=TRUE)
r_rhizo_prop = transform_sample_counts(r_rhizo, function(x)x/sum(x))
r_rhizo_prop_1pct = filter_taxa(r_rhizo_prop, function(x)max(x)>0.01, prune=TRUE)
rhizo_plot = (
	plot_bar(r_rhizo, x="Rank8", facet_grid=BlockLoc~Depth1)
)
rhizo_prop_plot = (
	plot_bar(r_rhizo_prop_1pct, x="Rank8", facet_grid=BlockLoc~Depth1)
)


ggsave("figs/rhizo_sp.pdf", rhizo_plot, width=12, height=9)
embedFonts("figs/rhizo_sp.pdf")
ggsave("figs/rhizo_sp_prop.pdf", rhizo_prop_plot, width=12, height=9)
embedFonts("figs/rhizo_sp_prop.pdf")
print("Rhizospheres ✓")



## Ordination plot + PERMANOVA stats

# drop observations without usable C/N values
# (only one 75-100 sample has C:N > 30;
# This very likely means it contains inorganic C).
rrp = subset_samples(r_root_prop, !is.na(CN) & CN < 30)
rrp = prune_taxa(taxa_sums(rrp)>0, rrp)

rrp_otu = t(matrix(otu_table(rrp), nrow=nrow(otu_table(rrp))))
colnames(rrp_otu) = c(tax_table(rrp)[,"Rank8"])
rrp_metamds = metaMDS(rrp_otu, distance="jaccard", binary=TRUE)

rrp_points = data.frame(
	scores(rrp_metamds, display="species"),
	species=colnames(rrp_otu),
	shortname=make.cepnames(colnames(rrp_otu)),
	abundance=colSums(rrp_otu),
	family=c(tax_table(rrp)[,"Rank6"]),
	row.names=NULL,
	stringsAsFactors=FALSE)
# Assign colors by a method deep in the uncanny valley between manual and automated:
# I'm only assigning colors to 3 of the 15 families present -- rest get lumped together.
# Also I want to use the Viridis palette, but am most interested in contrasting grass vs aster,
# so I'm hand-assigning the colors in an order that gives these the greatest perceptual difference.
fam_ord_colors = viridis(4)[c(4,1,3,2)]
names(fam_ord_colors) = c("Poaceae", "Asteraceae", "Fabaceae", "Other")
rrp_points$famcolors = fam_ord_colors[rrp_points$family]
rrp_points$famcolors[is.na(rrp_points$famcolors)] = fam_ord_colors["Other"]

# Plot, one layer at a time.
pdf(
	file="figs/ordination.pdf",
	width=9,
	height=9)
# Set up a blank frame
plot(rrp_metamds, display="species", type="n")
# Add species centroids, labeling in descending order of abundance until space is filled.
# Species given no label (=lower abund than others nearby in ordination space) are plotted as "+".
# want to color labels and points by family, but colors are applied AFTER dropping unlabeled points!
# I don't know how to calculate this without plotting,
# so instead plot all in white, save the returned vector of which points get labels,
# add colors by hand by overplotting.
torp_labeled = orditorp(
	x=rrp_metamds,
	display="species",
	labels=rrp_points$shortname,
	priority=rrp_points$abundance,
	pcol="white",
	pch="+",
	col="white",
	cex=0.8)
with(rrp_points[torp_labeled,],
	text(
		x=NMDS1,
		y=NMDS2,
		labels=shortname,
		col=famcolors,
		cex=0.8))
with(rrp_points[setdiff(seq_len(nrow(rrp_points)), torp_labeled),],
	points(
		x=NMDS1,
		y=NMDS2,
		col=famcolors,
		pch="+",
		cex=0.8))


# Stratify permutation analyses within soil profiles
ord_perm = how(
	nperm=999,
	blocks=sample_data(rrp)$BlockLoc)

ord_env = envfit(
	rrp_metamds ~ Depth * PctC * PctN * CN,
	data=data.frame(sample_data(rrp)),
	permutations=ord_perm)

plot(ord_env, col="black")
legend(
	x="topleft",
	legend=names(fam_ord_colors),
	text.col=fam_ord_colors)

ord_adon = adonis(
	rrp_otu ~ Depth * PctC * PctN * CN,
	data=data.frame(sample_data(rrp)),
	permutations=ord_perm,
	method="jaccard",
	binary=TRUE)
ord_adon_freeperm = adonis(
	rrp_otu ~ Depth * PctC * PctN * CN,
	data=data.frame(sample_data(rrp)),
	permutations=999,
	method="jaccard",
	binary=TRUE)
ord_adon_nocn = adonis(
	rrp_otu ~ Depth,
	data=data.frame(sample_data(rrp)),
	permutations=ord_perm,
	method="jaccard",
	binary=TRUE)
ord_adon_nodepth = adonis(
	rrp_otu ~ PctC * PctN * CN,
	data=data.frame(sample_data(rrp)),
	permutations=ord_perm,
	method="jaccard",
	binary=TRUE)
dev.off()
embedFonts("figs/ordination.pdf")

sink("data/adonis_out.txt")
print(ord_adon)
print(ord_adon_freeperm)
print(ord_adon_nocn)
print(ord_adon_nodepth)
sink()

print("Ordinations ✓")




## visualizing co-occurance patterns between pairs of species
# First some helper functions
physeq_to_otumat = function(physeq, rank){
	matrix(
		otu_table(physeq),
		nrow=ntaxa(physeq),
		dimnames=list(
			c(tax_table(physeq)[,rank]),
			sample_names(physeq)))
}
binarize = function(physeq, cutoff){
	transform_sample_counts(physeq, function(x)ifelse(x/sum(x) >= cutoff, 1, 0))
}
# Let's curry these... default to name by species and filter at 1%:
phy_spotu = function(physeq, rank="Rank8", cutoff=0.01){
	physeq_to_otumat(binarize(physeq, cutoff), rank)
}

rrall = phy_spotu(r_root)
rrtop = phy_spotu(subset_samples(r_root, Depth1 < 30))
rrmid = phy_spotu(subset_samples(r_root, Depth1 >=30 & Depth1 < 50))
rrdeep = phy_spotu(subset_samples(r_root, Depth1 >= 50))

# plotting chokes on full species names, haven't checked why
# Wild guess: have 4 NA => all named as string "NA", doesn't like duplicate names
rownames(rrdeep) = vegan::make.cepnames(rownames(rrdeep)) 
rownames(rrmid) = vegan::make.cepnames(rownames(rrmid))
rownames(rrtop) = vegan::make.cepnames(rownames(rrtop))
rownames(rrall) = vegan::make.cepnames(rownames(rrall))

rr_tax = data.frame(tax_table(r_root)) %>% mutate(sppname=vegan::make.cepnames(Rank8))

# Observed co-occurrence vs null model.
# points near 1:1 line = pairs of species found together about as often
# as expected if they are randomly distributed and independent of each other.
# Points far above (below) line: Pairs of species found together much more (less)
# than expected if random.
# "true_rand_classifier" sets color-coding of "random" vs not,
# otherwise defaults to p < 0.1.
obs_exp_plot = plot_grid(
	(obs.v.exp(cooccur(rrtop, spp_names=T, true_rand_classifier=0.05))
		+ ggtitle("0-30 cm")
		+ theme_ggEHD()
		+ theme(legend.position=c(0.2,0.8))),
	(obs.v.exp(cooccur(rrdeep, spp_names=T, true_rand_classifier=0.05))
		+ ggtitle("30-50 cm")
		+ theme_ggEHD()
		+ theme(legend.position="none")),
	(obs.v.exp(cooccur(rrdeep, spp_names=T, true_rand_classifier=0.05))
		+ ggtitle("50-100 cm")
		+ theme_ggEHD()
		+ theme(legend.position="none")),
	(obs.v.exp(cooccur(rrall, spp_names=T, true_rand_classifier=0.05))
		+ ggtitle("All depths")
		+ theme_ggEHD()
		+ theme(legend.position="none")),
	nrow=2,
	labels="auto")

ggsave_fitmax("figs/cooccur_obs_exp.pdf", obs_exp_plot, maxwidth=12, maxheight=9)
embedFonts("figs/cooccur_obs_exp.pdf")

# Standardized effect sizes, separated by family:
# Each point is a pairs of species; y-axis is family of sp1, panel label is family of sp2.
# Points with large effect are species pairs that co-occur at rates
# much different from random expectation;
# More often found together if effect is positive, less often if neg.
co_effect_plot = (effect.sizes(cooccur(rrall, spp_names=T))
	%>% left_join(rr_tax, by=c("sp1"="sppname"))
	%>% rename(sp1Fam=Rank6, sp1Gen=Rank7, sp1Sp=Rank8)
	%>% left_join(rr_tax, by=c("sp2"="sppname"))
	%>% rename(sp2Fam=Rank6, sp2Gen=Rank7, sp2Sp=Rank8)
	%>% ggplot(aes(sp1Fam, effects))
	+ geom_violin()
	+ geom_point()
	+ facet_wrap(~sp2Fam)
	+ geom_hline(yintercept=0)
	+ xlab(NULL)
	+ ylab("Co-occurence effect")
	+ coord_flip()
	+ theme_ggEHD()
	+ theme(legend.position="none"))

ggsave_fitmax("figs/cooccur_effect.pdf", co_effect_plot, maxwidth=12, maxheight=9)
embedFonts("figs/cooccur_effect.pdf")
