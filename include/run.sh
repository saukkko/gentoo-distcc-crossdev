#!/bin/bash
set -e

for arg in $@
do
  case $arg in
    "--port="*)
      export PORT=$(gawk -F= '{ print $NF }' <<< $arg)
      ;;
    "--stats-port="*)
      export STATS_PORT=$(gawk -F= '{ print $NF }' <<< $arg)
      ;;
    "--log-level="*)
      export LOGLEVEL=$(gawk -F= '{ print $NF }' <<< $arg)
      ;;
    "--allow="*)
      export ALLOW=$(gawk -F= '{ print $NF }' <<< $arg)
      ;;
    "--nice="*)
      export NICE=$(gawk -F= '{ print $NF }' <<< $arg)
      ;;
  esac
done

DISTCCD_ARGS="--daemon --no-detach -P /run/distccd.pid --log-stderr --stats --stats-port $STATS_PORT --port $PORT --log-level $LOGLEVEL --allow $ALLOW -N $NICE"
echo [$(date "+%Y-%m-%d %H:%M:%S")]: Starting distccd with arguments: $DISTCCD_ARGS

/usr/bin/distccd $DISTCCD_ARGS
