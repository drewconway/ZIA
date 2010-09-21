#!/usr/bin/env python
# encoding: utf-8
"""
python_test.py

A series of four test to examine the speed of NetworkX to 
accomplish CPU taxing network operations.

Created by Drew Conway on 2009-07-22.
Copyright (c) 2009. All rights reserved.
"""

import sys
import os
import networkx
import time

def betweenness_test(G):
# Test how long it takes NX to calculate betweenness centrality on graph G
    start=time.clock()
    B=networkx.brandes_betweenness_centrality(G,normalized=False)
    return time.clock()-start
    
def layout_test(G,i=50):
# Test how long it takes NX to calculate a Fruchterman-Reingold force-directed 
# layout on graph G
    start=time.clock()
    v=networkx.layout.spring_layout(G,iterations=i)
    return time.clock()-start
    
def diameter_test(G):
# Test how long it takes NX to find the diameter (maximum shortest path)
# of graph G
    start=time.clock()
    D=networkx.distance.diameter(G)
    return time.clock()-start
    
def max_clique_test(G):
# Test how long it takes NX to find the maximal cliques of graph G
    start=time.clock()
    C=networkx.clique.find_cliques(G)
    return time.clock()-start
    
def main():
    # G={V:2,500,E:4,996} generated with networkx.generators.barabasi_albert_graph(2500,2)
    # Read in as undirected graph type
    G=networkx.read_edgelist('BA_2500.txt',create_using=networkx.Graph())
    networkx.info(G)
    print ''
    
    # Begin the testing...
    tests={}
    print 'Testing betweenness...'
    tests['betweeness']=betweenness_test(G)
    print 'Testing Fruchterman-Reingold...'
    tests['layout']=layout_test(G)
    print 'Testing diameter...'
    tests['diameter']=diameter_test(G)
    print 'Testing maximal cliques...'
    tests['max_clique']=max_clique_test(G)
    
    # Output the time resulst to stdout
    for i in tests.keys():
        print i+": "+str(tests[i])
    


if __name__ == '__main__':
    main()

