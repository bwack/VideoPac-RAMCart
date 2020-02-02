#!/bin/sh
# usage: upload.sh file speed
# set SERIAL to the port which is connected to the G7000RAM
SERIAL=/dev/ttyS1
if [ "$2" == "19200" ]
then
    stty raw clocal -crtscts cstopb 19200 <$SERIAL;
elif [ "$2" == "9600" ]
then
    stty raw clocal -crtscts 9600 <$SERIAL;
elif [ "$2" == "" ]
then
    stty raw clocal -crtscts 9600 <$SERIAL;
else
    echo $0: "The speed" $2 "is not supported."
    exit;
fi;
# test if file exists
if [ ! -f "$1" ]
then
    echo $0: "The file" $1 "does not exist."
    exit;
fi
# test for size
SIZE=`ls -l -d -G $1 | cut -b23-32`
if [ "$SIZE" -eq "3072" ]
then
    cp $1 $SERIAL
    cp $1 $SERIAL
    cp $1 $SERIAL
    cp $1 $SERIAL;
elif [ "$SIZE" -eq "6144" ]
then
    cp $1 $SERIAL
    cp $1 $SERIAL;
elif [ "$SIZE" -eq "12288" ]
then
    cp $1 $SERIAL;
else
    echo $0: "The filesize" $SIZE "is not supported."
    exit;
fi
