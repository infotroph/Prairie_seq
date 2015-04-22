library(ggplot2)
library(grid)
source("~/R/DeLuciatoR/ggthemes.r")
source("~/R/ggplot-ticks/mirror.ticks.r")
theme_set(theme_ggEHD())


fitted = read.csv(commandArgs(trailingOnly=TRUE)[[1]], stringsAsFactors=FALSE)

pdf(
	width=11,
	height=8.5,
	file="figs/multi_ctab_melt_curves-20150421.pdf", #FIXME hard-coded filenames
	pointsize=12)
plt=(ggplot(
		fitted,
		aes(Temp, 
			df.dT, 
			color=factor(Extractions),
			# lty=factor(Extractions),  
			group=Well))
	+geom_line()
	+facet_wrap(~Tissue)
	+xlab("Temperature (°C)")
	+ylab("d(relative fluorescence)/dT")
	+guides(
		col=guide_legend(title="Times Extracted"),
		lty=guide_legend(title="Times Extracted"))
)
plot(mirror.ticks(plt))
dev.off()