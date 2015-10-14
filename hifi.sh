#!/bin/bash
########## structure of script
########## hifi.py crawls lists and outputs a log file containing modified files
########## named file_change.log
########## 1) archive old log file if it exists
########## 2) run hifi.py
########## 3) email user if files have changed

########## Email from hifi.conf
email=$(cat hifi.conf | awk -F: '{ print $2 }')

########## file_change.log comes from hifi.py
filename="file_change.log"

########## append timestamp to log to archive
current_time=$(date "+%m.%d.%Y-%H.%M")
new_filename=$current_time.$filename
cur_dir=$(pwd)
old_log=$cur_dir"/"$filename
new_log=$cur_dir"/archive/"$new_filename

########## archive old file_change.log
if [ -f $filename ];
then
	mv $old_log $new_log
fi

########## ADD hifi.py here; if files changed, a new file_change.log
########## will be created

########## email user if new file_change.log exists
email_script="/email_notification.py"
abs_path_email=$cur_dir$email_script
if [ -f $filename ];
then
	$abs_path_email $email $old_log
fi
