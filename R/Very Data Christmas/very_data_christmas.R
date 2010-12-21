# File-Name:       very_data_christmas.R           
# Date:            2010-12-20                                
# Author:          Drew Conway
# Email:           drew.conway@nyu.edu                                      
# Purpose:         Search for popularity of christmas terms in Infochimps data
# Data Used:       Christmas lyrics from Internet
# Packages Used:   infochimps,tm,ggplot2
# Output File:    
# Data Output:     
# Machine:         Drew Conway's MacBook Pro

# Copyright (c) 2010, under the Simplified BSD License.  
# For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
# All rights reserved.                                                         

# Load libraries
library(infochimps)
library(tm)
library(ggplot2)

my.api<-"your.api.key"
infochimps(my.api)

# Create vector corpus of all Christmas Carol lyrics using tm packge
# to clean up (strip punctuation, whitspace and stopwords)
# Lyrics downloaded from http://ldsguy.tripod.com/Christmas.carols.html
carols.txt<-readLines("carols.txt")
carols.txt<-tolower(carols.txt)
carols.txt<-gsub("[[:punct:]]","",carols.txt)
carols.corpus<-Corpus(VectorSource(carols.txt), readerControl=list(reader=readPlain,language="english"))
# Remove stop worlds and eliminate whitespace
carols.clean<-tm_map(carols.corpus, stripWhitespace)
carols.clean<-tm_map(carols.clean, removeWords, stopwords("english"))
# Create vector of only words, then create counts
carols.words<-unlist(lapply(carols.clean, function(c) strsplit(c, " ",fixed=TRUE)))
carols.words<-carols.words[which(carols.words!="")]
carols.df<-as.data.frame(list(Words=carols.words),stringsAsFactors=FALSE)
carols.df<-ddply(carols.df,.(Words), nrow)
names(carols.df)<-c("Words","Count")

# Next, add data from infochimps on word usage on Twitter
# WARNING: This takes 755 API calls and is not reccommended
# for users with free IC acounts. It also takes several minutes
infochimps.data<-sapply(carols.df$Words, word.stats)

# Clean up IC data
infochimps.matrix<-do.call(rbind,infochimps.data)
infochimps.list<-lapply(1:ncol(infochimps.matrix), function(x) as.vector(unlist(infochimps.matrix[,x])))
infochimps.df<-as.data.frame(do.call(cbind, infochimps.list), stringsAsFactors=FALSE)
names(infochimps.df)<-colnames(infochimps.matrix)
infochimps.df$global_stdev_ppb<-as.numeric(infochimps.df$global_stdev_ppb)
infochimps.df$range<-as.numeric(infochimps.df$range)
infochimps.df$global_freq_ppb<-as.numeric(infochimps.df$global_freq_ppb)

# Merge data sets
christmas.df<-merge(carols.df, infochimps.df, by.x="Words", by.y="tok")
write.csv(christmas.df, "christmas_carols_data.csv", row.names=FALSE)

# Now let's create some plots!

# Top words in Carols
top.words<-subset(christmas.df, Count>=10)
top.words<-top.words[with(top.words, order(Count,Words)),]
top.plot<-ggplot(top.words, aes(xmin=(1:nrow(top.words))-.5,xmax=(1:nrow(top.words))+.5,ymin=0,ymax=Count))+
    geom_rect(aes(fill="lightgreen",color="firebrick"))+coord_flip()+scale_alpha(legend=FALSE)+
    scale_x_continuous(breaks=1:nrow(top.words),labels=top.words$Word)+
    theme_bw()+scale_fill_manual(value=c("lightgreen"="lightgreen"),legend=FALSE)+
    scale_colour_manual(values=c("firebrick"="firebrick","lightgrey"="lightgrey"),legend=FALSE)+
    ylab("Number of Times Word Appears in All Carols")+
    opts(title="Most Popular Christmas Carols Words", panel.grid.major=theme_blank())
ggsave(plot=top.plot,filename="images/top_carol_words.png",width=8,height=6)

# Top words from Carols on Twitter
twitter.words<-christmas.df[with(christmas.df, order(-global_freq_ppb)),]
twitter.words<-twitter.words[1:nrow(top.words),]
twitter.words<-twitter.words[with(twitter.words, order(global_freq_ppb)),]
twitter.plot<-ggplot(twitter.words, aes(xmin=(1:nrow(twitter.words))-.5,xmax=(1:nrow(twitter.words))+.5,ymin=0,ymax=global_freq_ppb))+
    geom_rect(aes(fill="firebrick",color="lightgreen"))+coord_flip()+scale_alpha(legend=FALSE)+
    scale_x_continuous(breaks=1:nrow(twitter.words),labels=twitter.words$Word)+
    theme_bw()+scale_fill_manual(value=c("firebrick"="firebrick"),legend=FALSE)+
    scale_colour_manual(values=c("lightgreen"="lightgreen","lightgrey"="lightgrey"),legend=FALSE)+
    ylab("Number of Times Word Appears on Twitter (parts per-billion)")+
    opts(title="Most Popular Words from Christmas Carols on Twitter", panel.grid.major=theme_blank())
ggsave(plot=twitter.plot,filename="images/top_twitter_words.png",width=8,height=6)

# Scatter of word counts by Twitter popularity
carol.scatter<-ggplot(subset(christmas.df,Count>4), aes(x=global_freq_ppb,y=Count))+geom_text(aes(label=Words,size=3,alpha=0.75,colour=range))+
    scale_x_log10()+theme_bw()+xlab("Number of Times Word Appears on Twitter [log(parts per-billion)]")+
    ylab("Frequency of Word in All Christmas Carols")+scale_alpha(legend=FALSE)+
    scale_colour_gradient(low="firebrick",high="forestgreen",name="# of unique users\nwho’ve used word\n(normalized)")+
    scale_size(legend=FALSE)+opts(title="Old Versus New\n(Scatter of Words That Appear 5+ Times in Carols)", panel.grid.major=theme_blank())
ggsave(plot=carol.scatter,filename="images/carol_scatter.png",width=8,height=6)