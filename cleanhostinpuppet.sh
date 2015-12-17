$ cat /usr/local/sbin/cleanhost.sh
#!/bin/bash

max_tries=3
skip_cert=false
skip_dashb=false
skip_deact=false

while getopts cdp opt
do
  case $opt
  in
    c)
      skip_cert=true
    ;;
    d)
      skip_dashb=true
    ;;
    p)
      skip_deact=true
  esac
done

shift $((OPTIND-1))

HOST="$1"

if [ -z "${HOST}" ]
then
        echo "Please provide host name to clean up after"
        exit 1
fi

output="$(mktemp /tmp/cleanhost.XXXXXXXXXX)"
tries=0

while true
do
  skip_run=false
  tries=$((tries+1))
  exit_code=0
  echo "$(date +%H:%M:%S) start"
  echo "Cleaning up after host ${HOST}"

  cert=0
  if ! $skip_cert
  then
    echo "Puppet cert"
    puppet cert clean $HOST > "$output" 2>&1
    cert=$?
    cat "$output"
    echo "$(date +%H:%M:%S) puppet cert clean return code: $cert"
    if [ $cert -eq 0 ]
    then
      skip_cert=true
    else
      egrep -q "header too long|nested asn1 error|not find a serial number for" "$output"
      long_header=$?
      echo "$(date +%H:%M:%S) grep header too long or nested asn1 or no serial number error return code: $long_header"
      if [ $long_header -eq 0 ]
      then
        echo "header too long or nested asn1 error error skiping this run"
        skip_run=true
      fi
    fi
  fi

  exit_code=$((exit_code+cert))

  node_del=0
  workoff=0
  if ! $skip_dashb
  then
    echo "Puppet dashboard"
    echo "working off the delayed job queue"
    su - puppet-dashboard -c "bundle exec rake RAILS_ENV=production jobs:workoff"
    workoff=$?
    echo "$(date +%H:%M:%S) work off return code: $workoff"
    if [ $workoff -eq 0 ]
    then
      echo "Now deleting the node from dashboard"
      su - puppet-dashboard -c "bundle exec rake RAILS_ENV=production node:del name=${HOST}" > "$output" 2>&1
      node_del=$?
      cat "$output"
      echo "$(date +%H:%M:%S) puppet dashboard node:del return code: $node_del"
      if [ $node_del -ne 0 ]
      then
        grep -q "Node $HOST doesn't exist!" "$output"
        do_not_exist=$?
        echo "$(date +%H:%M:%S) grep does not exist return code: $do_not_exist"
        if [ $do_not_exist -eq 0 ]
        then
          node_del=0
        fi
      else
        skip_dashb=true
      fi
      if [ $node_del -eq 0 ]
      then
        skip_dashb=true
      fi
    fi
  fi

  exit_code=$((exit_code+node_del+workoff))

  deactivate=0
  if ! $skip_deact
  then
    echo "Puppet node deactivate"
    puppet node deactivate $HOST > "$output" 2>&1
    deactivate=$?
    cat "$output"
    echo "$(date +%H:%M:%S) puppet node deactivate return code: $deactivate"
    if [ $deactivate -eq 0 ]
    then
      skip_deact=true
    else
      egrep -q "header too long|nested asn1 error" "$output"
      long_header=$?
      echo "$(date +%H:%M:%S) grep header too long or nested asn1 error return code: $long_header"
      if [ $long_header -eq 0 ]
      then
        echo "header too long or nested asn1 error error skiping this run"
        skip_run=true
      fi
    fi
  fi

  exit_code=$((exit_code+deactivate))

  $skip_run && tries=$((tries-1))

  echo "exit code would be... $exit_code this is the try number: $tries of $max_tries"
  if [ $exit_code -eq 0 -o $tries -ge $max_tries  ]
  then
    echo "$(date +%H:%M:%S) end"
    rm "$output"
    exit $exit_code
  else
    sleep 5
  fi

done

$
