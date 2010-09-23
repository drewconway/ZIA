#!/usr/bin/env python
# encoding: utf-8
"""
web_scrapper_howto.py

This script is designed to download and parse data on NFL players. The script
was designed as part of tutorial for Zero Intelligence Agents.

The original tutorial post can be found here:

Tutorial steps:

1. Import list of names to search and retrieve corresponding URLs
2. Download player data
3. Parse player data into Python dict

Created by Drew Conway on 2009-06-25.
Copyright (c) 2009. All rights reserved.
"""

import sys
import os
import urllib2
import csv
import html5lib
from html5lib import treebuilders

def get_players(path):
# Returns a list of player names from CSV file
    reader=csv.reader(open(path,'U'),delimiter=',')
    '''
    players=[]
    row_num=0
    for row in reader:
        if row_num<1:
        # Ignore the column headers
            row_num+=1
        else:
        # Player names are in the first column,
        # so we add data from index 0
            players.append(row[0])
    '''
    # A much more succint method for extracting the player names
    # was suggested by Michael Bommarito @mjbommar and is used below
    reader.next()
    return [row[0] for row in reader]
    
def get_player_profiles(player_list):
# Returns a dict of player profile URLs to be used in the next step
    # Dict will hold player profile pages indexed by player name
    player_profile_urls=dict.fromkeys(player_list)
    for n in player_list:
        names=n.split(' ')
        # Search for the player names at NFL.com to get their individual player profiles, which contain the
        # data we ultimately want.
        search_url="http://www.nfl.com/players/search?category=name&filter="+names[0]+"+"+names[1]+"&playerType=current"
        results=urllib2.urlopen(search_url)
        for l in results.readlines():
            try:
                if l.count('<a href')>0 and l.count('profile?id'):
                # Search the returned HTMl for the hyper-link data for the speciic player.
                # This is mostly string clean up stiff to make the URL string ready for thte next step.
                    split1=l.split('=')
                    first_piece=split1[1].lstrip('"')
                    second_piece=split1[2].split('"')[0]
                    player_profile_urls[n]="http://www.nfl.com"+first_piece+"="+second_piece
            except UnicodeDecodeError:
                print "Ignoring UnicodeDecodeError"
        results.close()
    return player_profile_urls
    
def parse_data(player_urls):
# Returns a dict of player data parse trees indexed by player name
    # Create a dict indexed by player names
    player_data=dict.fromkeys(player_urls.keys())
    # Download player profile data and parse using html5lib
    for name in player_urls.keys():
    # html5lib integrates the easy-to-use BeautifulSoup parse tree using the treebuilders library.
    # We will use this to parse the html
        parser=html5lib.HTMLParser(tree=treebuilders.getTreeBuilder("beautifulsoup"))
        tree=parser.parse(urllib2.urlopen(player_urls[name]).read())
        # The data we are looking for is contained in a <p></p> tag, so we search for these tags
        data=tree.findAll("p")
        # By examining one of the HTML sources, we see that the exact data we need are in this range,
        # so we extract just what we want
        stats=data[2:5]
        # The data is stored in Unicode, so we must decode this before moving on.
        # We also know, from examining the HTML that the data sequence is:
        #   1. height
        #   2. weight
        #   3. dob
        #   4. college
        # So, we will now extract that data and place it in our storage dict
        data_temp=[]
        for i in stats:
        # All important data comes after a colon, so we split on it
            decoded=i.decode("utf-8")
            pieces=decoded.split(':')
            data_temp.append(pieces)
        # Create a dict 
        player_dict=dict.fromkeys(['height','weight','dob','college'])
        # Once split and stored in data_temp, we use our knowledge of the HTML structure to extract the correct data.
        # The remaining work is all string cleaning
        # Extract height
        height=string_cleaner_hw(data_temp[0][1])
        player_dict['height']=height
        # Extract weight
        weight=int(string_cleaner_hw(data_temp[0][2]))
        player_dict['weight']=weight
        # Extract DOB
        dob=string_cleaner_dob(data_temp[1][1])
        player_dict['dob']=dob
        # Extarct college
        college=string_cleaner_college(data_temp[2][1])
        player_dict['college']=college
        player_data[name]=player_dict
        
    return player_data
    
def string_cleaner_hw(data_string):
# Small helper function to do string cleaning on height and weight data
    data_string=data_string.strip()
    data_string=data_string.split('\n')[0]
    return data_string.split(' ')[0]
    
def string_cleaner_dob(data_string):
# Small helper function to do string cleaning on DOB data
    data_string=data_string.strip()
    data_string=data_string.split('\t')[0]
    return data_string.split('\n')[0]
            
def string_cleaner_college(data_string):
# Small helper function to do string cleaning on college data
    data_string=data_string.strip()
    return data_string.split('\n')[0]

def write_data(data,path,new_path):
# Takes data dict and writes new data to a new file
    reader=csv.reader(open(path,'U'),delimiter=',')
    writer=csv.writer(open(new_path,"w"))
    row_num=0
    for row in reader:
        if row_num<1:
        # Keep ther same column headers as before, so we simply
        # re-write the first row.
            writer.writerow(row)
            row_num+=1
        else:
        # For the remainder of the rows, we write the old data with the new.
        # The first three cells of each row will be from the old spreadsheet,
        # but the remainder will all be from the data parsed in Part 1.
            player=row[0]
            position=row[1]
            rnd=row[2]
            height=height_cleaner(data[player]['height'])
            weight=data[player]['weight']
            dob=data[player]['dob']
            college=data[player]['college']
            current_row=[player,position,rnd,height,weight,dob,college]
            writer.writerow(current_row)
    print "New CSV file successfully written to "+new_path

def height_cleaner(height):
# The format of the height data (stored as: feet-inches) is troublesome
# for the CSV format. When it is read into a spreadsheet program (such as Excel)
# it will convert the data into a date (e.g, 6-1 = 6/1/2009).  To avoid this,
# we create a small helper function to alter the data to a new formate (feet'inches")
    height=height.replace('-',"'")
    return height+'"'

def main():
    # Part 1: Download and parse data
    player_file_path='NYG_DRAFT_PICKS.csv'
    players=get_players(player_file_path)
    player_urls=get_player_profiles(players)
    parsed_player_data=parse_data(player_urls)
    print parsed_player_data
    #Part 2: Write data back to CSV file
    write_data(parsed_player_data,player_file_path,'NYG_DRAFT_PICKS_COMPLETE.csv')

if __name__ == '__main__':
	main()

