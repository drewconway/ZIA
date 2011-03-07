# File-Name:       polisci_language.R           
# Date:            2011-03-07                                
# Author:          Drew Conway
# Email:           drew.conway@nyu.edu                                      
# Purpose:         Scrape and analyze langauge used on poliscijobrumors.com
# Data Used:       
# Packages Used:   tm, XML, igraph, ggplot2
# Output File:    
# Data Output:     
# Machine:         Drew Conway's MacBook Pro

# Copyright (c) 2011, under the Simplified BSD License.  
# For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
# All rights reserved.                                                         

library(igraph)
library(ggplot2)
library(tm)
library(XML)

# How many forum threads to scrape
forum.max<-1000

# A function that returns a vector of URL's to poliscijobrumors.com posting threads. The
# parameter 'num.threads' indicates the number of URLs to be returned.
get.threads<-function(num.threads) {
    page<-1
    url.vec<-c()
    base.url<-"http://www.poliscijobrumors.com/forum.php?id=1&page="
    while(length(url.vec) <= num.threads) {
        thread.parse<-htmlTreeParse(paste(base.url,as.character(page),sep=""), useInternalNodes=TRUE)
        thread.nodes<-getNodeSet(thread.parse, "//table[@id='latest']//td//a")
        new.urls<-sapply(thread.nodes, function(x) xmlGetAttr(x, "href"))
        url.vec<-c(url.vec, new.urls[!grepl("post", new.urls, fixed=TRUE)]) # Ignore 'post' type URLS
        page<-page+1
    }
    return(url.vec)
}

# Get URLS
thread.urls<-get.threads(forum.max)

# A function that takes a thread URL for poliscijobrumors.com and returns the enture thread 
# as one-element chartacter vector.
get.thread<-function(polisci.url) {
    text.parse<-htmlTreeParse(polisci.url, useInternalNodes=TRUE)
    text.nodes<-getNodeSet(text.parse, "//div[@class='post']")
    text.vec<-sapply(text.nodes, xmlValue)
    return(paste(text.vec, collapse="\n"))
}

# Create a vector of all forum text from 'thread.urls'
forum.texts<-sapply(thread.urls, get.thread)

# We have all the wonderful texts!  Now, we can create a text corpus from this
# vector with 'VectorSource'
polisci.corpus<-Corpus(VectorSource(forum.texts))

# Next, create a term-document matrix, for the primary analysis
polisci.stopwords<-unique(c(stopwords(), gsub("[[:punct:]]","",stopwords())))
polisci.controller<-list(weighting=weightTf, stopwords=polisci.stopwords, removePunctuation=TRUE, 
    tolower=TRUE, minWordLength=4, removeNumbers=TRUE)
polisci.matrix<-TermDocumentMatrix(polisci.corpus, control=polisci.controller)

# Remove sparse terms from matrix
polisci.clean<-removeSparseTerms(polisci.matrix, .95)

raw.clean<-as.matrix(polisci.clean)

# Create a word affiliations matrix
term.affiliations<-raw.clean %*% t(raw.clean)
term.adjacency<-term.affiliations
diag(term.adjacency)<-0

# Create a graph, and then plot
polisci.graph<-graph.adjacency(term.adjacency, weighted=TRUE)

# Prepare for visualization
position.matrix<-layout.fruchterman.reingold(polisci.graph, list(weightsA=E(polisci.graph)$weight))
position.matrix<-cbind(V(polisci.graph)$name, position.matrix)

# Create a data frame
words.df<-data.frame(position.matrix, stringsAsFactors=FALSE)
names(words.df)<-c("term","x.pos","y.pos")
words.df$x.pos<-as.numeric(words.df$x.pos)
words.df$y.pos<-as.numeric(words.df$y.pos)

# k-means experiment
words.kmeans<-kmeans(cbind(as.numeric(position.matrix[,2]), as.numeric(position.matrix[,3])), 8)

# Add new data back in
words.df<-transform(words.df, freq=diag(term.affiliations), cluster=as.factor(words.kmeans$cluster))
row.names(words.df)<-1:nrow(words.df)

# Subset of words
words.subset<-subset(words.df, freq>quantile(words.df$freq)[2]) # first quantile

# I can haz viz?
polisci.words<-ggplot(words.subset, aes(x=x.pos, y=y.pos))+geom_text(aes(size=log10(freq), label=words.subset$term, alpha=.75, color=as.factor(cluster)))+
    theme_bw()+scale_size(legend=FALSE)+scale_alpha(legend=FALSE)+xlab("")+ylab("")+scale_color_brewer(pal="Dark2", legend=FALSE)+
    scale_x_continuous(breaks=c(min(words.subset$x.pos), max(words.subset$x.pos)), labels=c("",""))+
    scale_y_continuous(breaks=c(min(words.subset$y.pos), max(words.subset$y.pos)), labels=c("",""))+
    opts(panel.grid.major=theme_blank(), panel.grid.minor=theme_blank(), axis.ticks=theme_blank())
ggsave(plot=polisci.words, filename="polisci_words.pdf", height=10, width=10)