# File_Integrity
[CS 183] UNIX System Administration Project

Name of Program: Oh.sh
Tested with CentOS 6.6 minimal

Program that monitors a file system and checks whether or not files
have been modified / compromised. It runs periodically and gets file information.

- User can configure which files need to be checked in a "whitelist" file.
- User can configure which files should not be checked in a "blacklist" file.
- User can configure which files need to be included in an email report in 
a "watchlist" file.
- User inputs email used for notification in "config" file.
- User lists which directories need to be checked in "directories" file.

## Features
Monitoring: monitors the files every 30 minutes every day and checks the 
hash values of the files to see if it changed.

Notification: sends an email notification to the user when files on the 
watchlist is changed. Email will have a log file attached to it.

Database backend: sqlite database which holds file stats

Reporting: generates a report file of all files changed

Web Interface: connects with the database and displays the files that 
were modified

## Contribution
This project was developed by a group of six.
Group members: Kevin Chang, Johnny Hua, John Miner, Connie To, Eric Tram

I mostly worked on the web interface that connects the database located 
in VirtualBox.

Biggest technical challenge was to access web interface via our virtual
machine.

### Source Files
oh.sh: main file where we merged most of our implementations, also 
computes checksums and stores last hashed value for each file

dbTable.php: connects to sqlite database

index.html: simple page which redirects to page that displays modified 
files

## Other Files

These are the files my teammates implemented.

hifi.py - crawls lists and outputs a log file containing modified files 

install.sh - installs the program

Installation Manual - manual for install.sh
