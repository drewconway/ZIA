#!/usr/bin/env python
# encoding: utf-8
"""
twitterstats.py

Created by Andrew Conway on 2009-01-12.
Copyright (c) 2009 Andrew Conway. All rights reserved.
"""

import sys
import os
import cgi

from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app
import twitter
from pygooglechart import PieChart3D


class MainPage(webapp.RequestHandler):
# Creates the form to gather Twitter username and 
# number of post to analyze
    def get(self):
        self.response.out.write("""
            <form action="youtweet" method="post" target="youtweet" onSubmit="window.open('', 'youtweet', 'width=510,height=250,status=yes,resizable=yes,scrollbars=yes')">
                Twitter Username:     
                    <input type="text" name="user">
                    <br>
                Number of updates:  
                    <input type="text" name="updates">
                    <input type="submit" value="Analyze">
            </form>
        """)

        
class TwitterStats(webapp.RequestHandler):
# Gathers form data and creates GoogleChart URL
    def post(self,user=None,count=None):
        if user is None and count is None:
            user=cgi.escape(self.request.get('user'))
            count=int(cgi.escape(self.request.get('updates')))
        else:
            user='drewconway'
            count=100
        api=twitter.Api()   # <--- This is where the error occurrs, GAE does not want to create and API instance
        statuses = api.GetUserTimeline(user,count)
        updates = [s.text for s in statuses]
        tweet_dict=build_tweet_data(updates)
        url=create_chart(tweet_dict)
        self.response.out.write('<div><img src="'+url+'" align="center"></div><br>')
               

def get_reply(tweet):
# Find out who you have been tweeting
    users=[]
    words=tweet.split(' ')
    for w in words:
        if w.find('@')>-1:
            if len(w)>1:    
                users.append(w)
    return users


def build_tweet_data(raw_data,keep_updates=False):
# Creates dict with yoru tweets and how many times you have
# tweeted a given user
    tweet_ref={}
    if keep_updates:
        tweet_ref['Status Update']=0
    for u in raw_data:
        if u.find('@')>-1:
            to=get_reply(u)
            current_keys=tweet_ref.keys()
            for user in to:
                if current_keys.count(user)<1:
                    tweet_ref[user]=1
                else:
                    tweet_ref[user]=tweet_ref[user]+1
        else:
            if keep_updates:
                tweet_ref['Status Update']=tweet_ref['Status Update']+1
    return tweet_ref


def create_chart(tweet_dict):
# Calls to GoogleChart
    chart=PieChart3D(500,200)
    chart.add_data(tweet_dict.values())
    chart.set_colours(['282D8F'])
    chart.set_pie_labels(tweet_dict.keys())
    return chart.get_url()
    
application = webapp.WSGIApplication(
                                     [('/', MainPage),
                                      ('/youtweet', TwitterStats)],
                                     debug=True)
 
def main(): 
    run_wsgi_app(application)
    
    
    
if __name__ == '__main__':
	main()
