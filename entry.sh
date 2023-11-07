#!/bin/sh

if [ -n "${CRONTAB}" ]; then
  echo "${CRONTAB}" > /crontab.txt
else
  echo "Error: Missing 'CRONTAB' environment variable"
  exit 1
fi

# Test crontab
echo "Testing crontab.txt"
supercronic -test -debug /crontab.txt || exit 1

# Start supercronic
supercronic -passthrough-logs /crontab.txt
