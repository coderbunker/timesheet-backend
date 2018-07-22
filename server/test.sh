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

# cat pipe is to keep output quiet
psql -q -f sql/900-psql-testsuite.sql $DBNAME | cat
