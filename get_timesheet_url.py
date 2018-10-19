from __future__ import print_function
from googleapiclient.discovery import build
from httplib2 import Http
from oauth2client import file, client, tools

# If modifying these scopes, delete the file token.json.
SCOPES = 'https://www.googleapis.com/auth/drive.metadata.readonly'

def get_timesheets():
    store = file.Storage('token.json')
    creds = store.get()
    if not creds or creds.invalid:
        flow = client.flow_from_clientsecrets('credentials.json', SCOPES)
        creds = tools.run_flow(flow, store)
    service = build('drive', 'v3', http=creds.authorize(Http()))

    results = service.files().list(
        pageSize= 1000,
        q="name contains 'Timesheet'",
        fields="nextPageToken, files(id, name, parents, properties)").execute()
    items = results.get('files', [])
    if not items:
        print('No files found.')
    else:
        l=[]
        for item in items:
            l.append({'spreasheet_name':item['name'], 'id': item['id']})
    print(results)
    return l
    
if __name__ == '__main__':
    print(get_timesheets())
