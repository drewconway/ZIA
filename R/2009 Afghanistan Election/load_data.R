# File-Name:       load_data.R           
# Date:            2010-09-21                                
# Author:          Drew Conway
# Email:           drew.conway@nyu.edu                                      
# Purpose:         Loads, parses and writes AFG election data
# Data Used:       http://afghanistanelectiondata.org/open/data   
# Packages Used:   ggplot2,maptools,plyr       
# Output File:    
# Data Output:     
# Machine:         Drew Conway's MacBook Pro

# Copyright (c) 2010, under the Simplified BSD License.  
# For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
# All rights reserved.                                                         

library(ggplot2)
library(maptools)
library(plyr)

# Will need to download these files to make edits
incidents<-read.csv("security_incidents.csv",na.strings="")
poll.nums<-read.csv("pollingcenters_2009.csv",na.strings="")
centerpoints<-read.csv("district_centerpoints.csv",na.strings="")
pop.2009<-read.csv("2009_population.csv")
for(c in 2:4) {pop.2009[,c]<-pop.2009[,c]*1000} # Get data in 1,000

### No use for shapefiles yet...
# Provincial boundaries
#afg.prov<-readShapePoly("prov_shapefile/admin2_poly_32.shp")
#prov.poly<-fortify.SpatialPolygons(afg.prov)
#prov.poly$id<-as.integer(prov.poly$id)

# District boundaries
#afg.dist<-readShapePoly("dist_shapefile/admin3_poly_32.shp")
#dist.poly<-fortify.SpatialPolygons(afg.dist)
#dist.poly$id<-as.integer(dist.poly$id)

# Merge data to associate incidents with voter turnout
full.data<-merge(incidents,centerpoints,by.all=c("lon","lat","Dist_Name"))
# Create df of voter turnout data aggregated by the district level
dist.sums<-ddply(poll.nums,.(Province,Dist_ID),summarise,Est_votes=sum(Estimated.Voters,na.rm=TRUE),
    Total_PS=sum(Total.PS,na.rm=TRUE),Male=sum(Male,na.rm=TRUE),Female=sum(Female,na.rm=TRUE),Kuchi=sum(Kuchi,na.rm=TRUE))
full.data<-merge(full.data,dist.sums,by.all=c("Dist_ID"))

# Create province level aggregation for per-captia voter turnout calculation
prov.data<-ddply(full.data,.(Province,Prov_ID),summarise,Inc_2009=sum(X2009,na.rm=TRUE),Est_votes=sum(Est_votes,na.rm=TRUE),
    Total_PS=sum(Total_PS,na.rm=TRUE),Male=sum(Male,na.rm=TRUE),Female=sum(Female,na.rm=TRUE),Kuchi=sum(Kuchi,na.rm=TRUE))
# Merge in population data
prov.data<-merge(prov.data,pop.2009,by.x="Province",by.y="Provinces")
names(prov.data)<-c("Province","Prov_ID","Inc_2009","Est_votes","Total_PS","Male.votes","Femal.votes",
    "Kuchi","Female.pop","Male.pop","Total.pop")

# Output data as CSV
write.csv(full.data,"dist_violence_voter_turnout_2009.csv")
write.csv(prov.data,"prov_violence_voter_turnout_2009.csv")
