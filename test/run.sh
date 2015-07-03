#!/bin/bash

i=1

while true; do
	echo "Exec: $i"
	if (( i > 10 )); then
		echo "End\!\!\!"
		exit
	else
		echo "Google test"
		rm /tmp/google
		wget -o /tmp/google.log -O /tmp/google http://www.google.com?q=${i}
		i=$[$i+1]
		sleep 3
	fi
done
