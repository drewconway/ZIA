# File-Name:       afg_election.R           
# Date:            2010-09-20                                
# Author:          Drew Conway
# Email:           drew.conway@nyu.edu                                      
# Purpose:         Brief analysis of Afghanistan election data
# Data Used:       see load_data.R
# Packages Used:   see load_data.R 
# Output File:    
# Data Output:     
# Machine:         Drew Conway's MacBook Pro

# Copyright (c) 2010, under the Simplified BSD License.  
# For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
# All rights reserved.                                                         

# Load libraries and data
source("load_data.R") # Only run if editing data load

# full.data<-read.csv("dist_violence_voter_turnout_2009.csv")
# prov.data<-read.csv("prov_violence_voter_turnout_2009.csv")

# Create some basic visualizations of district and province level data
prov.lm<-ggplot(prov.data,aes(y=Est_votes/Total.pop,x=Inc_2009/Total.pop))+
    geom_point(aes(size=2,alpha=.5,colour="darkred"))+stat_smooth(method="lm",aes(colour="darkblue"))+
    scale_colour_manual(values=c("darkblue"="darkblue","darkred"="darkred"),name="",breaks=c("darkblue","darkred"),label=c("Linear Fit","Observation"))+
    scale_size_continuous(legend=FALSE)+scale_alpha(legend=FALSE)
prov.lm<-prov.lm+xlab("Provincial Per-capita Security Incidents (2009)")+
    ylab("Provincial Per-capita Voter Turnout")+
    opts(title="Provincial Per-capita Voter Turnout for 2009 Afghanistan\nPresidential Election by Total 2009 Provinical Security Incidents")+
    theme_bw()
ggsave(plot=prov.lm,file="images/prov_lm.png",width=8,height=4)
    
prov.smooth<-ggplot(prov.data,aes(y=Est_votes/Total.pop,x=Inc_2009/Total.pop))+
    geom_point(aes(size=2,alpha=.5,colour="darkred"))+stat_smooth(aes(colour="darkblue"))+
    scale_colour_manual(values=c("darkblue"="darkblue","darkred"="darkred"),name="",breaks=c("darkblue","darkred"),label=c("Lowess Fit","Observation"))+
    scale_size_continuous(legend=FALSE)+scale_alpha(legend=FALSE)
prov.smooth<-prov.smooth+xlab("Provincial Per-capita Security Incidents (2009)")+
    ylab("Provincial Per-capita Voter Turnout")+
    opts(title="Provincial Per-capita Voter Turnout for 2009 Afghanistan\nPresidential Election by Total 2009 Provinical Security Incidents")+
    theme_bw()
ggsave(plot=prov.smooth,file="images/prov_smooth.png",width=8,height=4)

# Take out outliers
lm.noout<-ggplot(subset(prov.data,Inc_2009<900),aes(y=Est_votes/Total.pop,x=Inc_2009/Total.pop))+
    geom_point(aes(size=2,alpha=.5,colour="darkred"))+stat_smooth(method="lm",aes(colour="darkblue"))+
    scale_colour_manual(values=c("darkblue"="darkblue","darkred"="darkred"),name="",breaks=c("darkblue","darkred"),label=c("Linear Fit","Observation"))+
    scale_size_continuous(legend=FALSE)+scale_alpha(legend=FALSE)
lm.noout<-lm.noout+xlab("Provincial Per-capita Security Incidents (2009)")+
    ylab("Provincial Per-capita Voter Turnout")+
    opts(title="Provincial Per-capita Voter Turnout for 2009 Afghanistan\nPresidential Election by Total 2009 Provinical Security Incidents (No Outliers)")+
    theme_bw()
ggsave(plot=lm.noout,file="images/lm_noout.png",width=8,height=4)

smooth.noout<-ggplot(subset(prov.data,Inc_2009<900),aes(y=Est_votes/Total.pop,x=Inc_2009/Total.pop))+
    geom_point(aes(size=2,alpha=.5,colour="darkred"))+stat_smooth(aes(colour="darkblue"))+
    scale_colour_manual(values=c("darkblue"="darkblue","darkred"="darkred"),name="",breaks=c("darkblue","darkred"),label=c("Lowess Fit","Observation"))+
    scale_size_continuous(legend=FALSE)+scale_alpha(legend=FALSE)
smooth.noout<-smooth.noout+xlab("Provincial Per-capita Security Incidents (2009)")+
    ylab("Provincial Per-capita Voter Turnout")+
    opts(title="Provincial Per-capita Voter Turnout for 2009 Afghanistan\nPresidential Election by Total 2009 Provinical Security Incidents (No Outliers)")+
    theme_bw()
ggsave(plot=smooth.noout,file="images/smooth_noout.png",width=8,height=4)