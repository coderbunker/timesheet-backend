#!/bin/bash
if [ -z "$1" ]; then
	echo "please provide dbname"
	exit 1
fi

# if matches will return the smallest prefix thus not equal
if [[ $1 == postgres://* ]]; then
	DBNAME=$1
else
	DBNAME="postgres://localhost/$1"
fi

echo "Using $DBNAME"

psql -f sql/utils/disconnect.sql $DBNAME
psql -c "SELECT utils.disconnect('$DBNAME');" $DBNAME
psql -v "ON_ERROR_STOP=1" -b -1 -e -f sql/PSQL.sql $DBNAME
#echo "# you can now run npm start to start the GraphQL endpoints"
#echo "# run:"
#echo "npm start"

