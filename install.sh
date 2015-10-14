#!/bin/bash

#install necessary packages
yum install -y python
yum install -y sqlite3

#store local path to hifi.sh; hifi.sh will be our tool's executable script
cur_dir=$(pwd)
file="/hifi.sh"
abs_path=$cur_dir$file

#backup and add crontab entry
crontab -l 2> /dev/null 1> tmp_mycron
echo "0,30 * * * * root $abs_path" >> tmp_mycron
crontab tmp_mycron
rm tmp_mycron

