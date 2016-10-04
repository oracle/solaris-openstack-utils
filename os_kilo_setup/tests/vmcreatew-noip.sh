#!/bin/ksh
# wait for creation
if [ -z "$1" ]; then
        echo "Pass name of VM"
        exit 1
fi
./vmcreate.sh $1 2 true false
