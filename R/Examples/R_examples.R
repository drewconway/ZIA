# File-Name:       R_examples.R                 
# Date:            2009-05-15                                
# Author:          Drew Conway                                       
# Purpose:         Provide example of how to perform analysis covered in May 15 brief
# Data Used:       friendship
# Packages Used:   Zelig
# Output File:     
# Data Output:     
# Machine:         Drew Conway's MacBook                         
                                                                    
# Load Zelig package

library(Zelig)

### Measuring Network Effects ###

# Attach the built-in friendship data set
data(friendship)

# Inspect the network data
friendship$friends

# We see that it is an NxN sociomatrix

# For this example, we are interested in how the dyadic network structure and scores 
# on prestige and advice, affect perceived power.

# We use the built-in network regression in Zelig to fit the model
z.out<-zelig(perpower ~ friends + advice + prestige, model = "normal.net", data = friendship)

# Get regression results
summary(z.out)

# We find that advice has a strong and significant positive effect on preceived power, 
# though the standard errors are high.

### One-dimensional Item Response ###

# We will be using the same data, so we do not need to re-attach it

# First, extract just the network data portion
friends.net<-friendship$friends

# Convert to a R data frame so it can be analyzed by Zelig
friends.df<-data.frame(friends.net)

# Perform MCMC to get one-dimensional likeness scale
mcmc.out<-zelig(cbind(X1,X2,X3,X4,X5,X6,X7,X8,X9,X10,X11,X12,X13,X14,X15)~NULL,
    model="irt1d", data=friends.df,verbose=TRUE)
    
# Get results and interpret
summary(mcmc.out)