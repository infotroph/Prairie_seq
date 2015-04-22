library(ggplot2)
library(grid)
source("~/R/DeLuciatoR/ggthemes.r")
source("~/R/ggplot-ticks/mirror.ticks.r")
theme_set(theme_ggEHD())

files = commandArgs(trailingOnly=TRUE)

read.trace=function(path){
	# each file has 17 lines of headers, 
	# then 1482 rows of data, 
	# then a footer afterwards indicating alignment status.
	a = read.csv(
		file=path,
		skip=17,
		nrows=1482)	
	# Example filename:"2100 expert_DNA 7500_DE34903367_2015-04-21_12-39-18_Ladder_001.csv"
	splitpath = strsplit(basename(path), "_")[[1]]
	a$RunID=splitpath[5]
	a$SampleID = gsub("(.*)\\..*", "\\1", splitpath[6]) # gsub to drop file extension
	return(a)
}
traces = do.call("rbind", lapply(files, read.trace))

sample_map = read.csv(
	text='
		SampleID,Species,Extraction
		Ladder,Ladder,NA
		Sample1,Silphium integrifolium,1
		Sample2,Silphium integrifolium,2
		Sample3,Silphium integrifolium,3
		Sample4,Silphium integrifolium,4
		Sample5,Andropogon gerardii, 1
		Sample6,Andropogon gerardii,2
		Sample7,Andropogon gerardii,3
		Sample8,Andropogon gerardii,4
		Sample9,Dalea purpurea,1
		Sample10,Dalea purpurea,2
		Sample11,Dalea purpurea,3
		Sample12,Dalea purpurea,4
		Sample13,Escherichia coli,NA
		Sample14,Haemophilus influenzae,NA
		Sample15,Rhodobacter sphaeroides,NA
		Sample16,Mixed bacteria,NA',
	stringsAsFactors=FALSE,
	strip.white=TRUE
)

traces = merge(traces, sample_map)

rootplot = (ggplot(subset(traces, RunID=="12-39-18" & Species!="Ladder"), aes(Time, Value, color=factor(Extraction)))
	+facet_wrap(~Species, ncol=1)
	+geom_line()
	+scale_color_discrete(name="Extractions")
	+scale_x_continuous(
		# I extracted these by hand. There's _probably_ a better way...
		breaks=c(35,38.25,50.45,60.2,67.35,72.85,75.95,77.5,79.8,82.7,84.7,88), 
		labels=c(50,100,300,500,700,1000,1500,2000,3000,5000,7000,10380),
		limits=c(37,60),
		name="Fragment length, bp")
	+scale_y_continuous(
		name="Fluorescence",
		limits=c(-7,60))
)	

bactplot = (ggplot(subset(traces, RunID=="13-23-20" & Species!="Ladder"), aes(Time, Value, color=Species))
	+geom_line()
	+scale_color_discrete(
		name="Species",
		breaks=c("Escherichia coli", "Haemophilus influenzae", "Rhodobacter sphaeroides", "Mixed bacteria"))
	+scale_x_continuous(
		breaks=c(35.05,38.25,50.45,60.2,67.35,72.85,75.95,77.5,79.8,82.7,84.7,88), 
		labels=c(50,100,300,500,700,1000,1500,2000,3000,5000,7000,10380),
		limits=c(37,60),
		name="Fragment length, bp")
	+scale_y_continuous(
		name="Fluorescence",
		limits=c(-7,150))
)	

pdf(
	file="figs/bioanalyzer_root_traces_20150421.pdf", 
	width=11,
	height=8.5,
	pointsize=12)
plot(mirror.ticks(rootplot))
dev.off()

pdf(
	file="figs/bioanalyzer_bact_traces_20150421.pdf", 
	width=11,
	height=8.5,
	pointsize=12)
plot(mirror.ticks(bactplot))
dev.off()
