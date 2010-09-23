#!/usr/bin/env python
# encoding: utf-8
"""
TwitterEgoBuilder.py

Created by Drew Conway on 2009-02-23.
Copyright (c) 2009. All rights reserved.

The purpose of this script is to generate a 
NetworkX DiGraph object based on the snowball
search results of a single starting node to 
K snowball rounds.
"""

import sys
import os
import time
import twitter
import networkx as NX
        

def snowball_build(twitter_api,seed_user,rounds):
# Main network building loop
    for r in range(0,rounds):
        if r<1:
            # Create initial egonet
            net=create_egonet(twitter_api,seed_user)
            if net.size()>99:
                print 'Running this script will exceed your Twitter API rate limit.  You already have enough friends!'
                break
        else:
            # Now perform snowball
            net=snowball_search(net,twitter_api,seed_user,r)
    return net
            
def snowball_search(network,twitter_api,seed_user,cur_round):
# Snowball uses create_egonet to generate new structure
    users=nodes_at_degree(network,cur_round)    # Get all the users at the current round degree
    for u in users:
        time.sleep(5)   # Wait five seconds in between to not hammer Twitter servers (H/T: @amyiris)
        search_results=create_egonet(twitter_api,u)
        network=NX.compose(network,search_results)
    return network

def create_egonet(twitter_api,seed_user):
# Function for created a directed ego-net object from inital seed Twitter user
    egonet=NX.DiGraph()
    
    # Get friend data. NOTE: we are restricted to only adding out-degree
    ego_friends=twitter_api.GetFriends(seed_user)
            
    # Create ego's edge list
    friend_ebunch=[(seed_user,str(u.screen_name)) for u in ego_friends]
    
    # Add edges
    egonet.add_edges_from(friend_ebunch)

    return egonet
    
def nodes_at_degree(network,degree):
# Get nodes to perform round k search on
    d=network.degree(with_labels=True)
    d=d.items()
    return [(a) for (a,b) in d if b==degree]

def main():
    # Create an authenticated Api object in order to download user data
    api_user='your_twitter_id'
    api_pswd='your_twitter_password'
    api=twitter.Api(username=api_user,password=api_pswd)

    # The seed user to be analyzed
    seed='your_twitter_id'

    # Now create network
    k=2 # Number of snowball rounds (WARNING: k>2 will most certainly exceed the Twitter API rate limit)
    twitter_net=snowball_build(api,seed,k)
    
    #Store network data as plain text file to be analyzed later
    twitter_net._name=seed+'_k'+str(k)  # Name the network after the seed and the number of snowball rounds
    NX.write_edgelist(twitter_net,path='your_net.edgelist',delimiter='\t')


if __name__ == '__main__':
    main() 
