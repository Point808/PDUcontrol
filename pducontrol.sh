#!/bin/bash
# AUTHOR: Josh North
# EMAIL: josh.north@point808.com
# BRIEF: Script to control dumb telnet-accessible power strips.  Created with
#        clean output for use in Home Assistant or other automation but could
#        be used as a standalone app as well.
# USAGE: Make it executeable and run with -h to get usage flags.
#        You will also probably want to set up a cron task to make it run as a
#        sort of fake service.
# SETTINGS:
TEMPDIR="/tmp"
SCRIPTNAME=${0##*/}
show_help()
{
echo "
    USAGE: $0 [-h] [-d device] [-s plug] [-o plug] [-f plug] [-p]
      -h                Help - show this help text
      -d fqdn           Device - FQDN or IP of device to control
      -s plug           Status of given plug #
      -o plug           Turn ON given plug #
      -f plug           Turn OFF given plug #
      -p                Process pending jobs (to be called from cron, ex below)
          * * * * *           ${0} --host pdu01 --process >/dev/null 2>&1
          * * * * * sleep 10; ${0} --host pdu01 --process >/dev/null 2>&1
          * * * * * sleep 20; ${0} --host pdu01 --process >/dev/null 2>&1
          * * * * * sleep 30; ${0} --host pdu01 --process >/dev/null 2>&1
          * * * * * sleep 40; ${0} --host pdu01 --process >/dev/null 2>&1
          * * * * * sleep 50; ${0} --host pdu01 --process >/dev/null 2>&1
"
}
OPTIND=1
while getopts ":o:f:s:d:ph" FLAG; do
  case "$FLAG" in
    d)
      HOST=$OPTARG
      ;;
    o)
      ON=$OPTARG
      ;;
    f)
      OFF=$OPTARG
      ;;
    s)
      STATUS=$OPTARG
      ;;
    p)
      PROCESS=1
      ;;
    h)
      show_help
      ;;
    \?)
      echo "Invalid option: -$OPTARG.  Use -h flag for usage instructions."
      exit
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z ${STATUS} ]
  then
    :
  else
    cat $TEMPDIR/$SCRIPTNAME-$HOST-STATUS | grep -A 6 'Plug | Name' | grep -A 5 '+--------' | grep -v '+--------' | awk '$1 ~ /^'$STATUS'$/{ print $7; }'
fi
if [ -z ${ON} ]
  then
    :
  else
    echo "/On $ON" >> $TEMPDIR/$SCRIPTNAME-$HOST-QUEUE
fi
if [ -z ${OFF} ]
  then
    :
  else
    echo "/Off $OFF" >> $TEMPDIR/$SCRIPTNAME-$HOST-QUEUE
fi
if [ -z ${PROCESS} ]
  then
    :
  else
    if [ -f $TEMPDIR/$SCRIPTNAME-$HOST-QUEUE ]; then
        echo "/S" >> $TEMPDIR/$SCRIPTNAME-$HOST-QUEUE
        echo "/X" >> $TEMPDIR/$SCRIPTNAME-$HOST-QUEUE
        { cat $TEMPDIR/$SCRIPTNAME-$HOST-QUEUE; sleep 1; } | telnet $HOST > $TEMPDIR/$SCRIPTNAME-$HOST-STATUS 2>/dev/null
        truncate -s 0 $TEMPDIR/$SCRIPTNAME-$HOST-QUEUE
    fi
fi
exit