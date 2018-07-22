#!/bin/bash
if [ -z "$1" ]; then
	echo "please provide dbname"
	exit 1
fi

if [[ $1 == postgres://* ]]; then
	DBNAME=$1
else
	DBNAME="postgres://localhost/$1"
fi

echo "Using $DBNAME"

psql -f sql/utils/show_extensions.sql $DBNAME

