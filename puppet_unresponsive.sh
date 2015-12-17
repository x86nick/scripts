#!/bin/bash

curl -s http://puppet14-dashboard.yoyo.local/nodes/unresponsive\?per_page\=all |
hxnormalize -x |
hxselect -s '\n' -c 'td.node a' |
while read host
do
  sudo /usr/local/sbin/cleanhost.sh -cp $host
done
