#!/bin/bash
./test.sh
fswatch -or ./sql/ |  xargs -n1 -t -- ./test.sh
