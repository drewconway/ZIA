# File-Name:       farouk_analysis.R                 
# Date:            2009-12-30                                
# Author:          Drew Conway                                       
# Purpose:         Brief analysis of data on Christmas Day bomber web forum postings
# Data Used:       farouk_data.csv
# Packages Used:   ggplot2
# Output File:     
# Data Output:     
# Machine:         Drew Conway's MacBook                         
                                                                    
library(ggplot2)

farouk.data<-read.csv("farouk_data.csv")

# Plot 1, scatter of log(views) to log(replies) for all forum messgaes
png("scatter.png",width=800,height=800)
views<-ggplot(farouk.data,aes(x=log(views),y=log(replies)))+geom_point(aes(colour=replies/views,size=(replies/views)*1000))
views<-views+xlab("log(Views)")+ylab("log(Replies)")+opts(title="Scatter of log(Views) vs. log(Replies)")
print(views)
dev.off()

# Plot 2, track of user activity on posts
png("activity.png",width=1400,height=500)
activity<-ggplot(farouk.data,aes(x=id))+geom_line(aes(y=views,colour="Views"))+geom_line(aes(y=replies,colour="Replies"))
activity<-activity+opts(title="Time Series of Posts View and Reply Activity")+xlab("Posts (Chronological)")+ylab("Count")
activity<-activity+scale_colour_manual(name="Activity",values=c("Views"="black","Replies"="blue"))
print(activity)
dev.off()

# Plot 3, histogram of posts by date
png("hist.png",width=800,height=800)
hist.plot<-ggplot(farouk.data,aes(x=date))+geom_histogram()+scale_x_date(minor="weeks",major="months")
hist.plot<-hist.plot+xlab("Date (bin=range/30)")+ylab("Count")+opts(title="Histogram of Post Activity from 2005-2007")
print(hist.plot)
dev.off()

