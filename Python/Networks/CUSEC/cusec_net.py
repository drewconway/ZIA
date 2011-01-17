#!/usr/bin/env python
# encoding: utf-8
"""
cusec_net.py

Purpose:  

Author:   Drew Conway
Email:    drew.conway@nyu.edu
Date:     2011-01-15

Copyright (c) 2011, under the Simplified BSD License.  
For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
All rights reserved.
"""

import sys
import os
import networkx as nx
import twitter
from numpy import unique

def twitter_network(users, api, user_type="search", alt_type="friend"):
    """
    Given a list of Twitter users, create NetworkX object of relationships.
    args:   users           List of Twitter users as strings
            user_types      Type string for entries in 'users'
    """
    twitter_network=nx.DiGraph()
    # Iteratively create network with appropriate type data
    users=list(users)
    for u in users:
        try:
            user=api.GetUser(u)
            if user.protected is False:
                user_friends=api.GetFriends(u)
                for j in user_friends:
                    friend_name=j.screen_name
                    twitter_network.add_nodes_from([u,friend_name], type=alt_type)
                    twitter_network.add_edge(u,friend_name)
        except twitter.TwitterError:
            print("Warning: user "+u+" was not found. Ignoring.")
            users.remove(u)
    # Reset node type for users
    twitter_network.add_nodes_from(users, type=user_type)
    return twitter_network, nx.weakly_connected_component_subgraphs(twitter_network)[0], nx.subgraph(twitter_network, users)

def main():
	# Create authenticated API
    consumer_key=""
    consumer_secret=""
    access_token=""
    token_secret=""
    
    api=twitter.Api(consumer_key=consumer_key,consumer_secret=consumer_secret,access_token_key=access_token,access_token_secret=token_secret)
    hashtag="#cusec"

    # Get all of the CUSEC data
    cusec=list()
    for i in range(1,8):
        cusec.extend(api.GetSearch(hashtag,per_page=100,page=i))
    print("Number of searches returned: "+str(len(cusec)))
    
    # List of all CUSEC tweeters
    cusec_tweeters=unique(map(lambda s: s.user.screen_name, cusec))
    print("Number of people Tweeting "+hashtag+": "+str(len(cusec_tweeters)))
    
    # Create network
    cusec_network,cusec_mc,cusec_subgraph=twitter_network(cusec_tweeters, api, user_type="cusec")
    
    # Export networks
    nx.write_graphml(cusec_network, "data/cusec_network.graphml")
    nx.write_graphml(cusec_mc,"data/cusec_main_comp.graphml")
    nx.write_graphml(cusec_subgraph,"data/cusec_users_subgraph.graphml")
    
    print(nx.info(cusec_network))
    print("Number of weakly connected components: "+str(nx.number_weakly_connected_components(cusec_network)))
    


if __name__ == '__main__':
    main()
    