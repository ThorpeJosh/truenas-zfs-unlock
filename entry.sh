#!/bin/sh

if [ -n "${CRONTAB}" ]; then
  echo "${CRONTAB}" > /tmp/crontab.txt
else
  echo "Error: Missing 'CRONTAB' environment variable"
  exit 1
fi

# Test crontab
echo "Testing crontab.txt"
supercronic -test -debug /tmp/crontab.txt || exit 1

# Start supercronic
supercronic -passthrough-logs /tmp/crontab.txt
