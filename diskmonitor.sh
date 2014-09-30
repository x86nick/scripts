#!/bin/bash
SCRIPT=/opt/workdir/bin/diskmonitor.sh
mkdir -p $(dirname ${SCRIPT})
# create the honor killing script
#
cat <<EOM | sudo tee -a ${SCRIPT}
#!/bin/bash
#
# logic: terminating IF disk my disk is full
#
export PATH=\${PATH}:/usr/local/bin
# if any disk is at 90% or greater capacity; terminate!
if df -k | grep -v Filesystem | awk '{print \$5}' | grep -q [09][0-9] ; then
export AWS_DEFAULT_REGION=us-west-1
cat <<EOF > /tmp/payload.json
payload={"text":"\$(hostname): disk is approaching full. "}
EOF

aws ec2 terminate-instances --instance-ids \$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
else
echo 'ok' > /dev/null
fi
EOM
# make this executable
sudo chmod +x ${SCRIPT}
# add it /etc/cron.d
cat <<EOF | sudo tee -a /etc/cron.d/diskmonitoraws
* * * * * root ${SCRIPT}
EOF
