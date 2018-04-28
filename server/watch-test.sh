#!/bin/bash
./test.sh
#fswatch -or ./sql/ |  xargs -n1 -t -- psql -f heroku-timesheet {} &&
fswatch -r ./sql/ | xargs -I % echo "psql heroku-timesheet -f %; ./test.sh" | sh