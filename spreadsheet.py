# FROM https://www.twilio.com/blog/2017/02/an-easy-way-to-read-and-write-to-a-google-spreadsheet-in-python.html
import json, csv, gspread, os, string
from oauth2client.service_account import ServiceAccountCredentials
from fuzzywuzzy import fuzz, process
from get_timesheet_url import get_timesheets

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
scope = ['https://spreadsheets.google.com/feeds',
    'https://www.googleapis.com/auth/drive']
creds = ServiceAccountCredentials.from_json_keyfile_name(python_path+'client_secret.json', scope)
#print(creds.__dict__)
client = gspread.authorize(creds)




#spreadsheet_list = get_timesheets()

def get_sheet_per_id(spreadsheet_id):
	sheet = client.open_by_key(spreadsheet_id)

	try:
		timesheet =  sheet.worksheet('Timesheet')
		return timesheet#.get_all_records()
	except:
		print(sheet.worksheets())

def get_all_spreadsheets():
	#this function needs fixing
	d=[]
	for i in spreadsheet_list:
		print(i['spreadsheet_name'], i['id'])
		try:
			list_of_hashed = get_sheet_per_id (i['id'])
			columns=list_of_hashed[0].keys()
			print(columns)
			d.append({"name":i['spreadsheet_name'], 'data':list_of_hashed})
		except:
			continue
		print()

sheet_id = '1z2fekRReG8ESBZe2mVegJmlRUT9-vtRIZIcT4i91Lls' # Time sheet teresa
#sheet_id = '1HBEXWjjgd_dhHtnCo4vOuYmkWAdh8tkeUx4BqFuG-80' # Timesheet TEst Charles

list_of_hashed = get_sheet_per_id (sheet_id)


def test_columns(sheet):
	col_list = ['Month','Date','Hourly rate','Start','Stop','Hours','Total','Resource','Task name','Activity','Reference']
	for x, y,z in zip(range(1, len(col_list)+1), string.ascii_uppercase, col_list):
		cell_val = sheet.acell(y+str(1)).value
		if not z==cell_val:
			print({"cell_no":y+str(1),"required_value":z,"spreadsheet_value": cell_val})

test_columns(list_of_hashed)


#print(d)
# import json
# with open('data.json', 'w') as outfile:
#     json.dump(list_of_hashed, outfile)
