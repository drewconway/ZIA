#!/usr/bin/env python
# encoding: utf-8
"""
multivariate_regression_ex.py

Created by Andrew Conway on 2008-12-16.
Copyright (c) 2008. All rights reserved.


Example code to show how to use Python and with RPy to perform multivariate regression
Ref: http://www2.warwick.ac.uk/fac/sci/moac/currentstudents/peter_cock/python/lin_reg/

Basic Steps:
1. Input Data, and clean
2. Create appropriate R commands from data to pass through RPy
3. Perform regression
4. Parse results and print to stdout
"""

import sys
import os
import rpy
import csv

def make_R_strings(dv,iv):
# This creates two strings that RPy uses to execute the regression command
# First, it creates the actual R expression of the linear model, which is
# always of the form 'DependantVar ~ IndependentVar1 + IndependentVar2 + ... +IndependentVarK'.
# Then, Python must reference back to data stored in memory, therefore, the second 
# string is the data frame based on the user input.
    dv_label=dv.keys()  # Store variable labels
    iv_labels=iv.keys()
    
    # The dependent variable always comes first
    R_string=dv_label[0]+" ~ "
    frame=dv_label[0]+"=dv['"+dv_label[0]+"'], "
    
    last_var=iv_labels[-1]  # note the final iv
    
    # Then add independent variables as appropriate
    for v in iv_labels:
        if v==last_var:
            R_string=R_string+v
            frame=frame+v+"=iv['"+v+"']"
        else:
            R_string=R_string+v+" + "
            frame=frame+v+"=iv['"+v+"'], "
    print 'R expression: '+R_string
    print
    return R_string,frame
    

def regress(dv,iv):
# Performs regression using R's linear model function (lm)
    if type(dv.values()) is list and all(type(x) is list for x in iv.values()):
    # First check that all of the data is in list form, otherwise RPy will throw an error
        rpy.set_default_mode(rpy.NO_CONVERSION) # Keeps values in R format until we need them
        R_string,frame=make_R_strings(dv,iv)    # Create strings used by RPy to run regression
        
        # R runs the linear regression
        OLS_model=eval('rpy.r.lm(R_string, data=rpy.r.data_frame('+frame+'))')
        rpy.set_default_mode(rpy.BASIC_CONVERSION)  # Now convert back to usable format
        
        model_summary=rpy.r.summary(OLS_model)      # Store resultss
        
        # Extract all of the data of interest
        coeff=model_summary['coefficients'][:,0]    # Regression coeffecients
        std_err=model_summary['coefficients'][:,1]  # Standard Errors
        t_stat=model_summary['coefficients'][:,2]   # t-statistics
        p_val=model_summary['coefficients'][:,3]    # p-values
        r_sqr=model_summary['r.squared']            # R-squred
        asj_r_sqr=model_summary['adj.r.squared']    # Adjusted R-squared
        
        return coeff,std_err,t_stat,p_val,r_sqr,asj_r_sqr
    else:
        raise TypeError("All variables must all be of type 'list'")
        
def label_fixer(label):
# Adjusts characters sizes for data output
    if len(label)>8:
        return label[:7]+"~"
    else:
        label=label.zfill(8)
        return label.replace('0',' ')
        
def zero_pad(value):
# Adjust data output to keep table uniform
    if len(value)>5:
        value=value[:6]
    else:
        while len(value)<6:
            value=value+'0'
    return value
    
def replace(data,old,new):
# Alter data 
    for v in range(0,len(data)):
        if data[v]==old:
            data[v]=new
    return data

def conf_inter(data,co,se):
# Creates confidence intervals of coeffecients using RPy
    n=len(data)
    if n>29:
    # Use z-score for large sample sizes
        neg=co-(rpy.r.qnorm(0.975)*se)
        pos=co+(rpy.r.qnorm(0.975)*se)
        return "["+str(neg)[:7]+", "+str(pos)[:7]+"]"
    else:
    # Use t-score for small sample sizes
        neg=co-(rpy.r.qt(0.975,df=n-2)*se)
        pos=co+(rpy.r.qt(0.975,df=n-2)*se)
        return "["+str(neg)[:7]+", "+str(pos)[:7]+"]"
        
def read_csv(file_path,delim=','):
# Parses CSV data into dict that can be used to run regression
    data_file=csv.reader(open(file_path,'rb'),delimiter=delim)
    headings=data_file.next()
    data=[]
    # Ordering matters, so we have to be careful when moving from
    # a CSV to a dict
    for h in headings:
        data.append((h,[]))
    # First create a tuple with the headings and data
    for row in data_file:
        for i in range(0,len(headings)):
            try:
                data[i][1].append(float(row[i]))
            except ValueError:
                data[i][1].append(row[i])
    # Then, move the data into the dict in the correct order
    data_dict={}
    for d in data:
        data_dict[d[0]]=d[1]
        
    return data_dict
    
    # Then the independent variables
    for l in iv.keys():
        old_iv=iv[l]
        si_copy=list(strip_indexes)
        new_iv=[]
        for i in range(0,len(old_iv)):
            if len(si_copy)>0:
                if si_copy[0]==i:
                    si_copy.pop(0)
                else:
                    new_iv.append(old_iv[i])
            else:
                new_iv.append(old_iv[i])
        iv[l]=new_iv
    
    print 'Number of observations removed: '+str(len(strip_indexes))
        
    return dv,iv
    
    
def example_one():
#In this simple implementation, we simply run regression on hand-coded data
# Example data from: http://www2.warwick.ac.uk/fac/sci/moac/currentstudents/peter_cock/python/lin_reg/
    dependent={}
    independent={}
    
    dependent['y']=[1.65, 26.5, -5.93, 7.96]
    independent['x']=[5.05, 6.75, 3.21, 2.66]
    return dependent,independent
    

def example_two():
# 2) Here, we load in data from a comma-delimited file using Python's built-in CSV module
# ---- DATA ----
# National Annenberg Election Survey 2004: Military Cross-Section
# 656 members of active U.S. military households, including 372 service personnel, and 284 family members
# Interviewing Sept. 22 – Oct. 5, 2004
    dependent={}
    independent={}
    
    # First parse the whole data-set into a dict
    full_dataset=read_csv('DATA.TXT',delim='\t')
    
    # Then, extract variables we are interested in.  From the codebook, we will use the folloing variables:
    # cAA01 - Bush Favorability (0-10)
    # cCD111 - Chance of Terrorist Attack in Next Year (0-10)
    # cRA01 - Voter registration dummy variable (1: registered, 2: not)
    # For the regression, we will examine the relationship between Bush's favorability rating and someones
    # feelings on the liklihood of a terrorist attack happening, controling for whether they are actually
    # registered to vote.
    
    dependent['BushFav']=full_dataset['cAA01']
    independent['Terrorism']=replace(full_dataset['cCD111'],2,0)    # Must convert to actual binary data
    independent['RegVote']=full_dataset['cRA01']
        
    return dependent,independent
    
        
def main():
    
    #dependent,independent=example_one()
    dependent,independent=example_two()
    
    # Perform regression and pull all of the data
    co,se,ts,pv,rs,ar=regress(dependent,independent)    
    
    # Prepare the labels for the output
    labels=[dependent.keys()[0]]
    for l in independent.keys():
        labels.append(l)
    
    # Now we output the data to a readable table in the stdout
    print "Number of obs:\t\t"+str(len(dependent.values()[0]))
    print "R-squared:\t\t"+str(rs)[:6]
    print "Adjusted R-squared:\t"+str(ar)[:6]
    
    print "------------------------------------------------------------------|"
    print label_fixer(labels[0])+"| Coeff  | Std Er |    t   |  P>|t| | 95% Conf. Intervals |"
    print "--------|--------|--------|--------|--------|---------------------|"
    
    for a in range(0,len(labels[1:])):
        print label_fixer(labels[a+1])+"| "+zero_pad(str(round(co[a+1],4)))+" | "+zero_pad(str(round(se[a+1],4)))+" | "+zero_pad(str(round(ts[a+1],4)))+" | "+zero_pad(str(round(pv[a+1],4)))+" | "+conf_inter(independent[labels[a+1]],co[a+1],se[a+1])+"  |"
        
    print "Interce.| "+zero_pad(str(round(co[0],4)))+" | "+zero_pad(str(round(se[0],4)))+" | "+zero_pad(str(round(ts[0],4)))+" | "+zero_pad(str(round(pv[0],4)))+" | "+conf_inter(dependent[labels[0]],co[0],se[0])+"  |"
    print "------------------------------------------------------------------|"


if __name__ == '__main__':
    main()
