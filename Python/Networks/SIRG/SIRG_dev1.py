#!/Library/Frameworks/Python.framework/Versions/2.5/bin/python
# encoding: utf-8
"""
SIRG_dev1.py

Created by Drew Conway on 2009-10-28.
Copyright (c) 2009. All rights reserved.
"""

import sys
import os
from networkx import *
import copy
from numpy import random,histogram

"""
Algorithm for generating graphs from some base structure, based on work entitled
Structurally Induced Random Graph Model.
Variables:
base_graph: some set of verticies and edges from which inference will be generated 
node_ceiling: some N such that when G{V}\ge N the simulation halts and the new graph is returns
metric: a statisitical operation that takes a NetworkX graph type and returns a graph-level
measure of structural fitness. This is used to determine which among burnt in graphs is fittest
tau: Number of verticies in the largest single-component graph for which subgraph isomorphisms
will be counted
beta: number of graphs to be generated at each growth iteration
mu: percent of times a graph is generated with endogenous growth rather than exogenous
"""
def sirg_graph_generator(base_graph,node_ceiling,metric,tau=4,beta=100,mu=0.15,verbose=False):
    new_graph=copy.deepcopy(base_graph)
    graph_count=1
    while new_graph.number_of_nodes()<node_ceiling:
        iso_counts=subgraph_distribution(new_graph,tau)  # Get isomorphism counts
        total_iso=sum(iso_counts.values())              
        prior_iso_dist=dict.fromkeys(iso_counts.keys()) # Get prior probability dist of sub-isomorphs
        for g in iso_counts.keys():
            prior_iso_dist[g]=float(iso_counts[g])/total_iso
        new_graph=simulate_growth(new_graph,prior_iso_dist,metric,beta,mu)
        new_graph.name="Graph Iteration: "+str(graph_count)
        if graph_count % 10<1:
            # Output progresss every ten iterations
            write_pajek(new_graph,'progress_estimate'+str(graph_count)+'.net')
        if verbose:
            info(new_graph)
            print 'Number of components: '+str(len(connected_component_subgraphs(new_graph)))
            print
        graph_count+=1
    if len(connected_component_subgraphs(new_graph))>1:
        # Finally, if new_graph has multiple components, conncet them to main component
        sub_components=connected_component_subgraphs(new_graph)[1:]
        while len(sub_components)>0:
            main_component=connected_component_subgraphs(new_graph)[0]
            mc_nodes=main_component.nodes()
            rand_mc_node=mc_nodes[random.randint(0,len(mc_nodes))]
            sub_comp=sub_components.pop()
            sub_node=sub_comp.nodes()[0]
            new_graph.add_edge(rand_mc_node,sub_node)
            if verbose:
                info(main_component)
                print 'Number of components:  '+str(len(connected_component_subgraphs(new_graph)))
                print
    new_graph.name="Final Graph Estimation"
    return new_graph
        
    
def simulate_growth(G,prior,statistic,iterations,mu):
# Generate some fixed number of potential future iterations
# of G based on draws from S
    graphs=dict()
    pd=create_pd(prior)
    for i in xrange(0,iterations):
        H=copy.deepcopy(G)
        draw=draw_structure(random.uniform(low=0.0,high=1.0),pd)
        H=add_structure(H,draw,mu)
        try: 
            graphs[statistic(H)].append(H)
        except KeyError:
            graphs[statistic(H)]=list()
            graphs[statistic(H)].append(H)
    return maxlikelihood_graph(graphs)
    
    
def maxlikelihood_graph(graph_dict):
# This function takes a dict of graphs keyed on some statistic and
# returns the graph that maximizes that statistic
    graphs=graph_dict.items()
    graphs.sort()
    max_graphs=graphs[-1][1]
    return max_graphs[random.randint(0,len(max_graphs))]
    
                
                
def add_structure(G,struct,mu):
# Adds draw from S to G based on decision rule R(.)
    V=struct.nodes()
    E=struct.edges()
    # 1) Connect any isolates to main component see if G has any isolates
    isos=find_isolates(G)
    nodes_in_mc=main_component_nodes(G)
    if random.uniform(low=0.0,high=1.0)<=mu:
        # If creating subisomorph from main component nodes, create subgraph 
        # ismorphism of struct from disconnected nodes in the main component
        neighbors=list()
        nodes_in=list()
        while len(nodes_in)!=len(V):
            rand_mc_node=nodes_in_mc[random.randint(0,len(nodes_in_mc))]    # Select random node in main component
            while nodes_in.count(rand_mc_node)>0:
                rand_mc_node=nodes_in_mc[random.randint(0,len(nodes_in_mc))]    # Prevent self-loops
            rand_neighbors=G.neighbors(rand_mc_node)
            good_node=True
            for n in neighbors:
                if rand_neighbors.count(n)>0:
                    good_node=False
            if good_node:
                nodes_in.append(rand_mc_node)
                for n in rand_neighbors:
                    neighbors.append(n)
        mc_node=nodes_in_mc.pop()
        return add_as_struct(G,E,V,nodes_in,mc_node)
    else:
        if len(isos)>0:
            # If isolates exist, connect them to main component as struct
            if len(isos)>=len(E):
                nodes_in=isos[:len(V)-1]   # Find one-minus isolate nodes to connect to main component as struct
                mc_node=nodes_in_mc[random.randint(0,len(nodes_in_mc))] # Select random node from main component
                return add_as_struct(G,E,V,nodes_in,mc_node)
            else:
                # Add remaining isolates
                nodes_in=isos   # Collect remaining isolate nodes
                for v in xrange(0,(len(V)-len(isos))-1):
                    nodes_in.append(nodes_in_mc[random.randint(0,len(nodes_in_mc))]) # Pick random MC nodes to fill out base_nodes
                mc_node=nodes_in_mc[random.randint(0,len(nodes_in_mc))] # Select random node from main component
                return add_as_struct(G,E,V,nodes_in,mc_node)
        else:
            # Build totally new structure
            nodes_in=range(len(G)+1,(len(G)+1)+(len(V)-1))    # New nodes will begin from 
            mc_node=nodes_in_mc[random.randint(0,len(nodes_in_mc))] # Select random node from main component
            return add_as_struct(G,E,V,nodes_in,mc_node)
                    
def add_as_struct(G,edges,verticies,base_nodes,final_node):
# Adds the structure reprsented in edges and verticies as 
# base_nodes and final node to graph G
    look_up=dict.fromkeys(verticies)
    # Create a dict to mirror struct edges in selected nodes, then
    # add new structure to graph G and return
    for v in xrange(0,len(verticies)-1):
        look_up[verticies[v]]=base_nodes[v]
    look_up[verticies[-1]]=final_node
    new_edges=list()
    for e in edges:
        new_edges.append((look_up[e[0]],look_up[e[1]]))
    G.add_edges_from(new_edges)
    return G
            
    
def main_component_nodes(G):
# Returns the nodes in the main component of G
    return connected_component_subgraphs(G)[0].nodes()
    
    
def find_isolates(G):
# Returns a list of isolate nodes in G
    isos=list()
    for n in G.nodes():
        if is_isolate(G,n):
            isos.append(n)
    return isos
    
def is_isolate(G,n):
    if len(G.neighbors(n))<1:
        return True
    else:
        return False

def draw_structure(rand_var,prob_dist):
# Draw some structure from S
    for interval in prob_dist.keys():
        if rand_var<interval[0] and rand_var>=interval[1]:
            struct=prob_dist[interval]
    return struct
    
def create_pd(prior_dist):
# Creates discrete probability distribution over S
    pd=dict()
    count=1.0
    for g in prior_dist.keys():
        if prior_dist[g]>0.0:
            interval=count-prior_dist[g]
            if interval<0.0:
                interval=0.0
            pd[(count,interval)]=g
            count=interval
    return pd
    
def subgraph_distribution(G,tau=4):
# Count the number of subgraph isomorphisms for all
# elements of I in G
    components=connected_component_subgraphs(G)
    subgraph_counts=get_subgraphs(tau)
    for g in components:
        if g.number_of_nodes()>1:
            for h in subgraph_counts.keys():
                GM=GraphMatcher(G,h)
                for i in GM.subgraph_isomorphisms_iter():
                    subgraph_counts[h]+=1
    return subgraph_counts
        
def get_counts(components_tup):
    g=components_tup[0]
    subgraphs=dict.fromkeys(components_tup[1],0)
    G=components_tup[2]
    return subgraphs

def get_subgraphs(tau):
# Returns a dict of all possible non-singleton subgraphs from a 
# dyad to $G=\{V=tau,E=\frac{tau(tau-1)}{2}\}$, i.e. the K_{tau}
# complete graph
    subgraphs=dict()
    for v in xrange(2,tau+1):
        graphs=all_graphs(v)
        for g in graphs:
            subgraphs[g]=0
    return subgraphs
        
        
def all_graphs(num_nodes):
# Retuns a list of all possible single component graphs given
# some number of nodes
    graphs=list()
    n_k=generators.complete_graph(num_nodes)    # Start with complete graph
    edges=n_k.edges()
    while n_k.number_of_edges()>0:
        e=edges.pop()
        n_k.remove_edge(e[0],e[1])
        if component.number_connected_components(n_k)==1:
            graphs.append(copy.deepcopy(n_k))
    graphs.append(generators.complete_graph(num_nodes))
    return graphs
    
def random_deletion(G,num_to_delete=None):
# Returns a NX graph object of G with some number of 
# nodes and edges randomly deleted,
    if num_to_delete is None:
    # If no nodes to delete has been provided, create a random number
    # that is at least equal to half of the graph
        num_to_delete=random.randint(low=round(len(G)*.5),high=len(G))
    for i in xrange(0,num_to_delete):
        current_nodes=G.nodes()
        # Select a random node index
        to_delete=random.randint(0,len(current_nodes))
        # Remove that node
        G.remove_node(current_nodes[to_delete])
    return G

def main():
    G=generators.barabasi_albert_graph(100,2)
    #write_pajek(G,'actual_network.txt')
    #G=Graph(read_pajek(path='drug_main.net'))
    G.name='Actual Graph'
    info(G)
    #base=random_deletion(G,num_to_delete=120)
    base=copy.deepcopy(G)
    base.name='Base Graph'
    print
    write_pajek(base,'test_base.net')
    #print
    info(base)
    new_graph=sirg_graph_generator(base_graph=G,node_ceiling=200,metric=transitivity,tau=4,beta=100,mu=0.15,verbose=True)
    new_graph.name='Estiamted Graph'
    print
    info(new_graph)
    write_pajek(new_graph,'new_estimate.net')
    
if __name__ == '__main__':
    main()

