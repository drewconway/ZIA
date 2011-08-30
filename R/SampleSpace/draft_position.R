# File-Name:       draft_position.R                 
# Date:            2010-08-16                                
# Author:          Drew Conway
# Email:           drew.conway@nyu.edu                                      
# Purpose:         Download and parse draft position data from http://fantasyfootballcalculator.com/
# Data Used:       
# Packages Used:   XML,plyr,reshape
# Output File:    
# Data Output:     
# Machine:         Drew Conway's MacBook Pro

# Copyright (c) 2010, under the Simplified BSD License.  
# For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
# All rights reserved.                                                         

### Load libraries
library(XML)
library(ggplot2)
library(plyr)
library(reshape)

### Draft specific vars
num.teams<-10           # Number of teams in your league
rounds<-15              # Number of rounds completed, should not change (15 standard num to complete draft for 10 teams)
num.obs<-500            # Number of drafts to scrape and parse
humans <- 5				# Number of human drafters, in my case I want at least half humans

### URL vars
base.url<-"http://fantasyfootballcalculator.com/draft/"
seed.url<-paste("http://fantasyfootballcalculator.com/completed_drafts.php?format=standard&teams=",num.teams,sep="")


### Helper functions
get.seeds<-function(url,rounds, humans) {
# Returns url ids for drafts matching num.team and rounds criteria
    seed.drafts<-readHTMLTable(seed.url,header=TRUE, stringsAsFactors=FALSE)[[1]]
	names(seed.drafts) <- c("DraftID", "Date", "Time(EST)", "Format", "TotalTeams", "Humans", "Rounds", "RoundsCompleted", "ViewEntireDraft")
	seed.drafts$RoundsCompleted <- as.numeric(seed.drafts$RoundsCompleted)
	seed.drafts$Humans <- as.numeric(seed.drafts$Humans)
    fit.drafts<-subset(seed.drafts, RoundsCompleted == rounds & Humans >= humans)
    return(fit.drafts$DraftID)
}

get.df<-function(draft.id,num.teams,rounds) {
# Retruns draft data as properly formatted data frame
    draft.table<-readHTMLTable(paste(base.url,draft.id,sep=""),header=1:num.teams+1)
    draft.order<-t(do.call(cbind,draft.table))
    draft.order<-draft.order[1:num.teams+1,]
    # Melt data into draft order
    raw<-melt(draft.order)
    raw<-gsub(" ","",as.character(raw$value))
    # Create seperate columsn for player name, position and team
    raw<-strsplit(raw,"[\\(\\)]")
    raw<-do.call(rbind,raw)
    player<-raw[,1]  # Players
    team<-raw[,2]    # Team
    # Create vector for player position
    pos<-sapply(player,function(x) substring(x,nchar(x)-1))
    # Strip keep just player name
    player<-sapply(player,function(x)substring(x,first=1,last=nchar(x)-2))
    order<-1:length(player) # Draft order
    df<-cbind(player,pos,team,order)
    row.names(df)<-order
    colnames(df)<-c("Player","Position","Team","Order")
    return(df)
}

### Draft position data

# 1) Get seed draft IDs
first.draft<-get.seeds(seed.url,rounds, humans)
draft.data<-lapply(first.draft,function(d) {get.df(d,num.teams,rounds)})

# 2) Build out list of data frames
chunk.pos <- 25
while(length(draft.data)<num.obs) {
	new.seeds<-get.seeds(paste(seed.url,"&list=",chunk.pos,sep=""),rounds, humans)
    seed.data<-lapply(new.seeds,function(d) {get.df(d,num.teams,rounds)})
    # Add new data to full set
    for(f in seed.data) {
        draft.data[[length(draft.data)+1]]<-f
    }
    chunk.pos <- chunk.pos + 25  # NOTE, the final number of observations may be > num.obs, but will never be less
}

# 3) Take list of draft position data frames and convert to single data frame with 
raw.output<-"raw_draft.csv"

drafts.df<-do.call(rbind,draft.data)
row.names(drafts.df)<-1:nrow(drafts.df)
drafts.df<-as.data.frame(drafts.df,stringsAsFactors=FALSE)
drafts.df$Order<-as.numeric(drafts.df$Order)
write.csv(drafts.df,raw.output, row.names=FALSE)    # Output raw data

# Compute draft statistics  
drafts.stats<-ddply(drafts.df,.(Player,Position,Team),summarise,Mean=mean(Order),
    StdDev=sd(Order),Freq=length(Order)/length(draft.data),MAD=mad(Order),Median=median(Order))

# Clean up and output
drafts.stats$Player<-as.character(drafts.stats$Player)
drafts.stats <- drafts.stats[with(drafts.stats, order(Mean)),]
write.csv(drafts.stats,"stats_draft.csv", row.names=FALSE)

### Bonus: player performance data from AdvancedNFLStats.com

# URL vars
stat.url<-"http://wp.advancednflstats.com/playerstats.php"
positions<-c("QB","RB","WR","TE")


### Helper functions 
get.stats<-function(pos) {
# Get player stats
    stat.url<-paste("http://wp.advancednflstats.com/playerstats.php?year=2010&pos=",pos,"&season=reg",sep="")
    stats<-readHTMLTable(stat.url,header=T,stringsAsFactors=FALSE)[[1]]
    return(cbind(stats,pos))
}

### Get the data
player.stats<-lapply(positions,get.stats)
names(player.stats)<-positions

scoring.system<-list(
        "QB"=function(qb.df) {}
        )

# Output as csv
for(p in positions) {
    write.csv(player.stats[[p]],paste("Players/", p, "_stats.csv", sep=""))
}

### Visualizations

# One image to show players most difficult to evaluate
ex.mad<-quantile(drafts.stats$MAD,.95)
value.plot<-ggplot(subset(drafts.stats,drafts.stats$MAD>=ex.mad),aes(Median,MAD))+geom_text(aes(label=Player,alpha=.85,colour="red",size=3.5),
    position=position_jitter(w=4,h=2))
value.plot<-value.plot+geom_point(data=subset(drafts.stats,drafts.stats$MAD<ex.mad))+stat_smooth(data=drafts.stats,aes(Median,MAD))+theme_bw()
value.plot<-value.plot+xlab("Median Player Draft Position")+ylab("Median Absolute Deviation (MAD) Player Draft Position")+
    opts(title="Most Variant Player Rankings in 2011 Fantasy Football")+
    annotate("text",label="Only players with MAD in the \n95th percentile are labeled",colour="darkred",x=20,y=40)+
    scale_colour_manual(legend=FALSE,values=c("red"="darkred"))+scale_alpha(legend=FALSE)+scale_size_continuous(legend=FALSE)
ggsave(plot=value.plot,filename="images/hard_valuation.png",height=7,width=10,dpi=120)

