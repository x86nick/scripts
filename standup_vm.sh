#!/bin/bash

set -eu

#
# This script was a hacked to try to use cobbler api
#

#
# TODO:
#  1. Do error checking on opts
#  2. Change this to func commands and run from puppet box
#
#  Example:

# - Setup Help
printUsage() {
  echo -e "

  Requirements:
     1. This script must be run from the cobbler server as root
     2. You will need to be able to ssh to the hypervisor
     3. You will need access to the hypervisor

  Usage: $(basename $0)
       \t -s <hypervisor to use>
       \t -v <hostname of vm>
       \t -d <disk size of vm in G>
       \t -m <ram size to allocate to vm>
       \t -c <num of cpus to allocate to vm>
       \t -n <ip address for pxe interface of vm>
       \t -i <default ip address for vm>
       \t -r <default static routes ip>
       \t -p <cobbler profile to use>
       \t -h <help>
       \t -b <name servers>
       \t -l <location to store images>
       \t -e <bridge interface>
       \t -k <l3pod for puppet what file>

       Example:
       \t $(basename $0) -svmh02-p02 -vvmh02-account01-p02 -d20 -m2048 -c2 -n10.10.10.10 -i10.10.10.11 -r10.2.7.1 -ebr0.7 -b'10.160.0.15 10.2.3.15' -l/var/lib/kvm1 -pprecise-x86_64_MasterlessPuppet -kp02
       \t $(basename $0) -svmh02-p92 -vvmh02-intproxy01-p92 -d20 -m1024 -c2 -n10.160.92.21 -i10.92.251.20 -r10.92.0.1 -ebr0.92 -b'10.160.0.16 10.200.0.9 10.200.0.10' -l/var/lib/kvm1 -ptrusty-x86_64-kvm -kp92
    "
}

# Collect Options
while getopts "s:v:d:m:c:n:i:r:p:h:b:l:e:k:" arg; do
  case $arg in
    v)
      vmhostname=$OPTARG
      ;;
    d)
      disk_size=$OPTARG
      ;;
    m)
      mem_size=$OPTARG
      ;;
    c)
      num_cpus=$OPTARG
      ;;
    n)
      pxe_ip=$OPTARG
      ;;
    i)
      default_ip=$OPTARG
      ;;
    p)
      profile=$OPTARG
      ;;
    r)
      static_routes=$OPTARG
      ;;
    s)
      hypv=$OPTARG
      ;;
    b)
      bind_servers=$OPTARG
      ;;
    l)
      images_volume=$OPTARG
      ;;
    e)
      bridge_int=$OPTARG
      ;;
    k)
      l3pod=$OPTARG
      ;;
    h)
      printUsage
      exit 1
      ;;
  esac
done

# Check for # of arguments
if [ "$#" -ne 13 ]; then
    printUsage
    exit 1
fi

printMessage() {
    echo "########## $@ ##########"
}

# Check Requirements
echo ""
printMessage "Checking Pre-reqs"
hash cobbler 2> /dev/null || { echo " !!!!! Cobbler commandline not installed !!!!! " && exit 5; }
nc -vz $hypv 22 2> /dev/null || { echo " !!!!! Cannot connect to $hypv !!!!! " && exit 5; }
ssh $hypv "hash virsh" || { echo " !!!!! virsh is not installed on $hypv !!!!! " && exit 5; }

# Check if VM is already there
echo ""
printMessage "Checking if $vmhostname exists"
set +e
VMCOUNT=$(ssh $hypv "virsh list --all |grep -c $vmhostname")
set -e
if [ ${VMCOUNT} != "0" ] ; then
    printMessage "ERROR: $vmhostname already exists on $hypv: Please execute 'virsh destroy $vmhostname ; virsh undefine $vmhostname --remove-all-storage'"
    exit 5
fi

# Setup VM
echo ""
printMessage "Creating VM"
# POD93 doesn't support autostart
# ssh -t $hypv "virt-install --name $vmhostname --ram $mem_size --vcpus=$num_cpus --disk path=${images_volume}/${vmhostname}.img,size=$disk_size --vnc -v --accelerate --os-type=linux --network=bridge:br0,model=virtio --network=bridge:${bridge_int},model=virtio --pxe"

ssh -t $hypv "virt-install --name $vmhostname --ram $mem_size --vcpus=$num_cpus --disk path=${images_volume}/${vmhostname}.img,size=$disk_size --vnc -v --accelerate --os-type=linux --network=bridge:br0,model=virtio --network=bridge:${bridge_int},model=virtio --pxe --autostart"

printMessage "Getting MAC Addresses"
PXE_MAC=$(ssh $hypv "virsh dumpxml ${vmhostname}" |grep 'mac address' | awk -F\' '{ print $2 }'|head -1)
DEFAULT_MAC=$(ssh -t $hypv "virsh dumpxml ${vmhostname}" |grep 'mac address' | awk -F\' '{ print $2 }'|tail -1)
printMessage "PXE_MAC is $PXE_MAC"
printMessage "DEFAULT_MAC is $DEFAULT_MAC"

printMessage "Shutting down instances"
set +e
ssh -t $hypv "virsh destroy $vmhostname"
set -e

printMessage "Checking Cobbler for pre-existing system"
set +e
COBBLER_SYSTEM_CHECK=$(cobbler report list |egrep -c "$vmhostname|$pxe_ip|$PXE_MAC|$DEFAULT_MAC|$default_ip")
set -e
if [ "$COBBLER_SYSTEM_CHECK" != "0" ] ; then
    printMessage "THERE WAS A SYSTEM MATCHING ONE OF YOUR PARAMS"
    exit 5
fi

echo ""
printMessage "Setting up Cobbler"
echo " [ Issuing the following command ]"
echo cobbler system add --name=$vmhostname --hostname=${vmhostname}.mysite.net --ip-address=$pxe_ip --profile=$profile --interface=eth0 --mac=$PXE_MAC --gateway=10.160.0.1 --dhcp-tag=pxeboot  --dns-name=${vmhostname}.pxeboot.mysite.net --name-servers="${bind_servers}" --name-servers-search=mysite.net --virt-bridge=virbr0 --ksmeta="l3pod=$l3pod"
echo cobbler system edit --name=$vmhostname --interface=eth1 --ip-address=$default_ip --mac=$DEFAULT_MAC --subnet=255.255.0.0 --dns-name=${vmhostname}.mysite.net --static-routes=0/0:${static_routes} --virt-bridge=virbr0 --static=1

cobbler system add --name=$vmhostname --hostname=${vmhostname}.mysite.net --ip-address=$pxe_ip --profile=$profile --interface=eth0 --mac=$PXE_MAC --gateway=10.160.0.1 --dhcp-tag=pxeboot  --dns-name=${vmhostname}.pxeboot.mysite.net --name-servers="${bind_servers}" --name-servers-search=mysite.net --virt-bridge=virbr0 --ksmeta "l3pod=$l3pod"

cobbler system edit --name=$vmhostname --interface=eth1 --ip-address=$default_ip --mac=$DEFAULT_MAC --subnet=255.255.0.0 --dns-name=${vmhostname}.mysite.net --static-routes=0/0:${static_routes} --virt-bridge=virbr0 --static=1

sleep 5

echo ""
printMessage "Running Cobbler Sync"
cobbler sync

echo ""
printMessage "Starting up VM $vmhostname"
ssh $hypv "virsh start $vmhostname"
