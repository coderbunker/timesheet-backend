#!/bin/bash
if [ -z "$1" ]; then
	echo "please provide dbname"
	exit 1
fi
DBNAME=$1

psql -f sql/utils/disconnect.sql postgres://localhost/$DBNAME
psql -c "SELECT utils.disconnect('$DBNAME');" postgres://localhost/$DBNAME
psql -v "ON_ERROR_STOP=1" -b -1 -e -f sql/PSQL.sql postgres://localhost/$DBNAME
#echo "# you can now run npm start to start the GraphQL endpoints"
#echo "# run:"
#echo "npm start"

