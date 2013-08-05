# File-Name:       better_word_cloud.R           
# Date:            2011-01-26                                
# Author:          Drew Conway
# Email:           drew.conway@nyu.edu                                      
# Purpose:         Attempt to create a more meaningful word-cloud
# Data Used:       obama.txt, palin.txt
# Packages Used:   tm, ggplot2       
# Output File:     obama_cloud.pdf,palin_cloud.pdf
# Data Output:     
# Machine:         Drew Conway's MacBook Pro

# Copyright (c) 2011, under the Simplified BSD License.  
# For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
# All rights reserved.                                                         

# Load libraries and data
library(tm)
library(ggplot2)

### Step 1: Load in text data, clean, and analyze overlapping terms

speeches<-Corpus(DirSource("data/"))
 
# Get word counts
obama.wc<-length(unlist(strsplit(speeches[[1]], " ")))
palin.wc<-length(unlist(strsplit(speeches[[2]], " ")))

# Create a Term-Document matrix
add.stops=c("applause")
speech.control=list(stopwords=c(stopwords(),add.stops), removeNumbers=TRUE, removePunctuation=TRUE)
speeches.matrix<-TermDocumentMatrix(speeches, control=speech.control)

# Create data frame from matrix
speeches.df<-as.data.frame(inspect(speeches.matrix))
speeches.df<-subset(speeches.df, obama.txt>0 & palin.txt>0)
speeches.df<-transform(speeches.df, freq.dif=obama.txt-palin.txt)    

### Step 2: Create values for even y-axis spacing for each vertical
#           grouping of word freqeuncies

# Create separate data frames for each frequency type
obama.df<-subset(speeches.df, freq.dif>0)   # Said more often by Obama
palin.df<-subset(speeches.df, freq.dif<0)   # Said more often by Palin
equal.df<-subset(speeches.df, freq.dif==0)  # Said equally

# This function takes some number as spaces and returns a vertor
# of continuous values for even spacing centered around zero
optimal.spacing<-function(spaces) {
    if(spaces>1) {
        spacing<-1/spaces
        if(spaces%%2 > 0) {
            lim<-spacing*floor(spaces/2)
            return(seq(-lim,lim,spacing))
        }
        else {
            lim<-spacing*(spaces-1)
            return(seq(-lim,lim,spacing*2))
        }
    }
    else {
        return(0)
    }
}

# Get spacing for each frequency type
obama.spacing<-sapply(table(obama.df$freq.dif), function(x) optimal.spacing(x))
palin.spacing<-sapply(table(palin.df$freq.dif), function(x) optimal.spacing(x))
equal.spacing<-sapply(table(equal.df$freq.dif), function(x) optimal.spacing(x))

# Add spacing to data frames
obama.optim<-rep(0,nrow(obama.df))
for(n in names(obama.spacing)) {
    obama.optim[which(obama.df$freq.dif==as.numeric(n))]<-obama.spacing[[n]]
}
obama.df<-transform(obama.df, Spacing=obama.optim)

palin.optim<-rep(0,nrow(palin.df))
for(n in names(palin.spacing)) {
    palin.optim[which(palin.df$freq.dif==as.numeric(n))]<-palin.spacing[[n]]
}
palin.df<-transform(palin.df, Spacing=palin.optim)

equal.df$Spacing<-as.vector(equal.spacing)

### Step 3: Create visualization
tucson.cloud <- ggplot(obama.df, aes(x=freq.dif, y=Spacing))+geom_text(aes(size=obama.txt, label=row.names(obama.df), colour=freq.dif))+
    geom_text(data=palin.df, aes(x=freq.dif, y=Spacing, label=row.names(palin.df), size=palin.txt, color=freq.dif))+
    geom_text(data=equal.df, aes(x=freq.dif, y=Spacing, label=row.names(equal.df), size=obama.txt, color=freq.dif))+
    scale_size(range=c(3,11), name="Word Frequency")+scale_colour_gradient(low="darkred", high="darkblue", guide="none")+
    scale_x_continuous(breaks=c(min(palin.df$freq.dif),0,max(obama.df$freq.dif)),labels=c("Said More by Palin","Said Equally","Said More by Obama"))+
    scale_y_continuous(breaks=c(0),labels=c(""))+xlab("")+ylab("")+theme_bw()+
    theme(panel.grid.major=element_blank(),panel.grid.minor=element_blank(), title=element_text("Word Cloud 2.0, Tucson Shooting Speeches (Obama vs. Palin)"))
ggsave(plot=tucson.cloud,filename="tucson_cloud.png",width=13,height=7)
