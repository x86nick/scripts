#!/bin/bash -eu



[ -f Dockerfile ] || { echo "No Dockerfile" ; exit 1; }
dockerExPort=$(sed -rne 's/EXPOSE ([0-9]+)/\1/p' Dockerfile)
[ $dockerExPort -gt 1000 ] || { echo "Bad exported port in Dockerfile" ; exit 1; }

# Now read some stuff
read -p "docker image: " dockerImage
read -p "nginx config: " nginxConfig
read -p "remote host name: " hostName

# Flatten the Dockerfile volumes in to mappings in a single string
dockerVolumes=""
exec 4<&0-
while read mapping
do
    [ -n $dockerVolumes ] && dockerVolumes="${dockerVolumes}+$mapping"
    [ -z $dockerVolumes ] && dockerVolumes="$mapping"
done < <(sed -rne 's/VOLUME (.*)/\1/p' Dockerfile | while read volume
do
  read -u 4 -p "host mapping for ${volume}: " mapping
  [ -z $mapping ] || echo "$mapping:$volume"
done)

dockerImage=$dockerImage
dockerExPort=$dockerExPort
nginxConfig=$nginxConfig
hostName=$hostName
dockerVolumes=$dockerVolumes
deploy \${1:-"deploy"} $dockerImage $dockerExPort $nginxConfig $hostName $dockerVolumes
EOF

chmod u+x deploy

echo deploy script has been written, now just:  bash deploy

# End
