# s3backup
This script will backup a ec2 filesystem directory daily to an existing aws s3 bucket. 
The backup time and date will appear in the backup/archive filename when it is created.
Backup/archive files older than 7 days will be purged from the s3 bucket.
Status messages are logged to a dedicated logfile and an email status message is sent when the job is finished or when an issue occurs during run time. 
