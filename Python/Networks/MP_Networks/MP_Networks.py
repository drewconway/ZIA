#!/usr/bin/env python
# encoding: utf-8
"""
MP_Networks.py

Generate a weighted 2-mode network of British MP's
to various lunch and dinner engaements

Created by Drew Conway on 2010-02-05.
Copyright (c) 2010. All rights reserved.
"""

import sys
import os
import networkx
import csv

def get_bipartite_proj(G,proj1_name=None,proj2_name=None):
    """docstring for get_bipartite_proj
    Returns the bipartite projection for each set
    of nodes in the bipartite graph G
    """
    if networkx.is_bipartite(G):
        set1,set2=networkx.bipartite_sets(G)
        net1=networkx.project(G,set1)
        net1.name=proj1_name
        net2=networkx.project(G,set2)
        net2.name=proj2_name
        return net1,net2
    else:
        raise networkx.NetworkXError("Network is not bipartite")
        
        
def dichotomize(G,thresh,remove_isolates=True):
    """docstring for dichotomize
    Returns a new Graph where all edges with weight<thresh removed
    """
    for e in G.edges(data=True):
        if e[2]["weight"]<=thresh:
            G.remove_edge(e[0],e[1])
        else:
            G.add_edge(e[0],e[1],weight=1)
    G.name=G.name+" Dichotomized < "+str(thresh)
    if remove_isolates:
        deg=G.degree(with_labels=True)
        deg=deg.items()
        isos=[(a) for (a,b) in deg if b<1]
        G.remove_nodes_from(isos)
    return G

def create_network(data_dict):
    """docstring for create_network
    Create a NetworkX object from the parsed MP data.
    This network will be a two-mode weighted network.
    """
    data_net=networkx.Graph(name="MP Network")
    for pair in data_dict.keys():
        MP=pair[0].replace(", ","_")
        Event=pair[1].replace(" ","_")
        # Each edge is weighted by the number of times a
        # Member attended this particular event
        data_net.add_edge(MP,Event,weight=data_dict[pair])
    return data_net

def parse_data(csv_obj):
    """docstring for parse_data
    Provided a csv.DictReader object, a dic
    """
    first=True
    for line in csv_obj:
        if first:
            mp_data=dict()
            first=False
        else:
            data_pair=(line["MP.Name"],line["Event"])
            if mp_data.keys().count(data_pair)<1:
                mp_data[data_pair]=1
            else:
                mp_data[data_pair]+=1
    return mp_data

def main():
    # Load and parse raw data
    csv_file="MP_DATA_CLEANDATE.csv"
    reader=csv.DictReader(open(csv_file,"rU"),fieldnames=["MP.Name","Date","Event","Type","Numbers","Venue.s."]) 
    parsed_mp=parse_data(reader)
    # Create base graph from raw data, and save to file
    G=create_network(parsed_mp)
    networkx.write_pajek(G,"MP_events.net")
    # Dichotomize data to remove all edges with a weight < 2
    G_dichot=dichotomize(G,thresh=1)
    G_dichot.remove_node("Association")
    networkx.info(G_dichot)
    # Generate MP-by-MP and Event-by-Event projections of the bipartite base graph
    mp_net,event_net=get_bipartite_proj(G_dichot,proj1_name="MP-by-MP",proj2_name="Event-by-Event")
    networkx.write_pajek(mp_net,"mp_net.net") 
    networkx.write_pajek(event_net,"event_net.net")
    # Perform some network cleaning for 

if __name__ == '__main__':
    main()

