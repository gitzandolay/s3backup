#!/usr/bin/env bash
# This script will backup an existing ec2 filesystem directory to an existing aws s3 folder.
# The script needs to be run from cron every morning @ 5 AM. Place the script in the following dir
# and add a entry to the ec2-user's crontabs to match the following:
# Crontab to run s3backup.sh daily at 5AM.
# * 5 * * * /home/ec2-user/scripts/s3backup.sh >> /var/log/s3backup.log 2>&1
#
# You need to change the following variables to match your environment:
# 1. # BACKUP_DIR="/home/ec2-user/backup"
# 2. # BACKUP_BUCKET="s3://foo-bucket"
# 3. # EMAIL_ACCOUNT="user@foo.com"
#
# Variables
# Full path to the ec2 filesyetem directory you want to backup daily
# BACKUP_DIR="/home/ec2-user/backup" 
BACKUP_DIR=""
#
# The destination s3 bucket - where the backup file will be placed
# BACKUP_BUCKET="s3://$BUCKET_NAME"
BACKUP_BUCKET=""
#
# Backup filename variables
DATE=`date`
BACKUP_FILE="BACKUP_$(date +"%Y-%m-%d_%H:%M:%S").tar.gz"
# Email account
# EMAIL_ACCOUNT="user@foo.com"
EMAIL_ACCOUNT=""
# Create the dedicated log file
LOG_FILE="/var/log/s3backup.log"
if [[ ! -e /var/log/s3backup.log ]]
	then
		sudo touch /var/log/s3backup.log
		sudo chmod 666 /var/log/s3backup.log
fi
# Status message when backup starts
echo "$DATE : Backup STARTED ... " >> $LOG_FILE
echo "$DATE : Contents of $BACKUP_DIR will be zipped and copied to $BACKUP_BUCKET" >> $LOG_FILE
#
# Create the backup file
tar -cpzf $BACKUP_DIR/$BACKUP_FILE $BACKUP_DIR
#
# Status message after backup file should have been created
echo "$DATE : Backup file $BACKUP_FILE should be created" >> $LOG_FILE
#
# Verify backup file was created
if [ -s "$BACKUP_DIR/$BACKUP_FILE" ]
	then
		echo "$DATE : $BACKUP_FILE archive successfully created" >> $LOG_FILE
		# Copy backup tar file to s3 bucket
		aws s3 cp $BACKUP_DIR/$BACKUP_FILE $BACKUP_BUCKET
		echo "$DATE : Uploading backup tar file $BACKUP_FILE to $BACKUP_BUCKET " >> $LOG_FILE
		echo "$DATE : Removing backup tar file $BACKUP_FILE from $BACKUP_DIR " >> $LOG_FILE
                rm "$BACKUP_DIR/$BACKUP_FILE"
	else
		echo "$DATE : $BACKUP_FILE archive was NOT created...." >> $LOG_FILE
		echo "$DATE : Backup FAILED !!!" >> $LOG_FILE
		grep "$DATE : " $LOG_FILE | mail -s "Backup FAILED !!!" $EMAIL_ACCOUNT
		exit
fi		
#
# Verify the backup file was copied to s3 bucket		
EXISTS=$(aws s3 ls $BACKUP_BUCKET/$BACKUP_FILE | awk '{print $4}')
if [ "$EXISTS" = "$BACKUP_FILE" ]
	then
		echo "$DATE : $BACKUP_FILE successfully uploaded to $BACKUP_BUCKET " >> $LOG_FILE
		aws s3 ls $BACKUP_BUCKET/ | while read -r line;
		do
		FILE_DATE=`echo $line|awk {'print $1" "$2'}`
		FILE_DATE=`date -d"$FILE_DATE" +%s`
		# Backup files will be retained for the number of days specified below
		RETENTION_TIME=`date --date "7 days ago" +%s`
			if [[ $FILE_DATE -lt $RETENTION_TIME ]]
				then
					FILE=`echo $line|awk {'print $4'}`
					if [[ $FILE != "" ]]
						then
							aws s3 rm $BACKUP_BUCKET/$FILE
							echo "$DATE : $FILE purged from $BACKUP_BUCKET" >> $LOG_FILE
					fi
			fi
		done
		echo "$DATE : Backup SUCCESSFUL ..." >> $LOG_FILE
		grep "$DATE : " $LOG_FILE | mail -s "Backup to s3 SUCCESSFUL..." $EMAIL_ACCOUNT
	else
		echo "$DATE : Upload of $BACKUP_FILE to $BACKUP_BUCKET FAILED ...." >> $LOG_FILE
		echo "$DATE : Backup FAILED !!!" >> $LOG_FILE
		grep "$DATE : " $LOG_FILE | mail -s "Backup FAILED !!!" $EMAIL_ACCOUNT
		exit
fi
