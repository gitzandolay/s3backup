# s3backup
Daily backup of a filesystem directory to an existing s3 bucket. 
Backup time and date appears in the backup filename. 
Backup files older than 7 days are purged from s3 bucket.
Status messages are loggd to a dedicated logfile.
Email status message is sent at the end of script run. 
