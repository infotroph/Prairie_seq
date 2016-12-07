# Plot summaries of melting peaks fit by qpcR::meltcurve().
# This is an uuuugly format. Need to either improve this or can the whole script.

# Usage: plot_melt_summary.R peaksummary.csv

library(ggplot2)
library(grid)
library("DeLuciatoR")
library("ggplotTicks")
theme_set(theme_ggEHD())

peak_summary = read.csv(commandArgs(trailingOnly=TRUE)[[1]])

pdf(
	file="figs/multi_ctab_melt_npeak_tm-20150421.pdf", #FIXME hard-coded path
	width=9,
	height=6,
	pointsize=24)

plot(mirror_ticks(ggplot(
		peak_summary, 
		aes(Tissue, npeak, shape=factor(Extractions)))
	+geom_point(position=position_jitter(w=0.25, h=0.1))
	+coord_flip()))

plot(mirror_ticks(ggplot(
		#peak_summary[peak_summary$main_tm > 77.5,], 
		peak_summary,
		aes(Tissue, main_tm, shape=factor(Extractions)))
	+geom_point(position=position_jitter(w=0.1, h=0.25))
	+coord_flip()))

dev.off()
