#!/bin/bash -eux`
interfaces="/etc/network/interfaces"
if grep dhcp $interfaces | grep -vq '#'
then
	echo "changing dhcp to static"
else
	echo "no dhcp"
exit
fi
apt-get -y install vlan
echo 8021q >> /etc/modules
modprobe -r 8021q
ipaddr=`ifconfig  eth0 | grep "inet addr" | cut -d ':' -f2 | cut -d ' ' -f1`
echo $ipaddr

grep -v eth0 $interfaces >/tmp/newinterface
cat >> /tmp/newinterface << EOF
auto eth0.210
iface eth0.210 inet static
address $ipaddr
netmask 255.255.255.0
gateway 192.168.18.1
EOF
cp $interfaces ${interfaces}.old
mv /tmp/newinterface $interfaces
