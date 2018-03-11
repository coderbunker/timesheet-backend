
# coding: utf-8

# Main source: https://api.github.com/users/coderbunker/events/public (https://developer.github.com/v3/activity/events)
# 
# Extract detail of each commit (from the url of sha within public events)
# https://api.github.com/repos/coderbunker/timesheet-backend/commits/3e714f24da1e29f9e4008605923ae7310fa3bc4d
# 
# Extract detail of issues: https://developer.github.com/v3/issues (e.g. https://api.github.com/repos/coderbunker/timesheet-backend/issues)

# In[150]:

import requests
import json
r = requests.get('https://api.github.com/users/coderbunker/events/public')
json_public_events = r.json()


# In[160]:

import pandas as pd
def recurse_keys(df, indent = '  '):                  
    for key in df.keys():
        print(indent+str(key))
        if isinstance(df[key], dict):
            recurse_keys(df[key], indent+'   ')
df_public_events = pd.DataFrame(json_public_events)  
#recurse_keys(df_public_events)
#print(df_public_events.head())
#print(df_public_events.loc[0,'actor'])
#print(df_public_events.loc[0,'org'])
print(df_public_events.loc[0,'payload'])
#print(df_public_events.loc[0,'repo'])


# To do:
# 
# Sort the sha and message values in payload/commits into separate columns
# 
# Index by date w. datetime and by member
# 
# Extract data from other sources

# In[166]:

print(df_public_events.loc[0,'payload'].items())
df_public_events['member'] = [x['login'] for x in df_public_events['actor']]
df_public_events['project'] = [x['name'] for x in df_public_events['repo']]
df_public_events['commit_key']=[x['commits']['sha'] for x in df_public_events['payload']]
df_public_events['commit_msg']=[x['commits']['message'] for x in df_public_events['payload']]
df_public_events_sorted = pd.DataFrame(df_public_events,columns=['created_at','member','project','type','commit_key','commit_msg'])
print(df_public_events_sorted.head())

