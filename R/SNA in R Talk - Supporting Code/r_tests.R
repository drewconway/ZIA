# File-Name:       r_tests.R                 
# Date:            2009-07-23                                
# Author:          Drew Conway                                       
# Purpose:         Test the speed of R's igraph package on CPU taxing network operations
# Data Used:       BA_10000.txt
# Packages Used:   igraph
# Output File:     
# Data Output:     
# Machine:                                
                                                                    
library(igraph)


# G={V:2,500,E:4,996} generated with networkx.generators.barabasi_albert_graph(2500,2)
G<-read.graph('BA_2500.txt',format='edgelist')
# Convert to undirected graph
G<-as.undirected(G)

# Test how long it takes igraph to calucluate betweenness centrality on graph G
betweenness_test<-function(graph) {
    return(betweenness(graph))
}

# Test how long it takes igraph tocalucluate a Fruchterman-Reingold force-directed 
# layout on graph G
layout_test<-function(graph,i=50) {
    return(layout.fruchterman.reingold(graph,niter=i))
}

# Test how long it takes igraph to find the diameter (maximum shortest path)
# of graph G
diameter_test<-function(graph) {
    return(diameter(graph))
}

# Test how long it takes NX to find the maximal cliques of graph G
max_clique_test<-function(graph) {
    return(maximal.cliques(graph))
}

# Test and print results to stdout
print('Betweenness...')
print(system.time(B<-betweenness_test(G)))
print('Fruchterman-Reingold...')
print(system.time(v<-layout_test(G)))
print('Diameter...')
print(system.time(D<-diameter_test(G)))
print('Maximal cliques...')
print(system.time(M<-max_clique_test(G)))
