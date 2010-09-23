# -*- coding: cp1252 -*-
# Title: Spectral Bipartivity
# Version 0.2
# Andrew Conway <conway_andrew@bah.com>
# Description: Returns the bipartivity measure for a network.  This measure
# is derived from spectral graph theory, and was first proposed by Estrada
# and Rodriguez-Velazquez in 2005.  Added functionality to calculate nodal
# bipartivity contribution.
# Source: E. Estrada and J. A. Rodríguez-Velázquez, "Spectral measures of
# bipartivity in complex networks", PhysRev E 72, 046105 (2005)
__author__ = """Andrew Conway (conway_andrew@bah.com)"""
import networkx as NX
import numpy as N

def bipartivity_exact(G, focal=None):
    G_MAT=NX.to_numpy_matrix(G) # Convert NX network to adjacency matrix
    ei,ev=N.linalg.eig(G_MAT)   # Calculate eigenvalues abd eigenvectors

    SC_even=0       # Sum of the contributions from even closed walks in G
    SC_all=0        # Sum of the contributions of all closed walks in G

    if focal is None:
        ''' Formulas described on page 2
        First code block calculates bipartivity of G globally'''
        for j in range(0,G.number_of_nodes()):
            SC_even=SC_even+N.cosh(ei[j].real)
            SC_all=SC_all+N.e**(ei[j].real)
        # Proportion of even closed walks over all closed walks
        B=SC_even/SC_all    
    else:
        # If focal node is passed as str, or object
        if focal is not int:
            n=G.nodes()
            focal=n.index(focal)
        '''Second code block calculates contibution of 'focal' to bipartivity'''
        for j in range(0,G.number_of_nodes()):
            SC_even=SC_even+((ev[focal,j].real)**2)*(N.cosh(ei[j].real))
            SC_all=SC_all+((ev[focal,j].real)**2)*(N.e**(ei[j].real))
            
        B=SC_even/SC_all    # Proportion of even CW for focal node, ie how much
                            # the focal node contributes to bipartivity.
    return B

def bipartivity_PI(G):
    '''Needs power-iteration implementation for use with large networks'''
    
if __name__ == "__main__":
    Net1 = NX.read_edgelist("email.edgelist")
    #Net1=NX.generators.random_graphs.barabasi_albert_graph(1000,2)
    Net1.info()
    B=bipartivity_exact(Net1)
    print "Spectral bipartivity: "+str(B)
