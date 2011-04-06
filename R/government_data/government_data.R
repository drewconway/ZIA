# File-Name:       government_data.R           
# Date:            2011-04-05                                
# Author:          Drew Conway
# Email:           drew.conway@nyu.edu                                      
# Purpose:         Show the frequency of companies in CrunchBase matching "government" and "data"
# Data Used:       CrunchBase API
# Packages Used:   RCurl, RJSONIO, ggplot2
# Output File:     companies_timeseries.pdf
# Machine:         Drew Conway's MacBook Pro

# Copyright (c) 2011, under the Simplified BSD License.  
# For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
# All rights reserved.                                                         

library(RCurl)
library(RJSONIO)
library(ggplot2)

# A function to get all of the companies matching a given query in the 
# CrunchBase data base
get.companies<-function(q,p,total=FALSE) {
    cb.base<-paste("http://api.crunchbase.com/v/1/search.js?query=",q,"&page=",p,sep="")
    cb.url<-getURL(cb.base)
    cb.parse<-tryCatch(fromJSON(cb.url), error = function(e) return(NA))
    # We need to find the total number of campanies first
    # so we can ping all of the pages (silly API method)
    if(total){
        return(cb.parse$total)
    }
    if(is.na(cb.parse)) {
        return(NA)   
    }
    if(is.null(cb.parse$results[[1]])){
        return(NA)
    }   
    else {
        company.data<-sapply(cb.parse$results, function(x) c(x$namespace,x$permalink))
        return(company.data[2,which(company.data[1,]=="company")])
    }
}

# Retrieve founding date information for a company. Some campanies do not have this,
# so we use the date the entry was created as a proxy
get.founding<-function(company) {
    company.base<-paste("http://api.crunchbase.com/v/1/company/",company,".js",sep="")
    company.url<-getURL(company.base)
    company.parse<-fromJSON(company.url)
    # Convert data
    year<-ifelse(is.null(company.parse$founded_year),"",company.parse$founded_year)
    month<-ifelse(is.null(company.parse$founded_month),"",company.parse$founded_month)
    day<-ifelse(is.null(company.parse$founded_day),"",company.parse$founded_day)
    created<-ifelse(is.null(company.parse$created_at),"",company.parse$created_at)
    return(c(company, year, month, day, created))
}

# Two query sets
q1="government"
q2="data"

# Page limits for both queries
q1.lim<-ceiling(get.companies(q1,1,total=TRUE)/10)
q2.lim<-ceiling(get.companies(q2,1,total=TRUE)/10)

# Let's go get the company data!

# 'government' query
q1.data<-sapply(1:q1.lim, function(i) get.companies(q1, i))
q1.data<-unique(unlist(q1.data))
# 'data' query
q2.data<-sapply(1:q2.lim, function(i) get.companies(q2, i))
q2.data<-unique(unlist(q2.data))

# Take intersection
matching.companies<-intersect(q1.data, q2.data)

# Create data frame of founding dates for all matching companies
founding.data<-lapply(matching.companies, get.founding)
founding.matrix<-do.call(rbind, founding.data)
founding.df<-data.frame(founding.matrix, stringsAsFactors=FALSE)
names(founding.df)<-c("company","year","month","day","created")
founding.df$created<-strptime(founding.df$created, format="%a %b %d %H:%M:%S UTC %Y")

# Create a subset that includes only the last 60 years
founding.years<-subset(founding.df, year!="" & year>=1950)
founding.years$year<-as.numeric(founding.years$year)

# Create a kernel density plot of frequencies over all years
firm.dens<-ggplot(founding.years, aes(x=year))+stat_density(aes(color="red",fill=FALSE))+
    stat_bin(aes(y=..density..,color="blue",fill="lightblue",alpha=.6),binwidth=1)+
    scale_color_manual(values=c("blue"="blue","red"="red"),legend=FALSE)+
    scale_fill_manual(values=c("lightblue"="lightblue"),legend=FALSE)+
    scale_alpha(legend=FALSE)+theme_bw()+xlab("Years")+ylab("Density")+
    opts(title="Frequency of Company Foundings by Year in CrunchBase\nMatching 'government' and 'data' (1950-2010)")
