#!/bin/bash 

RUNNINGDIR=/root/running
FILE=$RUNNINGDIR/labinit.sh

while true; do
	if [ -f $FILE ]; then
   		echo "File $FILE exists"
   		. $FILE
		sleep infinity
	else
   		echo "File $FILE does not exist."
   		sleep 5
	fi
done

