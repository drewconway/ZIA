 # File-Name:       chat_roulette_surv.R                 
# Date:            2010-03-30                                
# Author:          Drew Conway                                       
# Purpose:         Survival analysis for seeing things on chatroulette.com
# Data Used:       
# Packages Used:   survival
# Output File:     
# Data Output:     
# Machine:         Drew Conway's MacBook                         
                                                                    
library(survival)
library(Design)

### Genearte our data ###

# Time to seeing a penis
penis<-round(rchisq(30,2))
p_cens<-rep(1,30)
p_type<-rep("penis",30)
p_bind<-cbind(penis,p_cens,p_type)

# Time to seeing a lonely dude
lonely<-round(rchisq(40,1))
l_cens<-rep(1,40)
l_type<-rep("lonely",40)
l_bind<-cbind(lonely,l_cens,l_type)

# Time to seeing a two or more drunk persons
drunk<-sample(1:20,20,replace=T)
d_cens<-rep(1,20)
d_type<-rep("drunk",20)
d_bind<-cbind(drunk,d_cens,d_type)

# Time to seeing one or more women
chick<-sample(70:120,10,replace=T)
c_cens<-rep(1,10)
c_type<-rep("chick",10)
c_bind<-cbind(chick,c_cens,c_type)

surv_data<-as.data.frame(rbind(p_bind,l_bind,d_bind,c_bind))
colnames(surv_data)<-c("time","censor","type")
surv_data$time<-as.numeric(surv_data$time)
surv_data$censor<-as.numeric(surv_data$censor)

png("surv_plot.png",height=1000,width=1000,res=100)
par(mfrow=c(2,2))
survplot(survfit(Surv(time,censor)~type,data=subset(surv_data,type=="lonely")),what="survival",conf="bands",xlab="Minutes")
title("Survival function for seeing a lonely guy")
survplot(survfit(Surv(time,censor)~type,data=subset(surv_data,type=="penis")),what="survival",conf="bands",xlab="Minutes",main="Survival function for seeing a penis")
title("Survival function for seeing a penis")
survplot(survfit(Surv(time,censor)~type,data=subset(surv_data,type=="drunk")),what="survival",conf="bands",xlab="Minutes",main="Survival function for seeing two or more drunk people")
title("Survival function for seeing two or more drunk people")
survplot(survfit(Surv(time,censor)~type,data=subset(surv_data,type=="chick")),what="survival",conf="bands",xlab="Minutes",main="Survival function for seeing a woman")
title("Survival function for seeing a woman")
dev.off()


summary(survfit(Surv(time,censor)~type,data=surv_data))

write.csv(surv_data,"cr_surv.csv")
