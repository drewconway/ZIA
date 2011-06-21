# File-Name:       chicago_crime.R
# Date:            2011-06-20
# Author:          Drew Conway
# Email:           drew.conway@nyu.edu                                      
# Purpose:         Create analysis of year of Chicago crime data
# Data Used:       Crimes.csv, crimes_by_day.csv
# Packages Used:   ggplot2, maptools
# Machine:         Drew Conway's MacBook Pro

# Copyright (c) 2011, under the Simplified BSD License.  
# For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
# All rights reserved.

# Load libraries
library(ggplot2)
library(maptools)

# # Only run this section if you wish to work with the raw data The processes takes a long time!
# crimes <- read.csv("Crimes.csv", stringsAsFactors=FALSE)
# 
# # Get count of crimes by day, type, and location.
# # Notice the typo in the header for this data :)
# crimes.by.day <- ddply(crimes, .(DATE..OF.OCCURRENCE, PRIMARY.DECSRIPTION, X.COORDINATE, Y.COORDINATE), 
# 						summarise, COUNT=length(ARREST))
# 						
# # Fix date and sort
# crimes.by.day$DATE <- as.Date(crimes.by.day$DATE..OF.OCCURRENCE, format="%m/%d/%Y")
# crimes.by.day <- crimes.by.day[with(crimes.by.day, order(DATE)),]
# write.csv(crimes.by.day, "crimes_by_day.csv", row.names=FALSE)

# Load in clean data
crimes.by.day <- read.csv("crimes_by_day.csv", stringsAsFactors=FALSE)
crimes.by.day$DATE <- as.Date(crimes.by.day$DATE)
cpd.shp <- readShapePoly("cpd_beats/cpd_beats.shp")	
cpd.df <- fortify.SpatialPolygons(cpd.shp)

# Top crimes (with +1,000 total incidents in the data)
crimes <- c("THEFT", "BATTERY", "NARCOTICS", "CRIMINAL DAMAGE", "BURGLARY", "OTHER OFFENSE", "MOTOR VEHICLE THEFT",
 			"ASSAULT", "ROBBERY", "DECEPTIVE PRACTICE", "CRIMINAL TRESPASS", "WEAPONS VIOLATION", "PUBLIC PEACE VIOLATION",
			"OFFENSE INVOLVING CHILDREN", "NON-CRIMINAL", "PROSTITUTION", "CRIM SEXUAL ASSAULT", "SEX OFFENSE")
crimes.bds <- subset(crimes.by.day, !is.na(match(PRIMARY.DECSRIPTION, crimes)))

# The setup
day.num <- 1
date.range <- seq.Date(as.Date(min(crimes.bds$DATE)), as.Date(max(crimes.bds$DATE)), "days")
day.plot <- ggplot(cpd.df, aes(x=long, y=lat))+geom_path(aes(group=group))

# A simple loop to create a well-formated ggplot2 a 10 day window of mapped crime data 
for(day in date.range) {
	time.range <- ggplot(crimes.bds, aes(x=DATE))+stat_density(aes(fill=PRIMARY.DECSRIPTION, position="stack"))+theme_bw()+
		xlab("")+ylab("")+scale_fill_discrete(legend=FALSE)+opts(axis.text.y=theme_blank())
	if(day <= date.range[10]) {
		day.df <- subset(crimes.bds, DATE==day & !is.na(match(PRIMARY.DECSRIPTION, crimes)))
		day.plot <- day.plot+theme_bw()+opts(title=paste("Crime in Chicago, as of from", 
								strftime(min(crimes.bds$DATE), format="%b %d, %Y"),"to", strftime(max(day.df$DATE), format="%b %d, %Y")), 
								panel.grid.major=theme_blank(), panel.grid.minor=theme_blank(), 
								axis.text.x=theme_blank(), axis.text.y=theme_blank(), axis.ticks=theme_blank())
		time.range <- time.range+geom_vline(xintercept=as.numeric(date.range[day.num+1]):as.numeric(max(date.range)), alpha=0.3)+
									scale_alpha(legend=FALSE)
	}
	else {
		day.df <- subset(crimes.bds, DATE <= day & DATE > date.range[day.num-10] & !is.na(match(PRIMARY.DECSRIPTION, crimes)))
		day.plot <- ggplot(cpd.df, aes(x=long, y=lat))+geom_path(aes(group=group))
		day.plot <- day.plot+theme_bw()+opts(title=paste("Crime in Chicago, as of from", 
								strftime(min(day.df$DATE), format="%b %d, %Y"),"to", strftime(max(day.df$DATE), format="%b %d, %Y")), 
								panel.grid.major=theme_blank(), panel.grid.minor=theme_blank(), 
								axis.text.x=theme_blank(), axis.text.y=theme_blank(), axis.ticks=theme_blank())
		time.range <- time.range+geom_vline(xintercept=c(as.numeric(date.range[1]):as.numeric(date.range[day.num-10]), 
									as.numeric(date.range[day.num+1]):as.numeric(max(date.range))), alpha=0.3)+
									scale_alpha(legend=FALSE)
	}
	if(nrow(day.df) > 0) {
		day.plot <- day.plot+geom_point(data=day.df, aes(x=X.COORDINATE, y=Y.COORDINATE, size=2, color=PRIMARY.DECSRIPTION, alpha=COUNT/100))+
					scale_size(legend=FALSE, to=c(1.5))+scale_alpha(legend=FALSE)+scale_alpha(legend=FALSE, to=c(0.3,0.5))+
					scale_colour_discrete(name="Type of Crime")+xlab("")+ylab("")
	}
	# Save image
	ggsave(plot=day.plot, filename=paste("maps/", day.num, ".png", sep=""), 
			height=9, width=11)
	ggsave(plot=time.range,	filename=paste("timelines/", day.num, "_time.png", sep=""), 
			height=2, width=11)
	day.num <- day.num + 1
}

# Run this line to compose the images (recquires ImageMagick)
# ./compose_images

# Run this to generate the video (recquires ffmpeg)
# ffmpeg -f image2 -r 10 -i images/%d.png -b 800k Chicgo_crime.mp4

