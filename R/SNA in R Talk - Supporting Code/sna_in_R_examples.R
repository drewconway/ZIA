# File-Name:       sna_in_R_examples.R                 
# Date:            2009-11-10                                
# Author:          Drew Conway                                       
# Purpose:         Supporting code for November 10th Bay Area R Meetup talk
# Data Used:       drug_main.txt
# Packages Used:   igraph,ggplot2,twitteR                 

# igraph is used as the network analysis package
# though there are several other options in R                                                                    
library(igraph)

#### Example 1: Basic SNA - Finding Key Actors ####

# Load in network data of drug user in Hartford, CT
G<-read.graph("drug_main.txt",format="edgelist")
G<-as.undirected(G) # Force ties to be reciprocal

# Create a new dataframe with centrality metrics
cent<-data.frame(bet=betweenness(G),eig=evcent(G)$vector)
# evcent returns lots of data associated with the EC, 
# but we only need the leading eigenvector

# We will use the residuals in the next step as part
# of the visualization
res<-as.vector(lm(eig~bet,data=cent)$residuals)
cent<-transform(cent,res=res)

library(ggplot2)
# We use ggplot2 to make things a it prettier
p<-ggplot(cent,aes(x=bet,y=eig,label=rownames(cent),colour=res,
    size=abs(res)))+xlab("Betweenness Centrality")+ylab("Eigenvector
    Centrality")
# We use the residuals to color and shape the points of our plot,
# making it easier to spot outliers.
pdf('key_actor_analysis.pdf')
p+geom_text()+opts(title="Key Actor Analysis for Hartford Drug Users")
# We use the geom_text function to plot the actors' ID's rather than points
# so we know who is who
dev.off()


#### Example 2: Visualizing the Network ####

# 2.1 First, view the whole network in igraph's Tcl/Tk interface
tkplot(G,layout=layout.fruchterman.reingold)

# 2.2 Highlight key actors and save plot as PDF
# Create position for all of the nodes
l<-layout.fruchterman.reingold(G,niter=500)
# Set the nodes' size relative to their residual value
V(G)$size<-abs(res)*10
# Only display the labels of key playes
nodes<-as.vector(V(G)+1)
nodes[which(abs(res)<.25)]<-NA # Key players defined as have a res>.25
# Save plot as a PDF
pdf('actor_plot.pdf',pointsize=7)
plot(G,layout=l,vertex.label=nodes,vertex.label.dist=0.25,vertex.label.color='red',edge.width=1)
dev.off()

# 2.3 Highlight the diameter of graph G
d<-get.diameter(G)
V(G)$size<-4 # Reset G's node size for new graph
E(G)$width<-1
E(G)$color<-'dark grey'
E(G, path=d)$width<-3 # Set diameter path width to 3
E(G, path=d)$color<-'red' # and change color to red
# Save plot as PDF
pdf('diameter_plot.pdf')
plot(G,layout=l,vertex.label=NA,vertex.label.dist=0.25,vertex.label.color='red')
dev.off()

# 2.4 extract the 2-core using k-core analysis
# Find each actor's coreness
cores<-graph.coreness(G)
# Extract 2-core, which elimiantes pendants and pendant chains
E(G)$width<-1
E(G)$color<-'blue'
G2<-subgraph(G,as.vector(which(cores>1))-1)
l2<-layout.fruchterman.reingold(G2,niter=500)
# Save plot as a PDF
pdf('2core.pdf')
plot(G2,layout=l2,vertex.label=NA,vertex.label.color='red')
dev.off()

#### Example 3: Generating network data from Twitter ####

# We will the twitteR package to generate relations and find
# new friends.  The example is based on the parallel Python
# version posted here: http://www.drewconway.com/zia/?p=345
library(twitteR)

# Initialize a session to gather data
user<-'your_user'
pass<-'your_pass'
twit<-initSession(user,pass)

## Create several helper functions ##

# Function for converting twitteR object data to vector
friend.vector<-function(friends) {
    v<-c()
    for(i in 1:length(friends)) {v<-append(v,as.character(screenName(friends[[i]])))}
    return(v)
}

# Function for generating edgelists
create.adj<-function(seed) {
    u<-getUser(seed)
    # Cannot create network data from protected accts
    if(protected(u)==FALSE) {
        outdegree<-userFriends(u,twit)
        friends<-friend.vector(outdegree)
        return(list(adj.list=cbind(seed,friends),seed.friends=friends))
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

# Get all the users from the last 100 tweets containign some hashtage
hashtag<-'your_hashtag'
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
        if(is.na(current.el)) {
            print(paste(hash.users[u]), "has a protected account--ignoring")
        }
        else {
            hash.el<-rbind(hash.el,current.el)
        }
    }
}

# Create an igraph graph object from edgelist
hash.graph<-graph.edgelist(hash.el)

# First save raw network data
write.graph(hash.graph,paste(hashtag,".net",sep=""),format="pajek")

# Do some cleaning and record keeping of the network
V(hash.graph)$size<-5           # Vertex size 5
E(hash.graph)$arrow.size<-0     # Remove arrows from edges
hash.names<-V(hash.graph)$name  # Get vertex labels

# Create a 2-core, as this network will have several pendants
# that we will want to ignore
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
colors<-rep("#000066",length(names))
for(i in 1:length(name.matches)) {
    name.labels[name.matches[i]]<-names[name.matches[i]]
    colors[name.matches[i]]<-"#FF0033"
}

# Draw graph
hash.layout<-layout.fruchterman.reingold(hash.2core)
png(paste("01_",hashtag,".png",sep=""),height=1500,width=1500,res=100,pointsize=14)
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
png(paste("02_",hashtag,"_distant.png",sep=""),height=1500,width=1500,res=100,pointsize=20)
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
write.csv(hash.cent,"rstats_centrality.csv") 

p<-ggplot(hash.cent,aes(x=bet,y=eig,label=V(hash.graph)$name,colour=res,
    size=abs(res)))+xlab("Betweenness Centrality")+ylab("Eigenvector
    Centrality")
pdf(paste("03_",hashtag,"_key_actor.pdf",sep=""))
p+geom_text()+opts(title="Key Actor Analysis for Hahs Tag")
dev.off()

# 3) Block modeling on community structure of leading eigenvector

# First create a dendrogram to illustrate hierarchical structure
lec<-leading.eigenvector.community(as.undirected(hash.2core))
dend<-as.dendrogram(lec)
png(paste("04_",hashtag,"_dendrogram.png",sep=""),height=1500,width=1500,res=100,pointsize=20)
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
write.graph(block.model,paste(hashtag,"_block_model",".net",sep=""),format="pajek")

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
png(paste("05_",hashtag,"_block_model.png",sep=""),height=1500,width=1500,res=100,pointsize=20)
plot(block.model,layout=block.layout,vertex.size=10)
dev.off()
png(paste("06_",hashtag,"_block_model_size.png",sep=""),height=1500,width=1500,res=100,pointsize=20)
plot(block.model,layout=block.layout,vertex.size=block.size)
dev.off()
png(paste("07_",hashtag,"_block_model_density.png",sep=""),height=1500,width=1500,res=100,pointsize=20)
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
png(paste("08_",hashtag,"_key_block.png",sep=""),height=1500,width=1500,res=100,pointsize=20)
plot(key.block,layout=key.layout,vertex.label=block.labels,vertex.label.color="black",vertex.label.dist=0.28)
dev.off()
