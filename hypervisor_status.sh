#!/bin/bash

print_help() {
echo ""
echo "This program calculates the Hypervisor statistics"
echo ""
echo "Usage:"
echo "  $0 (-h | --help )"
#echo "  $0 (-d ) "
echo " -h, --help       Print this help screen"
#echo " -d               Display detailed statistics"
echo ""
}

warncheck()
{

if virsh list --all | grep shut 1> /dev/null
then
	echo "WARNING: Hypervisor has shut off VMs."
	echo "         Readings may be inacurate"
	echo ""
fi
}

geninfo()
{
echo "-------------"
echo "Hypervisor" `hostname`
echo "-------------"
echo ""
}

getcpu()
{

if [[ -f totalcpu.txt ]]
then
        echo "File totalcpu.txt exists - deleting file"
        rm totalcpu.txt
        grep vcpu /etc/libvirt/qemu/* | cut -d\> -f 2 | cut -d\< -f 1 > totalcpu.txt
else
	grep vcpu /etc/libvirt/qemu/* | cut -d\> -f 2 | cut -d\< -f 1 > totalcpu.txt
fi

total=0
while read line
do
	total=$(( $total + $line ))
done <totalcpu.txt

SYSCPU=`cat /proc/cpuinfo | grep MHz | wc -l`
echo "||||CPU||||"
echo "Final number of vCPUs in use is: $total"
echo "The system has a CPU limit of: $SYSCPU"
echo ""
}

getcpudetails()
{
echo "Details are as follows:"
grep cpu /etc/libvirt/qemu/* | sed 's/.xml:  <vcpu>/ - /' | sed 's/<\/vcpu>/ Cores/' | sed 's,/etc/libvirt/qemu/,,'
echo ""
}

getram()
{

if [[ -f totalram.txt ]]
then
	echo "File totalram.txt exists - deleting file"
	rm totalram.txt
	grep memory /etc/libvirt/qemu/* | cut -d\> -f 2 | cut -d\< -f 1 > totalram.txt
else
	grep memory /etc/libvirt/qemu/* | cut -d\> -f 2 | cut -d\< -f 1 > totalram.txt
fi

total=0
while read line
do
	total=$(( $total + $line ))
done <totalram.txt

SYSRAM=`free -gt | grep Total| awk '{ print $2 }'`
echo "||||RAM||||"
#echo "Total RAM is $total"
Gtotal=$(( total / 1024 / 1024 ))
echo "Total RAM in use in GB is $Gtotal"
echo "The system has a RAM limit of: $SYSRAM"
echo ""
}

getramdetails()
{
echo "Details are as follows:"
grep memory /etc/libvirt/qemu/* | sed 's/.xml:  <memory>/ - /' | sed 's/<\/memory>//' | sed 's,/etc/libvirt/qemu/,,'
echo ""
}

cleanup()
{
rm totalram.txt
rm totalcpu.txt
}

while test -n "$1"
do
    case "$1" in
        --help)
            print_help
            exit 0
            ;;
        -h)
            print_help
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            print_usage
            exit 0
            ;;
    esac
done

#clear

# Displays hostname
geninfo

# Executes getcpu function that calculates
# the ammount of processors
getcpu
getcpudetails

# Executes getram function that calculates
# the ammount of memory
getram
getramdetails

# Executes warncheck function
# VMs powered down may not reflect acutal usage
warncheck

# Remove buffer txt files
cleanup

