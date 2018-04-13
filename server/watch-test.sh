#!/bin/bash
fswatch -or ./sql/ |  xargs -n1 -t -- ./test.sh
