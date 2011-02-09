# File-Name:       boxes_viz.R           
# Date:            2011-02-08                                
# Author:          Drew Conway
# Email:           drew.conway@nyu.edu                                      
# Purpose:         Visualize the probability of a win in the Super Bowl
#                   boxes game given historical data
# Data Used:       see super_bowl.R
# Packages Used:   ggplot2, and see super_bowl.R for additional
# Output File:    
# Data Output:     
# Machine:         Drew Conway's MacBook Pro

# Copyright (c) 2011, under the Simplified BSD License.  
# For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
# All rights reserved.                                                         

# Creates data frames. Only run if you have not already create data
# source(super_bowl.R)

# Load libraries
library(ggplot2)

# Create a data frame for boxes
positions<-do.call(rbind, lapply(0:9, function(x) cbind(0:9,x)))
boxes<-data.frame(x=positions[,1],y=positions[,2])

# Create a heatmap of probability of winning given different digit combinations by quarter
boxes.heatmap<-ggplot(boxes[1:10,], aes(xmin=x,xmax=x+1,ymin=y,ymax=x+1))+geom_rect(color="white")
