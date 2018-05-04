#!/bin/bash
if [ -z "$1" ]; then
	echo "please provide dbname"
	exit 1
fi
DBNAME=$1
psql -f sql/900-psql-testsuite.sql $DBNAME
