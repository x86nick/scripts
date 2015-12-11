# cat sync_puppet.sh
#!/bin/bash

set -e -u
#set -v -x                                  # Debug mode placeholder

# --------------------------
# Cron Entry
# 0 0 * * * sync_puppet.sh <IP TO SYNC FROM>
# --------------------------


# VARS
RSYNC_OPTS="--dry-run -avhz --progress -e"  # Debug mode placeholder
#RSYNC_OPTS="-avhz --progress -e"
ALERT_EMAIL="myeamail@mydomain.com"
FILE_LIST="/etc/puppet /var/lib/puppet /var/www"
PUPPET_MASTER="$1"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
SSH_USER=root
BACKUP_DIR=/backup/
DATE=$(date +%Y_%m_%d)
BACKUP_RETENTION=10
PROG_NAME=$(basename $0)


# FUNCTIONS
CreateBackupDir(){

    mkdir -p $BACKUP_DIR/$DATE || EmailFailure "Error Creating backup directory for $PROG_NAME on $(hostname)"

    for DIR in $FILE_LIST ; do
        mkdir -p $BACKUP_DIR/$DATE/$DIR
    done

    if [ -d $BACKUP_DIR ] ; then
        cd $BACKUP_DIR
        find $BACKUP_DIR/$DATE -mtime +${BACKUP_RETENTION} -exec rm {} \;
    fi

}

PrintUsage(){

    echo
    echo "Usage: $PROG_NAME [IP|Hostname] of Puppet Server to sync from"
    echo

}


CheckArgs (){

    if [ -z $PUPPET_MASTER ] ; then
        PrintUsage
    fi

}

EmailFailure() {

    echo $@ | mail -s "CRON: $PROG_NAME Failed on $(hostname)" $ALERT_EMAIL

}

CheckReqs(){

    command -v rsync >/dev/null 2>&1 || apt-get install rsync

}

RunRsync(){

    for DIR in $FILE_LIST ; do
        rsync $RSYNC_OPTS "ssh $SSH_OPTS" $SSH_USER@$PUPPET_MASTER:$DIR $BACKUP_DIR/$DATE/$DIR || EmailFailure
    done

}

main(){

    CheckArgs
    CheckReqs
    CreateBackupDir
    RunRsync

}

main
