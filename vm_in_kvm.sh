#!/bin/bash -eu

#
# This script was a hacked to try to use cobbler api
#

#
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

       Example:
       \t $(basename $0) -sphysicalhost -vphysicalhost-vm01 -d20 -m2048 -c2 -n10.10.10.10 -i10.10.10.11 -r10.2.7.1 -ebr0.vlan -b'10.160.0.15 10.2.3.15' -l/var/lib/kvm1 -pprecise-x86_64
    "
}

# Collect Options
while getopts "s:v:d:m:c:n:i:r:p:h:b:l:e:" arg; do
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
    h)
      printUsage
      exit 1
      ;;
  esac
done

# Check for # of arguments
if [ "$#" -ne 12 ]; then
    printUsage
    exit 1
fi

printMessage() {
    echo "########## $@ ##########"  
}

# Check Requirements
printMessage "Checking Pre-reqs"
hash cobbler 2> /dev/null || { echo " !!!!! Cobbler commandline not installed !!!!! " && exit 5; }
nc -vz $hypv 22 2> /dev/null || { echo " !!!!! Cannot connect to $hypv !!!!! " && exit 5; }
ssh $hypv "hash virsh" || { echo " !!!!! virsh is not installed on $hypv !!!!! " && exit 5; }

# Check if VM is already there
printMessage "Checking if $vmhostname exists"
set +e
VMCOUNT=$(ssh $hypv "virsh list --all |grep -c $vmhostname")
set -e 
if [ ${VMCOUNT} != "0" ] ; then
    printMessage "ERROR: $vmhostname already exists on $hypv: Please execute 'virsh destroy $vmhostname ; virsh undefine $vmhostname --remove-all-storage'"
    exit 5
fi

# Setup VM
printMessage "Creating VM"
ssh -t $hypv "virt-install --name $vmhostname --ram $mem_size --vcpus=$num_cpus --disk path=${images_volume}/${vmhostname}.img,size=$disk_size --vnc -v --accelerate --os-type=linux --network=bridge:br0 --network=bridge:${bridge_int} --pxe --autostart"

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

printMessage "Setting up Cobbler"
cobbler system add --name=$vmhostname --hostname=${vmhostname}.mydomain.net --ip-address=$pxe_ip --profile=$profile --mac=$PXE_MAC --gateway=10.160.0.1 --dhcp-tag=pxeboot  --dns-name=${vmhostname}.pxeboot.mydomain.net --name-servers="${bind_servers}" --name-servers-search=mydomain.net --virt-bridge=virbr0
cobbler system edit --name=$vmhostname --interface=eth1 --ip-address=$default_ip --mac=$DEFAULT_MAC --subnet=255.255.255.0 --dns-name=${vmhostname}.mydomain.net --static-routes=0/0:${static_routes} --virt-bridge=virbr0 --static=1
cobbler sync

printMessage "Starting up VM $vmhostname"
ssh $hypv "virsh start $vmhostname"
