# File-Name:       foodtech.R           
# Date:            2010-12-04                                
# Author:          Drew Conway
# Email:           drew.conway@nyu.edu                                      
# Purpose:         Analysis and viz from foodtech event
# Data Used:       Milk_COP.csv
# Packages Used:   ggplot2
# Output File:    
# Data Output:     
# Machine:         Drew Conway's MacBook Pro

# Copyright (c) 2010, under the Simplified BSD License.  
# For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
# All rights reserved.                                                         

# To install dependencies run the following at the R console
# > install.packages("ggplot2", dependencies=TRUE)
# > install.packages("RExcelXML", repos = "http://www.omegahat.org/R", type="source")
library(ggplot2)
library(RExcelXML)
library(maps)

### Milk explorations

# First create data
milk<-read.csv("../data/Milk_COP.csv",stringsAsFactors=FALSE)
milk$GEOGRAPHY_DESC<-gsub(" ","",milk$GEOGRAPHY_DESC)
milk$GEOGRAPHY_DESC<-tolower(milk$GEOGRAPHY_DESC)
milk<-subset(milk, GEOGRAPHY_DESC!="")
states <- map_data("state")
milk<-milk[with(milk, order(YEAR_ID, TIMEPERIOD_ID)),]
states<-states[with(states, order(region)),]
names(milk)<-c("SOURCE_ID", "COMMODITY_DESC", "region", "ATTRIBUTE_DESC", "UNIT_DESC", "YEAR_ID", "TIMEPERIOD_ID", "TIMEPERIOD_DESC", "AMOUNT")

# Visualization of milk producer operating costs
operating.cost<-subset(milk, COMMODITY_DESC=="Total operating costs")
plot_num<-1
for(y in unique(milk$YEAR_ID)) {
    for(m in unique(milk$TIMEPERIOD_ID)) {
        current.milk<-subset(milk, COMMODITY_DESC=="Total operating costs" & YEAR_ID==y & TIMEPERIOD_ID==m)
        current.geo<-join(states, current.milk, by="region")
        current.plot<-ggplot(current.geo, aes(x=long,y=lat))+geom_polygon(aes(fill=AMOUNT,group=group))+
            scale_fill_gradient(low="cornsilk",high="darkgreen",limits=c(min(operating.cost$AMOUNT),max(operating.cost$AMOUNT)),name="Dollars per CWT")+
            geom_path(aes(group=group))+theme_bw()+coord_map(projection="lagrange")+
            opts(title=paste("Operating Costs for Milk Producers by State: ",y,"-",m,sep=""),panel.grid.major=theme_blank(),axis.ticks=theme_blank(),axis.text.x=theme_blank(),axis.text.y=theme_blank())+
            xlab("")+ylab("")
        # ggsave(plot=current.plot,filename=paste("../images/milk_maps/operating",y,"_",m,".png",sep=""),width=11,height=7)
        ggsave(plot=current.plot,filename=paste("../images/milk_maps/operating",plot_num,".png",sep=""),width=11,height=7)
        plot_num<-plot_num+1
    }
}