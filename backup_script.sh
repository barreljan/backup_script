#!/bin/bash
#
# Backup script for the daily and weekly copys
# Files to fill:
#	to_backup		Normal files, webcontent, configuration dirs,etc
#	to_backup_sql		SQL databases. Enter only the database name
#
# 16-06-2013: created by bartjan@pc-mania.nl
# 03-09-2016: re-done script (simplified, improved, universal, use of input files)
# 13-10-2016: checks made if input files exist
# 21-02-2018: minor fixes in syntax and folders to get all files and delete them properly

# Variables to work with

if [[ "$(date +%a)" != "Sun" ]]; then
	btype="daily"
else
	btype="weekly"
fi
servername="$(hostname -s)"
log="/var/log/backuplog"
destination="backupstorage.servr.local:/share/Backups/$servername/$btype"
basefolder="/root/scripts"

printf "\n========== $btype backup started at $(date) ==========\n" >> $log

# Do the backup of files, if any
if [[ -f $basefolder/to_backup ]]; then
	while read line
	do
		data="$data $line"
	done < $basefolder/to_backup
	printf "\nCopying Webcontent and Webserver configuration files...\n\n" >> $log

	rsync -qavhR --force --del --log-file="$log" --ipv4 --include ".*" $data $destination
else
	nofiles=true
fi

# Do the backup of databases, if any
if [[ -f $basefolder/to_backup_sql ]]; then
	printf "\nMaking the MySQL dumps...\n" >> $log
	if [ ! -d "/tmp/mysqlbackup_tmp" ]; then
		mkdir /tmp/mysqlbackup_tmp
	fi
	while read line
	do
		mysqldump --defaults-extra-file=/root/.my.cnf $line > /tmp/mysqlbackup_tmp/$line.sql
	done < $basefolder/to_backup_sql
	printf "\nCopying Databases and MySQL configuration...\n" >> $log

	rsync -qavh --force --ipv4 --del --force --log-file="$log" /tmp/mysqlbackup_tmp/ $destination/mysql

	printf "\nCleanup after SQL backup...\n" >> $log
	rm -rf /tmp/mysqlbackup_tmp
else
	nosql=true
fi

if [[ ! -z $nofiles && $nosql ]]; then
	printf "\nNothing to backup apparently...\n\n" >> $log
else
	printf "\nAll done!\n\n" >> $log
fi

