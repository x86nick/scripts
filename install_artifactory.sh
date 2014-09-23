#!/bin/bash
#### install unzip & oracle java

sudo apt-get -y update
sudo apt-get -y install software-properties-common python-software-properties unzip supervisor
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get -y update
# state that you accepted the license
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections

sudo apt-get -y install oracle-java7-installer

#Create a user that will run aritifactoy app
sudo useradd artifactory
# Download artifactory
cd /tmp
wget --quiet http://dl.bintray.com/jfrog/artifactory/artifactory-3.3.1.zip

unzip artifactory-3.3.1.zip

mv artifactory-3.3.1 /opt/artifactory

chown -R artifactory:artifactory /opt/artifactory

### Add artifacoty to path & start
cat <<EOF | sudo tee -a /etc/profile

#artifactory

export ARTIFACTORY_HOME=/opt/artifactory
if [ -d \${ARTIFACTORY_HOME} ] ; then
export PATH=\${PATH}:\${ARTIFACTORY_HOME}/bin
fi
EOF

#install apache for reverse proxy
sudo apt-get -y install apache2
sudo a2enmod -q proxy rewrite proxy_http

cat <<EOF | sudo tee -a /etc/apache2/sites-available/artifactory.conf

<VirtualHost *:80>
       ServerName artifactory.mydomain.com
       ServerAlias artifactory
       DocumentRoot /opt/loyal3/
       ErrorLog "/var/log/apache2/artifactory-error_log"
<Location /artifactory/>
	 Order deny,allow
	 Allow from all
</Location>
	RewriteEngine on
	RewriteRule ^/artifactory$ /artifactory/ [R=301]
	ProxyPreserveHost on
	ProxyPass /artifactory/ http://localhost:8081/artifactory/
	ProxyPassReverse /artifactory/ http://localhost:8081/artifactory/
</VirtualHost>

EOF

chmod +x /opt/artifactory/bin/artifactoryctl
#
  a2ensite artifactory.conf
  a2dissite 000-default
  service apache2 reload
#
#
/opt/artifactory/bin/artifactoryctl start
