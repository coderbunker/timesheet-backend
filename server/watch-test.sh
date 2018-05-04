#!/bin/bash
if [ -z "$1" ]; then
	echo "please provide dbname"
	exit 1
fi
DBNAME=$1
./test.sh $DBNAME
fswatch -r ./sql/ | xargs -I % echo "psql $DBNAME -f %; ./test.sh $DBNAME" | sh