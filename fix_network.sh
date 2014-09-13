#!/bin/bash -eux

GATEWAY=192.168.18.1
if ping -c 5 $GATEWAY
then
        exit
else
        echo "NO SERVER CONNECTIVITY - CHANGING INTERFACES FILE AND REBOOTING"
        ln -fs /etc/network/interfaces.static /etc/network/interfaces
        #reboot
        /sbin/shutdown -r now
fi
done
