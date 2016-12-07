library(ggplot2)
library(grid)
library(vegan)
library("DeLuciatoR")
source("R/order.plate.R")
theme_set(theme_ggEHD())


fitted = read.csv(commandArgs(trailingOnly=TRUE)[[1]], stringsAsFactors=FALSE)
keydat = unique(fitted[, c("Well", "Sample", "Censor", "Tissue", "Extractions")])

norm_fluor = t(unstack(fitted, Fluo ~ Well))
norm_slope = t(unstack(fitted, df.dT ~ Well))

# make sure all datasets are sorted the same way
fitted = fitted[order.plate(fitted$Well),]
norm_fluor = norm_fluor[order.plate(rownames(norm_fluor)),]
norm_slope = norm_slope[order.plate(rownames(norm_slope)),]
keydat = keydat[order.plate(keydat$Well),]

fluor_clust = hclust(dist(norm_fluor), method="complete")
slope_clust = hclust(dist(norm_slope), method="complete")
clustlabel=paste(keydat$Tissue, keydat$Extractions)

# Compute Euclidean distance between each curve and some reference curve. 
# I'm using the first E. coli curve here, but this is arbitrary.
# TODO: maybe use mean of both E. coli instead -- calculate mean, add to matrix, take diff, remove from result vector.
# FIXME: Whatever you use, stop using hardcoded well numbers
fluor_dist_ec = as.matrix(dist(norm_fluor))["G3",]
fluor_dist_ec = data.frame(FluoDist=fluor_dist_ec, Well=names(fluor_dist_ec))
fluor_dist_ec = merge(fluor_dist_ec, keydat)

slope_dist_ec = as.matrix(dist(norm_slope))["G3",]
slope_dist_ec = data.frame(SlopeDist=slope_dist_ec, Well=names(slope_dist_ec))

dist_ec = merge(fluor_dist_ec, slope_dist_ec, all=TRUE)

stopifnot( # Sanity check -- did all the merges work as expected?
	nrow(dist_ec) == nrow(norm_fluor)
	&& nrow(dist_ec) == nrow(norm_slope)
	&& ncol(dist_ec) == 7)

fluorplt = (ggplot(
		dist_ec, 
		aes(Extractions, FluoDist, group=Extractions))
	+geom_boxplot()
	+facet_wrap(~Tissue)
	+ylab("Change in fluorescence (Euclidean distance from E. coli curve)"))
slopeplt = (ggplot(
		dist_ec, 
		aes(Extractions, SlopeDist, group=Extractions))
	+geom_boxplot()
	+facet_wrap(~Tissue)
	+ylab("Change in line slope (Euclidean distance from E. coli curve)"))

# Drop unamplified samples for ordination
fitted = droplevels(fitted[fitted$Censor == "" | is.na(fitted$Censor),])
norm_fluor = t(unstack(fitted, Fluo ~ Well))
norm_slope = t(unstack(fitted, df.dT ~ Well))
colnames(norm_fluor) = fitted$Temperature[fitted$Well == fitted$Well[1]]
colnames(norm_slope) = colnames(norm_fluor)

keydat = unique(fitted[, c("Well", "Sample", "Tissue", "Extractions")])

fluo_mds = metaMDS(norm_fluor, distance="euclidean")
slope_mds = metaMDS(norm_slope, distance="euclidean")

fluo_env = envfit(fluo_mds ~ Tissue * poly(Extractions,3), data=keydat)
slope_env = envfit(slope_mds ~ Tissue * poly(Extractions,3), data=keydat)

fluo_test = adonis(
	norm_fluor ~ Tissue * poly(Extractions,3), 
	keydat, 
	method="euclidean",
	permutations=5000)
slope_test = adonis(
	norm_slope ~ Tissue * poly(Extractions,3), 
	keydat, 
	method="euclidean",
	permutations=5000)

capture.output(
	print("envfit: Fluorescence"),
		print(fluo_env),
		print("envfit: Slope"),
		print(slope_env),
		print("adonis: Fluorescence"),
		print(fluo_test),
		print("adonis: Slope"),
		print(slope_test),
	file="data/multi_ctab_melt_distance_ordresults-20150421.txt" #FIXME hardcoded filenames
)

fluo_rda = rda(
	norm_fluor~Tissue*Extractions, 
	data=keydat,
	scale=F)
slope_rda = rda(
	norm_slope~Tissue*Extractions, 
	data=keydat,
	scale=F)

pdf(
	file="figs/multi_ctab_melt_distance-20150421.pdf", #FIXME hardcoded filenames
	width=10,
	height=8,
	pointsize=12)
plot(fluor_clust, main="fluorescence", labels=clustlabel)
plot(slope_clust, main="d(fluorescence)/d(Temperature)", labels=clustlabel)
plot(fluorplt)
plot(slopeplt)
plot(fluo_mds, main="Fluorescence", type="text")
plot(fluo_env)
plot(slope_mds, main="Slope", type="text")
plot(slope_env)
plot(
	fluo_rda,
	display=c("sites", "species"),
	scaling=1,
	type="text",
	main="RDA: Fluorescence")
plot(
	slope_rda,
	display=c("sites", "species"),
	scaling=1,
	type="text",
	main="RDA: Slope")
dev.off()
