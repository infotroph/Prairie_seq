library(ggplot2)
library(grid)
source("~/R/DeLuciatoR/ggthemes.r")
source("~/R/ggplot-ticks/mirror.ticks.r")
source("R/facetAdjust.R") 	# adjusts bottom axes when panels are aligned ragged.
							# LICENSE FOR THIS CODE MAY NOT BE BSD-COMPATIBLE -- DO NOT COMMIT TO REPOSITORY until clarified
theme_set(theme_ggEHD())


fitted = read.csv(commandArgs(trailingOnly=TRUE)[[1]], stringsAsFactors=FALSE)

# Want plants in one column, bact in another.
# Dumb approach: Set Tissue factor levels in an order that happens to coincide with this layout
fitted$Tissue = factor(
	fitted$Tissue,
	levels=c(
		"E. coli K12",
		"Andropogon gerardii",
		"Haemophilus influenzae",
		"Dalea purpurea",
		"Rhodobacter sphaeroides",
		"Silphium integrifolium",
		"Mixed Bacterial Sample"))

pdf(
	file="figs/multi_ctab_melt_curves-20150421.pdf", #FIXME hard-coded filenames
	width=8.5,
	height=11,
	pointsize=12)
plt=(ggplot(
		fitted,
		aes(Temp, 
			df.dT, 
			color=factor(Extractions),
			# lty=factor(Extractions),  
			group=Well))
	+geom_line()
	+facet_wrap(~Tissue, ncol=2)
	+xlab("Temperature (°C)")
	+ylab("d(relative fluorescence)/dT")
	+guides(
		col=guide_legend(title="Times Extracted"),
		lty=guide_legend(title="Times Extracted"))
)
# plot(mirror.ticks(plt))
facetAdjust(plt,)
dev.off()