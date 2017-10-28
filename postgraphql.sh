#!/bin/bash
./node_modules/.bin/postgraphql \
	--disable-default-mutations \
	--dynamic-json \
	--schema dw \
	--watch \
	-c postgres://localhost/timesheet \
	--cors \
	--host 10.209.193.135
