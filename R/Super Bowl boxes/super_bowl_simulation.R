# File-Name:       super_bowl_simulation.R           
# Date:            2013-01-05                                
# Author:          Will Townes
# Email:           will.townes@gmail.com                                      
# Purpose:         Simulating the expected profits as a function of number of squares chosen in a super bowl digits matrix based on historic Super Bowl score data.
# Data Used:       Wikipedia Super Bowl data
# Packages Used:   super_bowl.R
# Output File:    

# Copyright (c) 2013, under the Simplified BSD License.  
# For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
# All rights reserved. 

###Read in quarterly probabilities from local CSV files, if they exist. Otherwise call super_bowl.R to download the data from wikipedia and write the CSV files.
fnames<-c("q1.probs.csv","q2.probs.csv","q3.probs.csv","q4.probs.csv")
if(all(file.exists(fnames))){
  for(fname in fnames){
    vname<-strtrim(fname,8)
    assign(vname,read.csv(fname))
  }
}else{
  print('files not found')
  source('super_bowl.R')
}
#we don't care at this point about the identities of the squares (only care about the chance of winning as a function of the number of squares randomly chosen), so we can flatten quarterly probabilities into vectors and stack in data frame
probs<-as.data.frame(lapply(list(q1.probs,q2.probs,q3.probs,q4.probs),function(q){as.numeric(c(q,recursive=T))}))
colnames(probs)<-c('q1','q2','q3','q4')
cdfs<-cumsum(probs)
rq<-function(n,cdf){
  #pseudo random variate based on the quarterly probability of "winning" as defined by the empirical "cdf" vector. Returns a vector of length n. Each item in the vector is an index of a single square in the super bowl card
  cdf<-sort(cdf) #cdf must be sorted in ascending order
  u<-runif(n) #get uniform variates
  res<-sapply(u,function(val){min(which(cdf>val))})
  #res is a vector of length n. Each element is the value of the cdf whose probability is closest to the uniform variate but still greater than it (this is basically an inverse transformation from the uniform distribution into the empirical discrete probability distribution)
  return(res)
}
rchoice<-function(){
  #generates a list of samples of size 1,2,3,...100 chosen from the integers 1:100. Simulates choosing a certain number of squares from the board on a single super bowl.
  res<-list()
  rng<-1:100
  for(j in rng){
    res[[j]]<-sample(rng,j)
  }
  return(res)
}
getwinnings<-function(qwinners,choices,rewards){
  #qwinners is a 4-vector of quarterly scores, choices is a 100-list of square choices, and rewards is a 4-vector assigning the revenue value of winning a particular quarter. Returns a 100-vector with the amount of revenue gained by each group of "k" square choices
  winnings<-rep(0,100)
  for(i in 1:4){
    winners<-which(sapply(choices,function(squares){qwinners[i] %in% squares}))
    winnings[winners]<-winnings[winners]+rewards[i]
  }
  return(winnings)  
}
run.sim<-function(nsims,squarecost=10,rewards=c(20,20,20,40)){
  #runs the specified number of super bowl simulations and returns the expected (average for a single game) profits for each choice of square count
  winners<-apply(cdfs,2,FUN=function(cdf){rq(nsims,cdf)}) #simulate a bunch of games and see the predicted scores at the end of each quarter of each game. A data frame of same dimension as cdfs
  rewards<-squarecost*rewards
  profit<-rep(0,100)
  costs<-seq(1,100)*squarecost
  for(sim in 1:nsims){
    choices<-rchoice()
    profit<-profit-costs+getwinnings(winners[sim,],choices,rewards)
  }  
  return(profit/nsims)
}
nsims<-c(10,100,1000,10000)
results<-matrix(nrow=100,ncol=length(nsims),dimnames=list(as.character(1:100),as.character(nsims)))
colnames(results)<-as.character(nsims)
for(i in 1:length(nsims)){
  results[,i]<-run.sim(nsims[i])
}
#plot of expected profits for the 10,000 simulations experiment shows high variability:
barplot(results[,length(nsims)],xlab='Number of Squares Chosen',ylab='Average Profit',main="Unpredictable variation in Profits")
scatter.smooth(1:100,results[,length(nsims)],xlab="Number of Squares Purchased",ylab="Average Profit",main="Unpredictable variation in Profits")

#but note that as the number of experiments run increases, the range of variation between maximum and minimum profits tends toward zero:

plot(log10(nsims),apply(results,2,max),type='b',ylim=c(min(results),max(results)),ylab="Maximum and Minimum Average Profits",xlab="Number of experiments run, log scale",main="Expected Profits squeezed to zero")
lines(log10(nsims),apply(results,2,min),type='b')
abline(0,0)
