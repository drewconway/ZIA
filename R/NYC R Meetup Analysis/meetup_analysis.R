# File-Name:       meetup_analysis.R                 
# Date:            2010-03-11                                
# Author:          Drew Conway                                       
# Purpose:         Analyzing a year worth of data from the NYC R Meetups
# Data Used:       meetup text and csv files
# Packages Used:   XML,ggplot2
# Output File:     png files
# Data Output:     
# Machine:         Drew Conway's MacBook                         
                                                                    
library(ggplot2)
library(XML)

### Meetup topics word cloud ###

# Get the raw meetup description into a dataframe
raw_desc<-levels(read.table('descriptions.txt',sep="\n")$V1)
clean_strings<-function(s){
    low<-tolower(s)
    clean<-gsub("[[:punct:]\n]","",low)
    return(strsplit(clean," "))
}
word_vector<-unlist(lapply(raw_desc,clean_strings))
words<-as.data.frame(table(word_vector[which(word_vector!="")]))
colnames(words)<-c("WORD","COUNT")

# Retrieve 100 most common English words from Wikipedia, 
# and remove them from data frame
com_words<-melt(readHTMLTable("http://en.wikipedia.org/wiki/Most_common_words_in_English"))
com_words<-tolower(as.vector(com_words$Word))
com_words<-append(com_words,c("is","are")) # Somehow, 'is' and 'are' are not among the 100 most common words
word_ind<-match(words$WORD,com_words)
words_clean<-words[which(is.na(word_ind)),]
words_final<-words_clean[which(words_clean$COUNT>1),] # Restrict cloud to words appearing more than once

# Now, let's make a word cloud in ggplot2
x<-runif(nrow(words_final),-1.5,1.5)
y<-runif(nrow(words_final),-1,1)
words_final<-transform(words_final,X=x,Y=y)
png("meetup_cloud.png",res=400,height=800,width=1000)
ggplot(words_final,aes(X,Y))+geom_text(aes(label=WORD,size=COUNT))+opts(legend.position="none")+xlab("")+ylab("")+
    scale_x_continuous(breaks=c(-2,0,2),labels=c("","",""))+scale_y_continuous(breaks=c(-1.5,0,1.5),labels=c("","",""))
dev.off()
# This requires some trial and error to minimize overlap, there is probably 
# a better way to specify locations to avoid overlap

### Meetup activity history ###

joins<-read.csv("New_York_R_Statistical_Programming_Meetup_Groups_Joins.csv")
rsvp<-read.csv("New_York_R_Statistical_Programming_Meetup_RSVPs.csv")
activity<-read.csv("New_York_R_Statistical_Programming_Meetup_Total_and_Active_Members.csv")

# Merge the data into a single frame
all<-merge(joins,rsvp,by="Date",all=TRUE)
all<-merge(all,activity,by="Date",all=TRUE)
all_dates<-as.vector(all$Date)

# Fix dates and convert to POSIX
make_date<-function(d) {
    date<-strsplit(d,"/")[[1]]
    if(nchar(date[1])<2){date[1]<-paste("0",date[1],sep="")}
    if(nchar(date[2])<2){date[2]<-paste("0",date[2],sep="")}
    return(paste("20",date[3],"-",date[1],"-",date[2],sep=""))
}

new_dates<-unlist(lapply(all_dates,make_date))
all$Date<-as.Date(new_dates)
all<-all[order(all$Date),]
rownames(all)<-1:nrow(all)

# Replace NAs with zeros
all$Member.Joins[which(is.na(all$Member.Joins))]<-0
all$RSVPs[which(is.na(all$RSVPs))]<-0

# Find first date where memebrship is counted
first_record<-1
while(is.na(all$Total.Members[first_record])) {first_record<-first_record+1}

# Create vector for 'estimated' group size
est_members<-rep(NA,nrow(all))
est_members[1]<-all$Member.Joins[1]
for (i in seq(2,first_record-1)) {est_members[i]<-est_members[i-1]+all$Member.Joins[i]}
all<-transform(all,Estimated.Members=est_members)

# Fill in NA after first_recrod with previous entry data
for (i in seq(first_record+1,nrow(all))) {
        if(is.na(all$Total.Members[i])) {
                all$Total.Members[i]<-all$Total.Members[i-1]
                all$Active.Members[i]<-all$Active.Members[i-1]
        }
}

# Create chart
png("meet_timeseries.png",res=120,height=700,width=1500)
members<-ggplot(all,aes(Date))+geom_bar(aes(y=Member.Joins,fill="Member Joins"),stat="identity")+
    geom_bar(aes(y=RSVPs,fill="RSVPs"),stat="identity",position="stack")+
    geom_line(aes(y=Estimated.Members/10,colour="Est. Total Members/10",linetype=2,size=.8))+geom_line(aes(y=Total.Members/10,colour="Total Members/10",size=.8))+
    geom_line(aes(y=Active.Members/10,colour="Active Members/10",size=.8))+annotate("text",x=as.Date("2009-05-15"),y=30,label="Dashed line is estimated group size",size=3.5)+
    scale_colour_manual(name="Group Membership/Activity",values=c("Est. Total Members/10"="#CC1100","Total Members/10"="#CC1100","Active Members/10"="#308014"))+
    scale_fill_manual(name="Meetup Activty",values=c("Member Joins"="#FF6600","RSVPs"="#0000CD"))
members<-members+opts(title="NYC R Meetup Member Time-Series")+ylab("Count")+
    geom_segment(aes(x=as.Date("2009-09-21"),y=30,xend=as.Date("2009-11-11"),yend=30),arrow=arrow(length=unit(0.1,"cm")))+
    geom_segment(aes(x=as.Date("2009-11-11"),y=30,xend=as.Date("2009-09-21"),yend=30),arrow=arrow(length=unit(0.1,"cm")))+
    annotate("text",x=as.Date("2009-10-15"),y=32,label="Lose home at NYU",size=3.5)+geom_vline(xintercept=as.Date("2009-09-21"))+geom_vline(xintercept=as.Date("2009-11-11"))
print(members)
dev.off()

