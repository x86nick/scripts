#!/bin/bash
#############install artifactroy from aritifactory
set -eu

#### install unzip & oracle java
sudo apt-get update
sudo apt-get -y install unzip
sudo apt-get -y install python-software-properties
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get -y update
sudo apt-get -y install oracle-java7-installer

cd /tmp
mkdir -p /opt/data

#Download aritifactory from artifactory
wget http://artifact.myDomain.com/artifactory/simple/third-party/artifactory-powerpack-standalone

mv artifactory-powerpack-standalone-3.2.2.zip /opt/data/
cd /opt/data
unzip artifactory-powerpack-standalone-3.2.2.zip


##Running artifactory
####


$ARTIFACTORY_HOME/bin/artifactoryctl start


apt-get -y install apache2

a2enmod

proxy


cat <<EOF | sudo tee -a /etc/apache2/sites-available/artifactory

<VirtualHost *:80>
  ServerName artifact.myDomain.com
  ServerAlias artifact
  ErrorLog "/var/log/apache2/artifactory-error_log"
<Location /artifactory/>
    Order deny,allow
    Allow from all
</Location>
  ProxyPreserveHost on
  ProxyPass /artifactory/ http://localhost:8081/artifactory/
  ProxyPassReverse /artifactory/ http://localhost:8081/artifactory/
</VirtualHost>

EOF
sudo a2ensite artifactory

