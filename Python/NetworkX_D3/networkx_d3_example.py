#!/usr/bin/env python
# encoding: utf-8
"""
networkx_d3_example.py

Description: A short example for using the D3 export feature.  Using Mike Dewar (@mikedewar)
Twitter social graph :)

Created by Drew Conway (drew.conway@nyu.edu) on 2011-07-25 
# Copyright (c) 2011, under the Simplified BSD License.  
# For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
# All rights reserved.
"""

import networkx as nx
from networkx.readwrite import d3_js


def main():
	# Load in Mike's data
	mikedewar = nx.read_graphml('mikedewar_rec.graphml')
	
	# We need to relabel nodes as Twitter name if we want to show the names in the plot
	label_dict = dict(map(lambda i : (mikedewar.nodes()[i], mikedewar.nodes(data=True)[i][1]['Label']), xrange(mikedewar.number_of_nodes())))
	mikedewar_d3 = nx.relabel_nodes(mikedewar, label_dict)	

	# Export 
	d3_js.export_d3_js(mikedewar_d3, files_dir="mikedewar", graphname="mikedewar", group="REC", node_labels=False)


if __name__ == '__main__':
	main()

	