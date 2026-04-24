#!/bin/bash
#
URL=$1


JSONDATE=$(curl -ksL $URL | jq '.trust_metadata.last_modified' 2> /dev/null)
EXITCODE=$?

if [ $EXITCODE -ne 0 ]; then
    echo "Could not get date from URL: $URL"
    exit 2
fi

JSONDATE=$(echo $JSONDATE | sed s/\"//g)


URLDATE=`date -d $JSONDATE +%s`
EXITCODE=$?

if [ $EXITCODE -ne 0 ]; then
    echo "Could not parse date:: $JSONDATE"
    exit 2
fi


TWODAYSAGO=`date -d "-2 days" +%s`
FIVEDAYSAGO=`date -d "-5 days" +%s`

if [ $FIVEDAYSAGO -ge $URLDATE ]; then
    echo "Metadata is more then 5 days old!"
    exit 2
fi


if [ $TWODAYSAGO -ge $URLDATE ]; then
    echo "Metadata is more then 2 days old!"
    exit 1
fi

echo "OK - Metadata is from: $JSONDATE"
exit 0
