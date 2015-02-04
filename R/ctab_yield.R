
nd = read.csv(
	"data/nanodrop.csv",
	colClasses=c("POSIXct", rep("character", 4), rep("numeric", 9), rep("character", 2)))
# nd$Date = as.Date(nd$datetime) # might not need this

ctab_log = read.csv(
	"rawdata/ctab_log.csv",
	colClasses=c("character", rep("Date", 3), rep("character", 2), "numeric", rep("character", 2)))

nd_merged = merge(
	x=ctab_log, 
	y=nd, 
	by.x=c("Nanodrop.date", "Sample.ID"),
	by.y=c("datetime", "Sample.ID"),
	all=TRUE)

library(ggplot2)
pdf(
	file="figs/ctab_yield.pdf", 
	width=9,
	height=6,
	pointsize=24)
print(
	ggplot(
		subset(nd_merged, Species != "H2O" & exclude==""),
		aes(mg.tissue, ng.ul))
	+geom_point()
	+theme_bw()
	+geom_smooth(method="lm")
	+facet_wrap(~Species, scales="free_y"))
dev.off()

write.csv(nd_merged, "data/nd_test.csv")