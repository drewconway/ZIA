# File-Name:       super_bowl.R           
# Date:            2011-02-07                                
# Author:          Drew Conway
# Email:           drew.conway@nyu.edu                                      
# Purpose:         Gather and manipulate historic Super Bowl score data
# Data Used:       Wikipedia Super Bowl data
# Packages Used:   ggplot2, RCurl, XML
# Output File:    
# Data Output:     
# Machine:         Drew Conway's MacBook Pro

# Copyright (c) 2011, under the Simplified BSD License.  
# For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
# All rights reserved.                                                         

# Load libraries
library(ggplot2)
library(RCurl)
library(XML)

# A function that converts a given integer into its Roman Numeral equivalent
to.RomanNumeral<-function(x) {
    if(0 < x & x < 5000) {
        x<-as.integer(x)
        digits<-c(1000,900,500,400,100,90,50,40,10,9,5,4,1)
        numerals<-c("M","CM","D","CD","C","XC","L","XL","X","IX","V","IV","I")
        digits.numerals<-as.data.frame(cbind(digits,numerals), stringsAsFactors=FALSE)
        numeral<-""
        for(i in 1:nrow(digits.numerals)) {
            while(x >= as.numeric(digits.numerals[i,1])) {
                numeral<-paste(numeral,digits.numerals[i,2],sep="")
                x<-x-as.numeric(digits.numerals[i,1])
            }
        }
        return(numeral)
    }
    else {
         stop(paste(x,"is invalid. Input must be an integer between 1 and 4,999"))
    }
}

# Function returns quater scores from Wikipedia Super Bown pages
get.scores<-function(numeral) {
    # Base URL for Wikipedia 
    wp.url<-getURL(paste("http://en.wikipedia.org/wiki/Super_Bowl_",numeral,sep=""))
    wp.data<-htmlTreeParse(wp.url, useInternalNodes=TRUE)
    score.html<-getNodeSet(wp.data,"//table[@style='background-color:transparent;']")
    score.table<-readHTMLTable(score.html[[1]])
    score.table<-transform(score.table, SB=numeral)
    return(score.table)
}

# Function returns the right-most digit of numer
last.digit<-function(x) {
    digits<-strsplit(as.character(x),"")[[1]]
    last.digit<-digits[length(digits)]
    return(as.numeric(last.digit))
}

# Function takes an nxm matrix of scores and returns a nxn matrix of
# probability of winning given a combination of digits
get.probs<-function(score.df) {
    digits.sums<-sum(score.df[,2:11])*10
    prob.matrix<-matrix(ncol=10,nrow=10)
    for(i in 1:10) {
        for(j in 1:10) {
            prob.matrix[i,j]<-(score.df[1,i+1]+score.df[2,j+1])/digits.sums
        }
    }
    prob.df<-as.data.frame(prob.matrix, row.names=0:9)
    names(prob.df)<-0:9
    return(prob.df)
}

# There have been 45 Super Bowls
bowls<-lapply(1:45, to.RomanNumeral)

# Create data frame of all Super Bowl scores
scores.list<-lapply(bowls, get.scores)
scores.df<-data.frame(do.call(rbind, scores.list))

# Fix the data types
scores.df$X1<-as.numeric(as.character(scores.df$X1))
scores.df$X2<-as.numeric(as.character(scores.df$X2))
scores.df$X3<-as.numeric(as.character(scores.df$X3))
scores.df$X4<-as.numeric(as.character(scores.df$X4))
scores.df$Total<-as.numeric(as.character(scores.df$Total))

# Add quarter scoring data to data frame
quarters.list<-lapply(1:nrow(scores.df), function(i) c(scores.df[i,2],sum(scores.df[i,2:3]),sum(scores.df[i,2:4])))
quarters.df<-as.data.frame(do.call(rbind, quarters.list))

# Final data set
super.df<-cbind(scores.df, quarters.df,rep(as.factor(c("Home","Away")),45))
names(super.df)<-c("Team","Q1","Q2","Q3","Q4","Total","SB","Q1T","Q2T","Q3T","Type")

# Get digit count totals in workable data frame for visualization
digits.df<-ddply(super.df,.(SB,Type), summarise, Q1D=last.digit(Q1T), Q2D=last.digit(Q2T), Q3D=last.digit(Q3T), 
    Q4D=last.digit(Total))

# Create separate data frames for each quarter
q1.counts<-ddply(digits.df,.(Type), summarise, D0=length(which(Q1D==0)), D1=length(which(Q1D==1)), D2=length(which(Q1D==2)),
    D3=length(which(Q1D==3)), D4=length(which(Q1D==4)), D5=length(which(Q1D==5)), D6=length(which(Q1D==6)), D7=length(which(Q1D==7)),
    D8=length(which(Q1D==8)), D9=length(which(Q1D==9)))
q1.probs<-get.probs(q1.counts)
    
q2.counts<-ddply(digits.df,.(Type), summarise, D0=length(which(Q2D==0)), D1=length(which(Q2D==1)), D2=length(which(Q2D==2)),
    D3=length(which(Q2D==3)), D4=length(which(Q2D==4)), D5=length(which(Q2D==5)), D6=length(which(Q2D==6)), D7=length(which(Q2D==7)),
    D8=length(which(Q2D==8)), D9=length(which(Q2D==9)))
q2.probs<-get.probs(q2.counts)

q3.counts<-ddply(digits.df,.(Type), summarise, D0=length(which(Q3D==0)), D1=length(which(Q3D==1)), D2=length(which(Q3D==2)),
    D3=length(which(Q3D==3)), D4=length(which(Q3D==4)), D5=length(which(Q3D==5)), D6=length(which(Q3D==6)), D7=length(which(Q3D==7)),
    D8=length(which(Q3D==8)), D9=length(which(Q3D==9)))
q3.probs<-get.probs(q3.counts)

q4.counts<-ddply(digits.df,.(Type), summarise, D0=length(which(Q4D==0)), D1=length(which(Q4D==1)), D2=length(which(Q4D==2)),
    D3=length(which(Q4D==3)), D4=length(which(Q4D==4)), D5=length(which(Q4D==5)), D6=length(which(Q4D==6)), D7=length(which(Q4D==7)),
    D8=length(which(Q4D==8)), D9=length(which(Q4D==9)))
q4.probs<-get.probs(q4.counts)

### Create visualizations

# Create a data frame for boxes
positions<-do.call(rbind, lapply(0:9, function(x) cbind(0:9,x)))
boxes<-data.frame(x=positions[,1],y=positions[,2])
boxes$Q1<-melt(q1.probs)$value
boxes$Q2<-melt(q2.probs)$value
boxes$Q3<-melt(q3.probs)$value
boxes$Q4<-melt(q4.probs)$value

# Create a heatmap of probability of winning given different digit combinations by quarter
q1.heatmap<-ggplot(boxes, aes(xmin=x,xmax=x+1,ymin=y,ymax=y+1))+geom_rect(aes(color="white", fill=Q1))+
    scale_fill_gradient(limits=c(0,.047), low="lightgrey", high="darkred", name="Pr(Winning)")+
    scale_color_manual(values=c("white"="white"), legend=FALSE)+theme_bw()+
    scale_x_continuous(breaks=.5:9.5,labels=0:9)+scale_y_continuous(breaks=.5:9.5,labels=0:9)+
    xlab("Home Team")+ylab("Away Team")+opts(title="Heat Map of Win Probabilties -- First Quater")
ggsave(plot=q1.heatmap, filename="images/q1_heatmap.png", height=12, width=12)

q2.heatmap<-ggplot(boxes, aes(xmin=x,xmax=x+1,ymin=y,ymax=y+1))+geom_rect(aes(color="white", fill=Q2))+
    scale_fill_gradient(limits=c(0,.047), low="lightgrey", high="darkred", name="Pr(Winning)")+
    scale_color_manual(values=c("white"="white"), legend=FALSE)+theme_bw()+
    scale_x_continuous(breaks=.5:9.5,labels=0:9)+scale_y_continuous(breaks=.5:9.5,labels=0:9)+
    xlab("Home Team")+ylab("Away Team")+opts(title="Heat Map of Win Probabilties -- Half Time")
ggsave(plot=q2.heatmap, filename="images/q2_heatmap.png", height=12, width=12)

q3.heatmap<-ggplot(boxes, aes(xmin=x,xmax=x+1,ymin=y,ymax=y+1))+geom_rect(aes(color="white", fill=Q3))+
    scale_fill_gradient(limits=c(0,.047), low="lightgrey", high="darkred", name="Pr(Winning)")+
    scale_color_manual(values=c("white"="white"), legend=FALSE)+theme_bw()+
    scale_x_continuous(breaks=.5:9.5,labels=0:9)+scale_y_continuous(breaks=.5:9.5,labels=0:9)+
    xlab("Home Team")+ylab("Away Team")+opts(title="Heat Map of Win Probabilties -- Third Quarter")
ggsave(plot=q3.heatmap, filename="images/q3_heatmap.png", height=12, width=12)

q4.heatmap<-ggplot(boxes, aes(xmin=x,xmax=x+1,ymin=y,ymax=y+1))+geom_rect(aes(color="white", fill=Q4))+
    scale_fill_gradient(limits=c(0,.047), low="lightgrey", high="darkred", name="Pr(Winning)")+
    scale_color_manual(values=c("white"="white"), legend=FALSE)+theme_bw()+
    scale_x_continuous(breaks=.5:9.5,labels=0:9)+scale_y_continuous(breaks=.5:9.5,labels=0:9)+
    xlab("Home Team")+ylab("Away Team")+opts(title="Heat Map of Win Probabilties -- Final")
ggsave(plot=q4.heatmap, filename="images/q4_heatmap.png", height=12, width=12)



