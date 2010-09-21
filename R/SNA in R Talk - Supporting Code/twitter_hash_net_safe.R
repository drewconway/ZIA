# File-Name:       twitter_hash_net.R                 
# Date:            2009-11-10                                
# Author:          Drew Conway                                       
# Purpose:         Generate network data from a users tweeting a specific hash-tag on Twitter
# Data Used:       
# Packages Used:   igraph,twitteR,ggplot2
# Output File:     several
# Data Output:     several
# Machine:         Drew Conway's MacBook                         
                                                                    
#### Example 3: Generating network data from Twitter and analysis       ####
#### WARNING: Make sure that the hash-tag you use is all lower-case.    ####
#### It appears there is a big in the twitteR package                   ####

library(twitteR)
library(igraph)
library(ggplot2)


# Initialize a session to gather data
user<-'your_username'
pass<-'your_password'
twit<-initSession(user,pass)

# Function for generating edgelists
create.adj<-function(seed) {
    u<-getUser(seed)
    # Cannot create network data from protected accts
    if(protected(u)==FALSE) {
        friends<-userFriends(seed)
        friend.vec<-sapply(friends,function(f) {screenName(f)})
        if(length(friend.vec)<1) {
            return(list(adj.list=NA,seed.friends=NA))
        }
        else {
            return(list(adj.list=cbind(seed,friend.vec),seed.friends=friend.vec))
        }
    }
    else {
        return(list(adj.list=NA,seed.friends=NA))
    }
}


# Get the last 100 tweets containing the given hashtag
get.hashtag<-function(hashtag,session=getCurlHandle()) {
    search.url<-paste("http://search.twitter.com/search.json?q=%23",hashtag,"&rpp=100",sep="")
    out <- getURL(search.url, curl = session)
    jsonList <- twFromJSON(out)[[1]]
    return(sapply(jsonList, buildStatus))
}

# Get the users from a list of tweets
users.from.statuses<-function(status.list) {
    users<-c()
    for(i in 1:length(status.list)) {
        users<-append(users,(screenName(status.list[[i]])))
    }
    return(unique(users))
}

# Get all the users from the last 100 tweets containign some hashtag
hashtag<-"rstats"
dir.create(hashtag)

hash.tweets<-get.hashtag(hashtag)
hash.users<-users.from.statuses(hash.tweets)

# We now build the network, but we have to make sure the initial
# seed is not protected
seed.user<-1
while(protected(getUser(hash.users[seed.user]))) {seed.user<-seed.user+1}

# Now create the edgelists for all uses 
for(u in seed.user:length(hash.users)) {
    if(u==seed.user) {
        hash.list<-create.adj(hash.users[u])
        hash.el<-hash.list$adj.list
    }
    else {
        current.list<-create.adj(hash.users[u])
        current.el<-current.list$adj.list
        if(is.na(current.el)==FALSE) {
            hash.el<-rbind(hash.el,current.el)
        }
    }
    cat(paste("Processed user:", hash.users[u],"\n"))
}

# Create an igraph graph object from edgelist
hash.graph<-graph.edgelist(hash.el)


# First save raw network data
write.graph(hash.graph,paste(hashtag,"/",hashtag,".net",sep=""),format="pajek")
# hash.graph<-read.graph(paste(hashtag,"/",hashtag,".net",sep=""),format="pajek")


# Do some cleaning and record keeping of the network
V(hash.graph)$size<-5           # Vertex size 5
E(hash.graph)$arrow.size<-0     # Remove arrows from edges
hash.names<-V(hash.graph)$name  # Get vertex labels

# Create a 2-core, as this network will have several pendants
# that we will want to ignore
# hash.mc<-decompose.graph(hash.graph,mode="weak",max.comps=1)[[1]]    # Extract main component
hash.cores<-graph.coreness(hash.graph)
hash.2core<-subgraph(hash.graph,as.vector(which(hash.cores>1))-1)
names.2core<-V(hash.2core)$name

# Create a vector for labeling graph with only names of 
# people using the hash tag
names<-as.vector(V(hash.2core)$name)
users<-as.vector(hash.users)
name.matches<-match(users,names)
name.matches<-name.matches[!is.na(name.matches)]
name.labels<-rep(NA,length(names))
colors<-rep("grey",length(names))
for(i in 1:length(name.matches)) {
    name.labels[name.matches[i]]<-names[name.matches[i]]
    colors[name.matches[i]]<-"darkblue"
}

# Draw whole graph
whole.layout<-layout.fruchterman.reingold(hash.graph)
png(paste(hashtag,"/","00_",hashtag,".png",sep=""),height=2500,width=2500,res=100,pointsize=14)
plot(hash.2core,layout=whole.layout,vertex.color="lightblue",vertex.label=NA)
dev.off()

# Draw two core graph
hash.layout<-layout.fruchterman.reingold(hash.2core)
png(paste(hashtag,"/","01_",hashtag,".png",sep=""),height=1500,width=1500,res=100,pointsize=14)
plot(hash.2core,layout=hash.layout,vertex.label=name.labels,vertex.label.color="black",vertex.color=colors,vertex.label.dist=0.22)
dev.off()

## Let's do some analysis! ##

# 1) Find the most distant pair in the data

# Get all shortest paths for users, and find max shortest paths
paths<-get.all.shortest.paths(hash.2core,name.matches)
max.paths<-unique(tail(paths))
distant.users<-unique(unlist(max.paths))

# Take subgraph with actors in max shortest paths
distant.graph<-subgraph(hash.2core,distant.users)

# Plot max path grapth
E(distant.graph)$width<-2
V(distant.graph)$size<-6
distant.color<-match(V(distant.graph)$name,users)
distant.color[!is.na(distant.color)]<-"green"   # Users with hash-tag green
distant.color[is.na(distant.color)]<-"red"      # Without are red
V(distant.graph)$color<-distant.color
distant.layout<-layout.kamada.kawai(distant.graph)
png(paste(hashtag,"/","02_",hashtag,"_distant.png",sep=""),height=1500,width=1500,res=100,pointsize=20)
plot(distant.graph,layout=distant.layout,vertex.label=V(distant.graph)$name,vertex.label.color="black",vertex.label.dist=0.28)
dev.off()

# 2) Key actor analysis using betweeness and eigenvector centrality,
# as in the example from above

hash.cent<-data.frame(bet=betweenness(hash.graph),eig=evcent(hash.graph)$vector)

# We will use the residuals in the next step as part
# of the visualization
hash.res<-as.vector(lm(eig~bet,data=hash.cent)$residuals)
hash.cent<-transform(hash.cent,res=hash.res,name=V(hash.graph)$name)

# Save centrality data for future analysis
write.csv(hash.cent,paste(hashtag,"/",hashtag,"_centrality.csv",sep="")) 

p<-ggplot(hash.cent,aes(x=bet,y=eig,label=V(hash.graph)$name,colour=res,
    size=abs(res)))+xlab("Betweenness Centrality")+ylab("Eigenvector
    Centrality")
pdf(paste(hashtag,"/","03_",hashtag,"_key_actor.pdf",sep="",height=200,width=500))
p+geom_text()+opts(title=paste("Key Actor Analysis for #",hashtag,sep=""))
dev.off()

# 3) Block modeling on community structure of leading eigenvector

# First create a dendrogram to illustrate hierarchical structure
lec<-leading.eigenvector.community(as.undirected(hash.2core))
dend<-as.dendrogram(lec)
png(paste(hashtag,"/","04_",hashtag,"_dendrogram.png",sep=""),height=1500,width=1500,res=100,pointsize=20)
plot(dend)
dev.off()

# Now create block model of community structure from leading eigenvector

# Create a list of block membership, and internal tie density
M<-lec$membership
block.id<-unique(M)
blocks<-list()
blocks.subgraphs<-list()
density.internal<-list()
for(i in block.id) {
    b<-as.vector(which(M==i)-1)
    blocks[[i+1]]<-b
    subgraph.b<-subgraph(hash.graph,b)
    blocks.subgraphs[[i+1]]<-subgraph.b
    if(is.nan(graph.density(subgraph.b))) { density.internal[[i+1]]<-0 } else { density.internal[[i+1]]<-graph.density(subgraph.b)*10 }
}

# Create weighted incidence matrix 
block.matrix<-matrix(nrow=length(block.id),ncol=length(block.id))
# Define inter-block edges and weights
for(i in block.id) {
    for(j in block.id) {
        if(i!=j) {
            ego.edges<-length(E(blocks.subgraphs[[i+1]]))
            alter.edges<-length(E(blocks.subgraphs[[j+1]]))
            internal.edges<-ego.edges+alter.edges
            union.edges<-length(E(subgraph(hash.graph,c(blocks[[i+1]],blocks[[j+1]]))))
            block.matrix[i+1,j+1]<-union.edges-internal.edges
        } else {
            block.matrix[i+1,j+1]<-0
        }
    }
}

# Create block model from matrix
block.model<-graph.adjacency(block.matrix,weighted=TRUE)
write.graph(block.model,paste(hashtag,"/",hashtag,"_block_model",".net",sep=""),format="pajek")

# Plot block model

# Make edge thickness correspond to weight, based on
# strength of tie between blocks
for(i in 1:length(block.id)) {
    for(j in neighbors(block.model,i-1)) {
        E(block.model, path=c(i-1,j))$width<-block.matrix[i,j+1]
    }
}
E(block.model)$arrow.size<-0    # Turn off arrows

# Plot block model
block.layout<-layout.fruchterman.reingold(block.model,iterations=100)
# There are many ways to examine a block model, one is to size blocks by internal density
block.density<-unlist(density.internal)*20
# Another is to simply size them by the number of actors, we will use both, and a fixed size
block.size<-c()
for(i in 1:length(blocks)){  block.size<-append(block.size,length(blocks[[i]]))}
png(paste(hashtag,"/","05_",hashtag,"_block_model.png",sep=""),height=1500,width=1500,res=100,pointsize=20)
plot(block.model,layout=block.layout,vertex.size=10)
dev.off()
png(paste(hashtag,"/","06_",hashtag,"_block_model_size.png",sep=""),height=1500,width=1500,res=100,pointsize=20)
plot(block.model,layout=block.layout,vertex.size=block.size)
dev.off()
png(paste(hashtag,"/","07_",hashtag,"_block_model_density.png",sep=""),height=1500,width=1500,res=100,pointsize=20)
plot(block.model,layout=block.layout,vertex.size=block.density)
dev.off()

# Final step, display a subgraph of block with maximum internal structure (possible tighest community)
max.block<-which(block.density==max(block.density))[1]
key.block<-subgraph(hash.2core,blocks[[max.block]])

# Create a vector for labeling graph as before
block.names<-as.vector(V(key.block)$name)
block.matches<-match(users,block.names)
block.matches<-block.matches[!is.na(block.matches)]
block.labels<-rep(NA,length(block.names))
block.colors<-rep("#000066",length(block.names))
for(i in 1:length(block.matches)) {
    block.labels[block.matches[i]]<-block.names[block.matches[i]]
    block.colors[block.matches[i]]<-"#FF0033"
}

# Plot subgraph
key.layout<-layout.fruchterman.reingold(key.block)
E(key.block)$arrow.size<-0
V(key.block)$size<-10
V(key.block)$color<-block.colors
png(paste(hashtag,"/","08_",hashtag,"_key_block.png",sep=""),height=1500,width=1500,res=100,pointsize=20)
plot(key.block,layout=key.layout,vertex.label=block.labels,vertex.label.color="black",vertex.label.dist=0.28)
dev.off()

### NEW ANALYSIS USING infochimps API DATA ###

ic.apikey<-"your_key"

# Returns a list of Infocimps.org trstrank metric for
# some twitter screen name
get.trstrank<-function(screen.name) {
    tr.url<-paste("http://api.infochimps.com/soc/net/tw/trstrank.json?screen_name=",screen.name,"&apikey=",ic.apikey,sep="")
    tr.get<-getURL(tr.url)
    tr.list<-twFromJSON(tr.get)
    ifelse(is.null(tr.list$error),return(tr.list),return(NA))
}

# Returns a list of Infocimps.org Twitter User 
# Influence Metrics some twitter screen name
get.influence<-function(screen.name) {
    inf.url<-paste("http://api.infochimps.com/soc/net/tw/influence.json?screen_name=",screen.name,"&apikey=",ic.apikey,sep="")
    inf.get<-getURL(inf.url)
    inf.list<-twFromJSON(inf.get)
    ifelse(is.null(inf.list$error),return(inf.list),return(NA))
}

# Get trstrank and influence metrics for everyone in network
nodes.trstrank<-lapply(names.2core,get.trstrank)
nodes.influence<-lapply(names.2core,get.influence)

# Create data frames, then merge into one
trstrank.df<-as.data.frame(do.call(rbind,nodes.trstrank))
trstrank.df<-subset(trstrank.df,is.na(trstrank.df$screen_name)==FALSE)
influence.df<-as.data.frame(do.call(rbind,nodes.influence))
influence.df<-subset(influence.df,is.na(influence.df$screen_name)==FALSE)
infochimps<-merge(influence.df,trstrank.df,by=c("id","screen_name"))
infochimps<-colwise(unlist)(infochimps)

# Add column for whether a user tweetest hash-tag
tweeted<-rep(0,nrow(infochimps))
tweet.match<-match(hash.users,infochimps$screen_name)
tweet.match<-tweet.match[which(is.na(tweet.match)==FALSE)]
tweeted[tweet.match]<-1

# Write data as CSV
infochimps<-transform(infochimps,follower_rank=log(followers_count/friends_count),tweet.hash=tweeted)
infochimps<-subset(infochimps,follower_rank!=Inf)
write.csv(infochimps,paste(hashtag,"/",hashtag,"_infochimps.csv",sep=""))
infochimps<-read.csv(paste(hashtag,"/",hashtag,"_infochimps.csv",sep=""))

# PLOT 1: All data points
png(paste(hashtag,"/",hashtag,"_full_infochimps_metric.png",sep=""),height=1000,width=1000,res=100)
ic.plot<-ggplot(infochimps,aes(x=follower_rank,y=trstrank))+geom_text(aes(label=screen_name,color=as.factor(tweet.hash)))
ic.plot<-ic.plot+xlab(expression(log(frac(Followers,Friends))))+ylab("Infochimps.org trstrank")+
    opts(title=paste("Key Actor Analysis for #",hashtag," with Infochimps.org Data (full network)",sep=""))+
    xlim(min(infochimps$follower_rank)-min(infochimps$follower_rank)*.15,max(infochimps$follower_rank)+max(infochimps$follower_rank)*.15)+
    ylim(min(infochimps$trstrank)-min(infochimps$trstrank)*.15,max(infochimps$trstrank)+max(infochimps$trstrank)*.15)
ic.plot<-ic.plot+scale_colour_manual(values=c("darkgrey","red"),breaks=c("0","1"),labels=c("No","Yes"),name=paste("Tweeted #",hashtag,sep=""))
print(ic.plot)
dev.off()

# PLOT 2: Only those where tweeted==1
infochimps.sub<-subset(infochimps,tweet.hash==1)
png(paste(hashtag,"/",hashtag,"_only_infochimps_metric_.png",sep=""),height=1000,width=1000,res=100)
ic.plot<-ggplot(infochimps.sub,aes(x=follower_rank,y=trstrank))+geom_text(aes(label=screen_name,colour=factor(tweet.hash)))
ic.plot<-ic.plot+xlab(expression(log(frac(Followers,Friends))))+ylab("Infochimps.org trstrank")+
    opts(title=paste("Key Actor Analysis for #",hashtag," with Infochimps.org Data",sep=""))+
    xlim(min(infochimps.sub$follower_rank)-min(infochimps.sub$follower_rank)*.15,max(infochimps.sub$follower_rank)+max(infochimps.sub$follower_rank)*.15)+
    ylim(min(infochimps.sub$trstrank)-min(infochimps.sub$trstrank)*.15,max(infochimps.sub$trstrank)+max(infochimps.sub$trstrank)*.15)
ic.plot<-ic.plot+scale_colour_manual(values=c("red"),legend=FALSE)
print(ic.plot)
dev.off()