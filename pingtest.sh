mailalert()
{
printf "$1" | /usr/bin/mail -aFrom:myemail@my-domain.com -s "$2" seconda-email@my-domain.com
}

flag=0
HOST=x.x.x.x
LOCALENV="local"
RMTENV="remote"

while true
do
if ping -c 1 $HOST &> /dev/null
then
#	echo "success"
	sleep 1
		if [ $flag -eq 1 ]
		then
			currentst="VPN Failure Cleared"
        		stdesc="VPN connectivity seems to have been restored"
			mailalert "$stdesc" "$currentst"
#			echo "Connectivity restored"
			flag=0
		fi

else
#	echo "failure"
	currentst="VPN Failure Detected"
	stdesc="Check VPN connectivity\nUnable to reach $HOST from $LOCALENV to $RMTENV"
	mailalert "$stdesc" "$currentst"
	sleep 4
	flag=1
fi
done
