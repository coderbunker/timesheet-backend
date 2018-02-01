# FROM https://www.twilio.com/blog/2017/02/an-easy-way-to-read-and-write-to-a-google-spreadsheet-in-python.html
import json
import gspread
from oauth2client.service_account import ServiceAccountCredentials
 
 
# use creds to create a client to interact with the Google Drive API
scope = ['https://spreadsheets.google.com/feeds']
creds = ServiceAccountCredentials.from_json_keyfile_name('client_secret.json', scope)
client = gspread.authorize(creds)
 

# Find a workbook by name and open the first sheet
# Make sure you use the right name here.

sheet = client.open("Coderbunker Internal Projects Timesheet").sheet1
 
# Extract and print all of the values


list_of_hashes = sheet.get_all_records()
json_dumps=json.dumps(list_of_hashes).decode("utf-8-sig") #The decode("utf-8-sig"))is to remove the BOM that will create an Error in Postgresql

##** THE JSON STILL CANNOT BE LOADED IN POSTGRESQL BECAUSE OF A "" FORMAT ERROR

#json_dumps=json_dumps.replace('\"', '\\"')


f=open('/home/chuck/timesheet/timesheet.json','w')  
f.write(json_dumps)
f.close()

