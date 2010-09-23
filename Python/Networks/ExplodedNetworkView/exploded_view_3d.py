#!/usr/bin/env python
# encoding: utf-8
"""
exploded_view_3d.py

The purpose of this script is to create an 'exploded view'
of a network in 3D using heierarchical clustering of geodesic 
distances in NetworkX and UbiGraph.

This script is intended as an illustratie proof of concept
for the exploded view visualization.

Created by Drew Conway on 2009-04-24.
Copyright (c) 2009. All rights reserved.
"""

import sys
import os
import time
# Three NumPy functions needed for data manipulation
from numpy import array,unique1d,zeros
import networkx as NX   # Building and manipulating network data
import Pycluster as PC  # Calculating heierarchical clustering
import pylab as P       # Display chart of E-I ratio
import xmlrpclib        # Open connection to UbiGraph server


def exploded_view(G,ubi_server,edge_ref,partition,repulsion=0.3):
# Creates exploded view of network based on a given partition
    # Need to find the edges that exist outside of the partition groupings.
    # Will create subgraphs of each grouping to find these edges
    all_edges=G.edges()
    internal_edges=[]
    groupings=get_partition_groupings(partition)
    # Create an edgelist of all edges contained INSIDE partition groupings
    for g in groupings.keys():
        sub_graph=NX.subgraph(G,groupings[g])
        for e in sub_graph.edges():
            internal_edges.append(e)
    # Find edges remaining OUTSIDE partition groupings
    external_edges=[]
    for i in all_edges:
        if internal_edges.count(i)<1:
            external_edges.append(i)
    # Explode external edges in UbiGraph
    explode(ubi_server,edge_ref,external_edges,repulsion)
    return edge_ref,external_edges
    
def rebuild(ubi_server,ubi_edges,edgelist,repulsion=1.0):
# Resets view to normal view
    normal_view=ubi_server.new_edge_style(0)
    ubi_server.set_edge_style_attribute(normal_view,"visible","true")
    ubi_server.set_edge_style_attribute(normal_view,"strength",str(repulsion))
    for e in edgelist:
        ubi_server.change_edge_style(ubi_edges[e],normal_view)
        

def explode(ubi_server,ubi_edges,edgelist,repulsion=0.3):
# Use UbiGraph edge attribute to hide and repel external edges
    exploded_view=ubi_server.new_edge_style(0)
    ubi_server.set_edge_style_attribute(exploded_view,"visible","false")
    ubi_server.set_edge_style_attribute(exploded_view,"strength",str(repulsion))
    for e in edgelist:
        ubi_server.change_edge_style(ubi_edges[e],exploded_view)
        time.sleep(0.05)
    

def build_ubigraph(G,ubi_server):
# Note: Not using the built in NX.UbiGraph class for two reasons.
# 1) This shows more of what is occurring under the hood with the code
# 2) Having explict access to the XML-RPC server makes creating the 
# exploded view more transparent
    ubi_server.clear()
    edges={}    # Dictionary to record UbiGraph edge ids
    # Add nodes
    for n in G.nodes():
        ubi_server.new_vertex_w_id(n)
    # Add edges
    for e in G.edges():
        e_id=ubi_server.new_edge(e[0],e[1])
        edges[e]=e_id
    return edges

def open_ubigraph_server(url='http://127.0.0.1:20738/RPC2'):
# Open connection to UbiGraph XML-RPC server
    server_url = url
    server = xmlrpclib.Server(server_url)
    return server.ubigraph
    
def get_partition_groupings(partition):
# Returns dictionary of nodelist for each grouping
    groupings={}    # dictionary of groupings for each partition
    num_clusters=unique1d(partition) # number of clusers in partition
    # Create a dictonary of nodelists for each group in partition p
    for n in num_clusters:
        group=[]
        for i in range(0,len(partition)):
            if partition[i]==n:    # If node i is in group n
                group.append(i)         # Add i to n's nodelist
        groupings[n]=group
    return groupings

def external_internal_ties(G,partitions):
# Calculate the external/internal tie ratio for each partition
# This will help identiy interesting clusters
    total_edges=G.number_of_edges()
    E={}    # will store internal ties for each partition
    I={}    # external ties
    R={}    # E-I/total edges
    for p in partitions.keys():
        groupings=get_partition_groupings(partitions[p])
        # Generate subgraphs of each nodelist grouping for partition p and calculate 
        # the number of external and internal ties per paritioning
        internal=0.    # will track the total internal ties
        for g in groupings.keys():
            sub_graph=NX.subgraph(G,groupings[g])
            internal+=sub_graph.number_of_edges()
        I[p]=internal
        E[p]=total_edges-internal
        R[p]=(E[p]-I[p])/total_edges
    return E,I,R
    
def dict_of_dicts_to_matrx(dict_of_dicts):
# Return a NxN array from a dict-of-dicts
    index=dict_of_dicts.keys()
    i_0=min(index)
    i_k=max(index)
    M=zeros((i_k,i_k))
    for i in range(i_0,i_k):
        vals=dict_of_dicts[i]
        for j in range(i_0,i_k):
            M[i,j]=vals[j]
    return array(M)
            
def get_dist_matrix(G):
# Returns a symmetric NxN array of geodesic distances
    geo_dist=NX.path.all_pairs_shortest_path_length(G)
    return dict_of_dicts_to_matrx(geo_dist)

def generate_network_clusters(G):
# Function creates the cluster partitions using heierarchical clustering
# on geodesic distances
    # First check to make sure the given network is a single fully
    # connected component.
    if len(NX.component.connected_component_subgraphs(G)) >1:
        raise NX.NetworkXError, 'G must be single component! Extract main component...'
    # Now generte clusters
    dist_matrix=get_dist_matrix(G)
    # Default Heierarchical Clustering algo used
    hclus=PC.treecluster(data=None,distancematrix=dist_matrix,method='m')
    partitions={}   # create dictionary of partitioning at each cut in heierarchy
    for c in range(1,len(hclus)+1):  # treecluster cuts start at 1
        partitions[c]=hclus.cut(c).tolist()
    return partitions


def main():
    # First half of the script calculates the partitions, and the metric used
    # to identify good candidate partitions for using in the exploded view; 
    # the ratio of extern tie-internal ties/total network edges
    
    # G=NX.generators.barabasi_albert_graph(550,2)
    G=NX.read_edgelist('test_network.edgelist',create_using=NX.Graph())
    G=NX.convert_node_labels_to_integers(G,first_label=0) # for consistent record keeping
    partitions=generate_network_clusters(G)
    external,internal,ei_ratio=external_internal_ties(G,partitions)
    # Plot E-I ratio and save
    P.plot(ei_ratio.values(),ls='-',marker='.',color='r')
    P.savefig('ei_plot.png')
    #P.show()
    #P.savefig('ei_plot.png',dpi=100)
    # Looking for large jumps in graph, thoes will be candidate partitions
    time.sleep(10)
    # Once the candidate partitions have been identified, we use UbiGraph to 
    # display exploded view
    S=open_ubigraph_server()    # Open connection to XML-RPC UbiGraph Server
    edges=build_ubigraph(G,S)         # Build network in UbiGraph
    time.sleep(20)
    edge_ref,external_edges=exploded_view(G,S,edges,partitions[20],repulsion=0.20738) # Choose partition and display 'exploded view'
    time.sleep(20)
    rebuild(S,edge_ref,external_edges)
    


if __name__ == '__main__':
    main()

