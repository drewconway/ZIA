# File-Name:       vets_day.R           
# Date:            2010-11-11                                
# Author:          Drew Conway
# Email:           drew.conway@nyu.edu                                      
# Purpose:         Map of VA Homeless Grant and Per Diem FY09 distributions
# Data Used:       Datagov_VHA_FY09_Capital_Grant.csv
# Packages Used:   ggplot2, plyr, XML
# Output File:    
# Data Output:     
# Machine:         Drew Conway's MacBook Pro

# Copyright (c) 2010, under the Simplified BSD License.  
# For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
# All rights reserved.                                                         

# Load libraries
library(ggplot2)
library(plyr)
library(XML)
library(maps)

# Load and clean the data
va.df<-read.csv("Datagov_VHA_FY09_Capital_Grant.csv", as.is=TRUE)
va.df$Grant<-as.numeric(gsub("[$,]","",va.df$Grant))
va.df<-ddply(va.df,.(Center,City,State), summarise, Grant=sum(Grant))

# API keys for geo-code look-up with Yahoo!
# You will need your own Yahoo! ID, which you can get here:

yahoo.id<-"your.id"
geo.lookup<-"http://local.yahooapis.com/MapsService/V1/geocode?appid="

# Function for taking a [city,state] vector and returning [lat,long] vector
get.geo<-function(place.vec) {
    geo.url<-paste(geo.lookup,yahoo.id,"&city=",place.vec[1],"&state=",place.vec[2])
    geo.xml<-xmlTreeParse(geo.url,isURL=TRUE)
    root<-geo.xml[[1]]
    lat<-root[["ResultSet"]][["Result"]][["Latitude"]][["text"]]
    long<-root[["ResultSet"]][["Result"]][["Longitude"]][["text"]]
    return(c(lat$value,long$value))
}

# Get geocodes, and add to data frame
lat.long<-lapply(1:nrow(va.df), function(x) get.geo(cbind(va.df[x,2],va.df[x,3])))
lat.long<-do.call("rbind", lat.long)
va.df$Latitude<-as.numeric(lat.long[,1])
va.df$Longitude<-as.numeric(lat.long[,2])

# Save data frame
write.csv(va.df, "va_data.csv")

# Visualize on map and save
us.map<-data.frame(map("state", plot=FALSE)[c("x","y")]) 
us.map$group<-1

va.plot<-ggplot(us.map, aes(x=x,y=y))+geom_path(aes(group=group, alpha=0.5))
va.plot<-va.plot+geom_point(data=va.df, aes(x=Longitude,y=Latitude,size=Grant,colour="goldenrod", alpha=0.65))+
    scale_size_continuous(to=c(3,10), name="Grant and Stipend (USD)")+scale_colour_manual(values=c("goldenrod"="goldenrod"),legend=FALSE)+
    scale_alpha(legend=FALSE,to=c(0.5,0.65))+coord_map()+theme_bw()+xlab("")+ylab("")+scale_size(breaks=seq(225000,1750000,250000),name="Grant and Stipend (USD)")+
    opts(title="VA Homeless Grant and Per Diem FY09",axis.text.x=theme_blank(),axis.text.y=theme_blank(),axis.ticks=theme_blank(),panel.grid.major=theme_blank())
ggsave(plot=va.plot, filename="va_homeless.png", width=8,height=5)