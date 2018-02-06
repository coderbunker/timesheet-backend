

# FROM https://www.twilio.com/blog/2017/02/an-easy-way-to-read-and-write-to-a-google-spreadsheet-in-python.html
import json
import csv
import gspread
import os
from oauth2client.service_account import ServiceAccountCredentials
from fuzzywuzzy import fuzz
from fuzzywuzzy import process

# DEFINE LOAD DATA INFO

load_info=[["YeDian (Night+, NightPlus) Project Timesheet","/yedian.csv","Yedian"],["Coderbunker Internal Projects Timesheet","/internal_project.csv","Internal Projects"],["Atlas Project Timesheet","/atlas.csv" ,"Atlas"]]



# POSTGRESQL TABLE COLUMNS
psql_col=['resource','activity','taskname','date','stop','start','hours','hourly_rate','total']


# DEFINE PYTHON PATH

python_path= os.environ.get('PYTHON_PATH')
if python_path is None:
	python_path=''
	print(python_path)
else:
	python_path=python_path

data_path='./data'


# use creds to create a client to interact with the Google Drive API
scope = ['https://spreadsheets.google.com/feeds']
creds = ServiceAccountCredentials.from_json_keyfile_name(python_path+'client_secret.json', scope)
client = gspread.authorize(creds)

 
def load_data(client,googlesheet):

	# Find a workbook by name and open the first sheet
	# Make sure you use the right name here.

	sheet = client.open(googlesheet).sheet1
	return sheet
 
def tranform_data(sheet,psql_col):

	# Extract and print all of the values

	list_of_hashed = sheet.get_all_records()

	columns=list_of_hashed[0].keys()

	for i in columns:
		if i.lower()=='hours':
			hour_header=i
		
	data=[]
	for i in list_of_hashed: 
		if i[hour_header] != '':
			data.append(i)		

	drive_col=list_of_hashed[0].keys()
	
	return data, drive_col


def define_columns(drive_col,psql_col):

	# CREATE GOOGLE DRIVE DATA MAPPING WITH PSQL USING FUZZY MATCHING (case and title columns slightly vary between projects, sometimes having a space in the end etc)
	# https://marcobonzanini.com/2015/02/25/fuzzy-string-matching-in-python/
	mapping={}

	for k in drive_col:
		for i in psql_col:
			if(fuzz.ratio(k,i))>=60:
				mapping[i]=k
			

	# Define the columns insertion order

	insert_col=[]

	for i in psql_col:
		for j in mapping.keys():
			if i==j:
				insert_col.append(mapping[i])

	return insert_col

def createse_csv(data_path, csv_name, insert_col, data, project_name):

	# Insert the data

	f=open(data_path+csv_name, "w+")
	f = csv.writer(f)
	f.writerow(insert_col) # header
	for row in data:
		datainsert=[project_name]
		for x in insert_col:
			datainsert.append(row[x])
		print (datainsert)
		f.writerow(datainsert)

for i in load_info:
	googlesheet= i[0]
	csv_name=i[1]
	project_name=i[2]
	
	sheet = load_data(client,googlesheet)
	data, drive_col = tranform_data(sheet,psql_col)
	insert_col = define_columns(drive_col,psql_col)
	createse_csv(data_path, csv_name, insert_col, data, project_name)






