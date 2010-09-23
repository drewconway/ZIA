#!/usr/bin/env python
# encoding: utf-8
"""
Experiments for growing fractal networks

Created by Drew Conway on 2009-05-19.
Copyright (c) 2009. All rights reserved.
"""

import sys
import os
import networkx as NX
from numpy import random
import time
import xmlrpclib 

def fractal_build(base_graph,iterations,server):
# Simple routine for growing fractal networks. Note, if you are not
# visualizing these network with UbiGraph simply comment out the calls
# to ubigraph and the time.sleep commands (will annoyingly slow down things)
    G=NX.Graph()    # Start with an empty graph
    server.clear()
    for i in range(0,iterations):
        node_index=G.number_of_nodes()  # Keeping track of number of nodes
        # Create a network indexed from the last node in G from the base graph
        T=NX.operators.convert_node_labels_to_integers(base_graph,first_label=node_index)
        N=T.nodes() # Get the nodes from the base graph
        G=NX.operators.compose(G,T) # Add the base graph to G
        ubigraph_add_edges(T.edges(),server)
        time.sleep(0.05)
        # Drew's fractal growth rules...
        if node_index>0:
            if node_index%2>0:
            # If the number of nodes in G is even...
                for n in N:
                    if n%2>0:
                    # Find the even labeled node from the base graph...
                        connect_to=n
                        while n==connect_to:
                            # ...and connect it to a random node from the top half (labels) of all nodes in G
                            connect_to=random.random_integers(node_index/2,node_index)
                        G.add_edge(n,connect_to)
                        time.sleep(0.05)
                        ubigraph_add_edges([(n,connect_to)],server)
            else:
            # If the number of nodes in G is odd...
                for n in N:
                    if n%2<1:
                    # Find the odd labeled node from the base graph...
                        connect_to=n
                        while n==connect_to:
                            # ... and connect it to a random node from the bottom half (labels) of all nodes in G
                            connect_to=random.random_integers(0,node_index/2)
                        G.add_edge(n,connect_to)
                        time.sleep(0.05)
                        ubigraph_add_edges([(n,connect_to)],server)
    return G
        

def open_ubigraph_server(url='http://127.0.0.1:20738/RPC2'):
# Open connection to UbiGraph XML-RPC server
    server_url = url
    server = xmlrpclib.Server(server_url)
    return server.ubigraph

def main():
    ubi_server=open_ubigraph_server()
    #base=NX.Graph(data=[(0,1)])                # Dyad
    #base=NX.Graph(data=[(0,1),(1,2),(1,3)])    # Disconnected triple
    #base=NX.Graph(data=[(0,1),(1,2),(2,0)])    # Triangle
    #base=NX.Graph(data=[(0,1),(1,2),(1,3)])    # Three point star
    base=NX.generators.petersen_graph()        # Petersen Graph
    #base=NX.generators.heawood_graph()         # Heawood Graph
    #base=NX.Graph(data=[(0,1),(2,3),(3,4),(4,2)])   # Dyad and triangle
    #base=NX.Graph(data=[(0,1),(2,3),(3,4),(3,5)])  # Dyad and three point star
    G=fractal_build(base,100,ubi_server)
    #G=NX.barabasi_albert_graph(300,2)
    #H=NX.UbiGraph(G)
    #print(compact_box_burning(G))
    time.sleep(15)
    ubi_server.clear()

if __name__ == '__main__':
	main()

