#!/bin/ksh
if [ -z "$1" ]; then
	echo "Need argument with stack name"
fi
./hstacktest.sh $1 6
