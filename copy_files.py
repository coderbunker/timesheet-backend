import psycopg2
import os	 


# Specify column information

column_names1="project_name, resource, activity, taskname, entry_date, stop, start, hours_worked"  
column_names2="project_name, resource, activity, taskname, entry_date, stop, start, hours_worked, hourly_rate, total"  # change column names if necessary

target_table='timedata.entries'


# Get all CSV file names from data folder
csvfiles=os.listdir('./data')

# Connect to postgresql
connection = psycopg2.connect("dbname=timesheet user=" + os.environ['USER'])


# Function declaration

SQL_STATEMENT = """
    COPY %s (%s) FROM STDIN WITH
        CSV
        HEADER
        DELIMITER AS ','
    """

def process_file(conn, table_name, file_object,column_names):
	cursor = conn.cursor()
	cursor.copy_expert(sql=SQL_STATEMENT % (table_name,column_names), file=file_object)
	conn.commit()
	cursor.close()

for i in csvfiles:
	print (i)
	if i=="internal_project.csv":
		column_names=column_names1
	else:
		column_names=column_names2
	my_file = open('data/'+i)
	process_file(connection,target_table,my_file,column_names)

connection.close()


