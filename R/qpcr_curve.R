# Convert melting curves from a Bio-Rad QX200 droplet PCR analyzer into melting peak form for analysis of melting temperature heterogeneity.
# Usage: qpcr_curve.R datafile.csv idfile.csv

library(qpcR)
source("R/order.plate.R") # for correct sorting of "A1, A10, A11, A12, A2..."

extract.meltcurve = function(mc){
# Each curve is a ragged-shaped data frame, 
# which is really two data structures crammed into one table.
# For the record, this is The Wrong Way To Use A Dataframe 
# and I think less of the package authors for doing it. 
#
# Data structure one: Parameters that have a value for every temperature.
# 	Temp = temperature
# 	Fluo = normalized fluorescence 
# 	df.dT = derivative of fluorescence
#	baseline = estimated baseline fluorescence 
#		(NA at temperatures outside a fitted peak)
#
# Data structure two: Parameters that only have a few values.
# Note that each of these columns starts at row one, goes for however many rows it needs
# to store all the values, and DOES NOT necessarily correspond to the temperature 
# for the row it is stored in (╯°□°）╯︵ ┻━┻). 
# 	Pars = optimized values for span.smooth and span.peaks.
#	RSS = Residual sum of squares from comparing fitted Tm against Tm.opt values. 
#		(NA for us because we leave TM.opt null).
#	Tm = estimated melting temperature, one line per fitted peak.
#	Area = Peak area within Tm.border °C of Tm, one line per fitted peak.
#
# So, let's break this Not Really A Dataframe up into a more useful list. 
	structure(list(
		fitted=mc[,c("Temp", "Fluo", "df.dT", "baseline")],
		pars=c(na.omit(mc$Pars)),
		RSS=c(na.omit(mc$RSS)),
		peaks = data.frame(
			Tm=c(na.omit(mc$Tm)), 
			Area=c(na.omit(mc$Area))),
		quality=attr(mc, "quality"),
		class=c("meltcurve", "list")))
}

get_peaks = function(mc){
# Takes a meltcurve, returns a dataframe containing Tm and area of each fitted peak.
	stopifnot(mc$quality == "good")
	return(mc$peaks)
}

get_fitted = function(mc){
# Takes a meltcurve, returns a dataframe containing: Temperature; smoothed, normalized fluorescence; rate of change; baseline fluorescence.
	stopifnot(mc$quality == "good")
	return(mc$fitted)
}


args = commandArgs(trailingOnly=TRUE)
curvedat = read.csv(args[1])
iddat = read.csv(args[2], stringsAsFactors=FALSE)

# column 1 is empty, column 2 is Temperature
wellnames=colnames(curvedat)[-c(1,2)]

# For a full plate, expect a 98-col datafile and a 96-line ID file.
# Any line of the ID file where "Sample" is blank will be skipped in the analysis.
# If you also want to skip samples where "Censor" is *not* blank, uncomment the second set_id assignment.
stopifnot(
	nrow(iddat) == ncol(curvedat)-2
	&& all(c("Well", "Sample", "Censor") %in% colnames(iddat)))
ids = iddat$Sample
set_ids = seq_along(ids)[ids != ""]
# set_ids = seq_along(ids)[ids != "" & iddat$Censor == ""]


# Normalize, smooth, and fit melting peaks all in one step. See the qpcR::meltcurve() documentation for details on how it does the fitting.
# The plot is pretty ugly and we'll make a prettier version in a later step, but let's save this one too for diagnostic pourposes.
pdf(
	file="figs/multi_ctab_peakfit-20150421.pdf", #FIXME FIXME FIXME: let Makefile specify path!
	width=45,
	height=30,
	pointsize=24)
curves = meltcurve(
	data=curvedat, 
	temps=rep(2, length(set_ids)), # expects one column of temperatures for every column of fluorescence, so pass the same column repeatedly.
	fluos=2+set_ids, # column numbers to analyze (we're skipping empty wells).
	window=c(80,90), # Picked these values for 2015-03-19 run, check before trusting on others.
	norm=TRUE, # scale so max fluorescence in each curve = 1, min ditto = 0
	plot=TRUE,
	Tm.opt=NULL,
	Tm.border=c(0.5,0.5)) # compute "baseline" from Tm +/- this many °C
		# (Usually far above the actual bottom of the peak!)
dev.off()

names(curves) = wellnames[set_ids]

curves = lapply(curves, extract.meltcurve)

# Collect summary statistics for the whole dataset:
# npeaks = How many peaks were found in each sample
# main_tm = Melting temperature of the peak with the largest area
#	N.B. this isn't really the same as "average melting temperature" 
#	and may or may not actually be a useful metric.
peaks = lapply(curves, get_peaks)
peak_summary = data.frame(
	npeak=sapply(peaks, nrow),
	main_tm=sapply(peaks, function(x)with(x, Tm[which.max(Area)])))
peak_summary$Well = wellnames[set_ids]
peak_summary = merge(peak_summary, iddat, all.x=TRUE)

# Fix ordering by forcing "A2" to sort before "A10" instead of after.
peak_summary = peak_summary[order.plate(peak_summary$Well),]

# OK, summary is done. Write it out and move on.
#FIXME FIXME FIXME: let Makefile specify path!
write.csv(peak_summary, file="data/multi_ctab_melt_summary-20150421.csv", quote=FALSE, row.names=FALSE)



# Extract normalized fluorescence data, add sample ID info, 
# save as one long dataframe.
fitted = lapply(curves, get_fitted) # returns a named list of dataframes
fitted = mapply( # add name to each dataframe in list as a new column 
	FUN=function(x,n){x$Well=n;x}, 
	fitted, 
	names(fitted), SIMPLIFY=FALSE)
fitted_summary = do.call("rbind", fitted)
fitted_summary = merge(fitted_summary, iddat, all.x=TRUE)

# Sort in plate order (TODO: maybe should sort by sample instead?)
fitted_summary = fitted_summary[order.plate(fitted_summary$Well),]

# FIXME FIXME FIXME: let Makefile specify path!
write.csv(fitted_summary, file="data/multi_ctab_melt_curves-20150421.csv", quote=FALSE, row.names=FALSE)