#!/bin/bash
apt-get update
apt-get -y install unzip
cd /tmp

wget http://xxxxxxx/oracle-jdk/UnlimitedJCEPolicyJDK7.zip
wget http://xxxxxxxxxx/oracle-jdk/jdk-7u60-linux-x64.gz

tar -xzf jdk-7u60-linux-x64.gz
mv jdk1.7.0_60 /opt

unzip -U -o -j -d /opt/jdk1.7.0_60/jre/lib/security UnlimitedJCEPolicyJDK7.zip

cat <<EOF | tee /bin/java_home
#!/usr/bin/env bash

# bind command line arguments to variables
while getopts "v:" name
do
  declare \$name="\$OPTARG"
done

# called with zero args
if [ 0 -eq \$# ]; then
  echo "Usage: java_home -v 1.7.0_60 -> /opt/jdk1.7.0_60"
  exit 1
fi

home="/opt/jdk\$v"

# java verson does not exist
if [ ! -d \$home ]; then
  echo "Cannot find directory for java version \$v. Tried: \$home"
  exit 2
fi

echo \$home
EOF

chmod +x /bin/java_home
