# Read raw Nanodrop output, 
# Correct IDs as needed,
# write to one output file.

library(lubridate)

args = commandArgs(trailingOnly = TRUE)

read.nanodrop = function(path){
	read.delim(path, colClasses=c(rep("character",4), rep("numeric", 9))) 
}
nd_raw = do.call("rbind", lapply(args, read.nanodrop))
nd_raw$datetime = with(nd_raw, parse_date_time(paste(Date, Time), "mdyhm"))

corrections = read.csv(
	"rawdata/nanodrop/nanodrop_corrections.csv", 
	colClasses=rep("character", 4), 
	strip.white=TRUE)
corrections$datetime = parse_date_time(corrections$datetime, "ymdhm")

nd_merge = merge(
	x=nd_raw, 
	y=corrections, 
	by.x =c("datetime", "Sample.ID"),
	by.y=c("datetime", "savedID"),
	all.x=TRUE)

changed_rows = which(nd_merge$newID !="" & !is.na(nd_merge$newID))
stripped_rows = which(nd_merge$newID == "" & !is.na(nd_merge$newID))

nd_merge$Sample.ID[changed_rows] = nd_merge$newID[changed_rows]
nd_merge = nd_merge[-stripped_rows,]

write.csv(
	nd_merge, 
	file="data/nanodrop.csv", 
	quote = FALSE,
	row.names=FALSE)
