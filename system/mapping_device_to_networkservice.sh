#!/bin/sh
# Takanori TANIGUCHI

TMPDIR="/tmp/`uuidgen`"
TMPFILE="${TMPDIR}/file_$$"
mkdir "${TMPDIR}"

networksetup -listnetworkserviceorder| grep -v "network service"  | while read line 
do 
	if [ 1 = `echo $line| egrep -c ^$` ]; then
		echo ${SV} >> "${TMPFILE}_0.txt"
		SV=""
	else	
		SV="${SV}${line} " 
	fi
done

networksetup -listallnetworkservices | grep -v "network service" | while read line
do
	DEVICE_NAME=`grep "$line" "${TMPFILE}_0.txt" | awk -F": " '{print $3}' | sed s/\)//g| uniq`
	echo "${DEVICE_NAME},${line}" >> "${TMPFILE}_1.txt"
done

cat "${TMPFILE}_1.txt"
rm -rf ${TMPDIR}