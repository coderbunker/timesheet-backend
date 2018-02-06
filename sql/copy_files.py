import psycopg2
import os	 


# Get all CSV file names from data folder
csvfiles=os.listdir('./data')

SQL_STATEMENT = """
    COPY %s (%s) FROM STDIN WITH
        CSV
        HEADER
        DELIMTER AS ','
    """





my_file = open("/home/chuck/timesheet_venv/timesheet/data/yedian.csv")

column_names1="project_name, resource, activity, taskname, entry_date, stop, start, hours_worked"  
column_names2="project_name, resource, activity, taskname, entry_date, stop, start, hours_worked, hourly_rate, total"  # change column names if necessary

target_table='timedata.entries'

def process_file(conn, table_name, file_object,column_names):
    cursor = conn.cursor()
    cursor.copy_expert(sql=SQL_STATEMENT % (table_name,column_names), file=file_object)
    conn.commit()
    cursor.close()


connection = psycopg2.connect("dbname=timesheet user=chuck")

def copy_files(connection,target_table,my_file,column_names):
	try:
	    process_file(connection, target_table, my_file,column_names)
	finally:
	    connection.close()

#copy_files(connection,target_table,my_file,column_names)
