library(lubridate)
library(ggplot2)
library(grid)

source("~/R/DeLuciatoR/ggthemes.r")
source("~/R/ggplot-ticks/mirror.ticks.r")
theme_set(theme_ggEHD())

weights = read.csv("rawdata/buffer_saturation_ctab.csv", stringsAsFactors=FALSE,
	colClasses=c("character", rep("Date", 3), rep("character", 2), rep("numeric", 3)))
concs = read.delim("rawdata/nanodrop/CTAB-M_90minOptimization_2015-05-26.txt", stringsAsFactors=FALSE)

replacements = read.csv(stringsAsFactors=FALSE, text="
datetime,oldID,newID,note
2015-05-26 12:46,1X TE,,checking blank
2015-05-26 01:54,CRS 36B,,suspect poor mixing
2015-05-26 01:55,CRS 36B.1,CRS 36B,reread after mixing with little change
2015-05-26 01:57,CRS 24,,mislabeled and reread in next line
2015-05-26 02:16,CRS 10B,,suspect poor mixing
2015-05-26 02:17,CRS 10B.1,CRS 10B,reread after mixing with little change
2015-05-26 02:22,CRS 8A,,suspect poor mixing
2015-05-26 02:23,CRS 8A.1,CRS 8A,reread after mixing with little change
2015-05-26 02:24,H2O,,checking blank
2015-05-26 02:44,CRS 6,,bad reading
2015-05-26 02:46,CRS 6,,bad reading
2015-05-26 02:50,CRS H2O,,checking blank
2015-05-26 03:04,CRS H2O,,checking blank
2015-05-26 03:39,CRS H2O,,checking blank
2015-05-26 03:52,CRS 32,,bad reading
2015-05-26 03:52,CRS 32.1,CRS 32,remeasured after bad reading
2015-05-26 04:19,CRS H2O,,checking blank
2015-05-26 03:03,CRS 37A,,suspect bad blank
2015-05-26 03:05,CRS 37A.1,CRS 37A,reread after blanking with little change
2015-05-26 03:54,CRS 37A,,suspect bad blank
2015-05-26 04:18,CRS 37A,,bad reading
2015-05-26 04:18,CRS H2O,,checking blank
2015-05-26 04:20,CRS 37A,,duplicated
")

concs$datetime = with(concs, parse_date_time(paste(Date, Time), "mdyhm"))
replacements$datetime=parse_date_time(replacements$datetime, "ymdhm")

concs = concs[!grepl("H2O|TE", concs$Sample.ID),] # drop Nanodrop blanks

concs = merge(
	x=concs,
	y=replacements,
	by.x=c("datetime", "Sample.ID"),
	by.y=c("datetime", "oldID"),
	all.x=TRUE)

changed_rows = which(concs$newID !="" & !is.na(concs$newID))
stripped_rows = which(concs$newID == "" & !is.na(concs$newID))

concs$Sample.ID[changed_rows] = concs$newID[changed_rows]
concs = concs[-stripped_rows,]

concs$sample = gsub("CRS ", "", concs$Sample.ID)
concs$splitID = ifelse(
	grepl("A|B", concs$sample),
	gsub(".*(A|B).*", "\\1", concs$sample),
	"")
concs$sample = gsub("[^0-9]", "", concs$sample)

merged = merge(weights, concs, by="sample", all=TRUE)

# Sanity checks 
print(with(merged, table(Species, uL.buffer, minutes.incubation)))
stopifnot(nrow(merged[merged$uL.buffer == 650,]) == 20)
stopifnot(nrow(merged[merged$uL.buffer == 1300,]) == 40)
stopifnot(all(grepl("^[A|B]$", merged$splitID[merged$uL.buffer == 1300])))
stopifnot(!anyNA(merged$ng.ul))
stopifnot(!anyNA(merged$mg.tissue))

# 1300-uL samples are split during extraction, we want total DNA recovery from both.
merged.sum = aggregate(ng.ul~sample+Species+minutes.incubation+uL.buffer, merged, FUN=sum) 
# weight of 1300-uL samples was duplicated in merge, just need one of them.
merged.wt = aggregate(mg.tissue~sample+minutes.incubation+uL.buffer, merged, FUN=unique)

merged.sum = merge(merged.sum, merged.wt)
merged.sum$ng.dna = merged.sum$ng.ul*50
merged.sum$ng.mg = merged.sum$ng.dna/merged.sum$mg.tissue

# shorter names for more convenient stats display
merged.sum$extraction = factor(
	paste(merged.sum$minutes.incubation, merged.sum$uL.buffer),
	levels=c("30 650", "30 1300", "90 650", "90 1300"))
merged.sum$Species = factor(merged.sum$Species)
merged.sum$mins = factor(merged.sum$minutes.incubation)
merged.sum$uLs = factor(merged.sum$uL.buffer)
rownames(merged.sum) = merged.sum$sample

buffertest = lm(ng.mg ~ Species * mins * uLs, merged.sum[merged.sum$Species != "H2O",])
predframe = expand.grid(
			uLs=factor(c(650, 1300)),
			mins=factor(c(30, 90)),
			Species=c("AnGe", "DaPu", "SiIn"))
pred = predict(
		buffertest, 
		interval="prediction",
		newdata=predframe)
capture.output(
	summary(buffertest),
	cat("\n\n"),
	anova(buffertest),
	cat("\n\n"),
	cbind(predframe, pred),
	file="data/buffersat-anovas.txt")

pdf(
	file="figs/ctab_buffersat.pdf",
	width=9,
	height=6,
	pointsize=24)
print(
	ggplot(subset(merged.sum, Species != "H2O"), aes(mins, ng.mg, color=uLs))
	+geom_smooth(aes(group=uLs), method="lm", se=FALSE)
	+geom_boxplot()
	+geom_point()
	+facet_wrap(~Species))
plot(buffertest, which=c(1:6), cex=0.8)
plot(
	resid(buffertest) ~ extraction,
	subset(merged.sum, Species != "H2O"))
hist(resid(buffertest))
dev.off()


