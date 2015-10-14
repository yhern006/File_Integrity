#!/usr/bin/python -tt
#changelog:
# - Merged fileInfo.py 
# - Force /proc not in DB
# - Walks through bwwlist directories
# - Added owner and maingroup fields to files table
# - Accounts for files removed from any bwwlist
# - Allows # comments in bwwlist files

import hashlib
import sqlite3
from email.mime.text import MIMEText
from datetime import date
import smtplib
import sys
import re
import os
import time
import stat
import pwd
import grp 

counter = 0
file_counter = 0
output = "The following files have changed:\n\n"
str_to_file = "The following files have changed:\n\n"
str_filereport = "file_report"

#filename,exists,perm,owner,maingroup,size,mtime,hashes,BWW list
#path="/home/csmajs/cto002/183/proj/"
#returns 0, if file does not exist
#returns 1, if file exist
def fileExist(filePath):
	if not os.path.exists(filePath):
		return 0
	return 1

#returns the permissions of the file in integer form
def permission(filePath):
    return int(oct(stat.S_IMODE(os.stat(filePath).st_mode)))

#check file size
def fileSize(filePath):
    return os.stat(filePath).st_size

#check modification time
def modTime(filePath):
    return time.ctime(os.path.getmtime(filePath))

def readingFile(filePath):
	file = open(filePath,"r")
	for line in file:
		line = line.rstrip('\n')
		if(line == sys.argv[2]):
			file.close()
			return 1
	file.close()
	return 0

def owner(filePath):
	stat_info = os.stat(filePath)
	uid = stat_info.st_uid
	user = pwd.getpwuid(uid)[0]
	return str(user)

def group(filePath):
	stat_info = os.stat(filePath)
	gid = stat_info.st_gid
	group = grp.getgrgid(gid)[0]
	return str(group)

def updateFileInfo(c, filePath, file_out):
    email_flag = 0
    if filePath.strip().startswith('/proc/')==True or filePath.strip()=='/proc': 
        return
    t=(filePath,)
    c.execute('''SELECT bwwlist FROM files WHERE pathname=?''', t)
    entry=c.fetchone()
    if entry != None:
        if entry[0] == 1:
            pass #An empty if statement so that blacklisted files are skipped
        else:
            exists = fileExist(filePath)
            perm = permission(filePath)
            fileOwner = owner(filePath)	
            mainGroup = group(filePath)
            size = fileSize(filePath)
            mtime =  modTime(filePath)
            hash = GetHash(filePath)
            c.execute('''SELECT exist, permissions, owner, maingroup, size, mtime, hash, bwwlist, reported, emailed FROM files WHERE pathname=?''',t)
            entry2=c.fetchone()
            fetchedExist=entry2[0]
            fetchedPerm=entry2[1]
            fetchedFileOwner=entry2[2]
            fetchedMainGroup=entry2[3]
            fetchedSize=entry2[4]
            fetchedMTime=entry2[5]
            fetchedHash=entry2[6]
            bwwlist=entry2[7]
            reported=entry2[8]
            emailed=entry2[9]
            if fetchedExist != exists or fetchedPerm != perm or fetchedFileOwner != fileOwner or fetchedMainGroup != mainGroup or fetchedSize != size or fetchedMTime != mtime or fetchedHash != hash:
                if bwwlist == 3: 
                    email_flag = 1
                    file_out.write(filePath + "<br>")
                    file_out.write("-----------------------------------<br>")
                    file_out.write("Last/Current\tpermissions\towner\tmaingroup\tsize\tmtime<br>")		
                    file_out.write("Last\t\t" + str(perm)+ "\t"+ fileOwner+ "\t"+ mainGroup+ "\t"+ str(size)+ "\t"+ str(mtime)+ "<br>")
                    file_out.write("Current\t"+str(fetchedPerm)+"\t"+ fetchedFileOwner+ "\t"+ fetchedMainGroup+ "\t"+ str(fetchedSize)+ "\t"+ str(fetchedMTime)+ "<br>")
                    file_out.write("Hash Last: " + fetchedHash + "<br>")
                    file_out.write("Hash Current: " + hash + "<br>")
                    file_out.write("<br>")
                    c.execute('''UPDATE files SET exist=?, permissions=?, owner=?, maingroup=?, size=?, mtime=?, hash=?, emailed=? WHERE pathname=?''', (exists, perm, fileOwner, mainGroup, size, mtime, hash, 1, filePath))
                t=(filePath,)
                c.execute('''SELECT * FROM report WHERE pathname=?''', t)
                entry3 = c.fetchone()
                if entry3 == None:
                    c.execute('''INSERT INTO report VALUES(?,?,?,?,?,?,?,?,?,?,?)''', (filePath, exists, perm, fileOwner, mainGroup, size, mtime, hash, bwwlist, 0, 0))
                else:
                    c.execute('''UPDATE report SET exist=?, permissions=?, owner=?, maingroup=?, size=?, mtime=?, hash=?, bwwlist=?, reported=? WHERE pathname=?''', (exists, perm, fileOwner, mainGroup, size, mtime, hash, bwwlist, 0, filePath))
                c.execute('''UPDATE files SET reported=? WHERE pathname=?''', (0, filePath))
    return email_flag
		

def PrintReport(c):
            t=(0,)
            c.execute('''SELECT pathname, exist, permissions, owner, maingroup, size, mtime, hash, bwwlist, reported FROM files WHERE reported=?''',t)
            entries=c.fetchall()
            for entry in entries:
                pathname=entry[0]
                t2=(pathname,)
                c.execute('''SELECT pathname, exist, permissions, owner, maingroup, size, mtime, hash, bwwlist, reported FROM report WHERE pathname=?''',t2)
                entry2=c.fetchone()
                if (entry2 != None) and (entry[2] != entry2[2] or entry[3] != entry2[3] or entry[4] != entry2[4] or entry[5] != entry2[5] or entry[6] != entry2[6] or entry[7] != entry2[7]) :
                    print pathname
                    print "-----------------------------------"
                    print "Last/Current\tpermissions\towner\tmaingroup\tsize\tmtime\t"
                    print "Last\t\t", entry[2], "\t", entry[3], "\t", entry[4], "\t", entry[5], "\t", entry[6], "\t"
                    print "Current\t\t", entry2[2], "\t", entry2[3], "\t", entry2[4], "\t", entry2[5], "\t", entry2[6], "\t"
                    print "Hash Last:\t", entry[7]
                    print "Hash Current:\t", entry2[7]
                    print ""
                    c.execute('''UPDATE files SET exist=?, permissions=?, owner=?, maingroup=?, size=?, mtime=?, hash=?, reported=? WHERE pathname=?''', (entry2[1], entry2[2], entry2[3], entry2[4], entry2[5], entry2[6], entry2[7], 1, pathname))
            
            c.execute('''UPDATE report SET reported=? WHERE reported=?''', (1, 0))

def removeComments(pathname):
    #Discard commented lines
    if pathname.strip().startswith('#')==True or pathname.strip().startswith('/proc/')==True or pathname.strip()=='/proc':
        return ""
    return re.sub('#.*$', '', pathname).strip()

def clearBwwList(c):
    c.execute('''UPDATE files SET bwwlist=?''', (0,))

def updateBwwList(c, pathname, list):
    if pathname.strip().startswith('/proc/')==True or pathname.strip()=='/proc': 
        return
    t=(pathname,)
    c.execute('''SELECT * FROM files WHERE pathname=?''', t)
    entry=c.fetchone()
    if entry==None:
        c.execute('''INSERT INTO files VALUES(?,?,?,?,?,?,?,?,?,?,?)''', (pathname, 1, 0, '', '', 0, 'init', 'init', list, 1, 1))
    else:
        c.execute('''UPDATE files SET bwwlist=? WHERE pathname=?''', (list,pathname))

def GetHash(filename):
    f2 = open(filename, "r")
    string = ""
    line_count = 0
    for line in f2:
        string = string + line
        line_count = line_count + 1
        if line_count==100000:
            break;
    m = hashlib.sha224(string).hexdigest()
    f2.close()
    return m
        
def main():
    global counter
    global output
    global file_counter
    global str_to_file
    conn = sqlite3.connect('oh.db')
    c = conn.cursor()
    # bwwlist is a number that indicates which list it's on
    # 0 no list
    # 1 blacklist
    # 2 whitelist
    # 3 watchlist
    email_flag = 0
    if len(sys.argv) == 1:
        c.execute('''CREATE TABLE IF NOT EXISTS files (pathname text, exist integer, permissions integer, owner text, maingroup text, size integer, mtime text, hash text, bwwlist integer, reported integer, emailed integer)''')
        c.execute('''CREATE TABLE IF NOT EXISTS report (pathname text, exist integer, permissions integer, owner text, maingroup text, size integer, mtime text, hash text, bwwlist integer, reported integer, emailed integer)''')
        clearBwwList(c)
        
        exclude = set(['proc'])
        directory = open("./directory", "r")
        for dline in directory:
            dline=removeComments(dline)
            for root,dirs,files in os.walk(dline, topdown=True):
                dirs[:] = [d for d in dirs if d not in exclude] 
                for name in files:
                    updateBwwList(c, os.path.join(root,name), 0)
        directory.close() 
        f = open("./blacklist", "r")
        for line in f:
            line=removeComments(line)
            if(line != '' and os.path.isfile(line)):
                updateBwwList(c, line, 1)
            for root,dirs,files in os.walk(line):
                dirs[:] = [d for d in dirs if d not in exclude] 
                for name in files:
                    updateBwwList(c, os.path.join(root,name), 1)
        f.close()
        f = open("./whitelist", "r")
        for line in f:
            line=removeComments(line)
            if(line != '' and os.path.isfile(line)):
                updateBwwList(c, line, 2)
            for root,dirs,files in os.walk(line):
                dirs[:] = [d for d in dirs if d not in exclude] 
                for name in files:
                    updateBwwList(c, os.path.join(root,name), 2)
        f.close()
        f = open("./watchlist", "r")
        for line in f:
            line=removeComments(line)
            if(line != '' and os.path.isfile(line)):
                updateBwwList(c, line, 3)
            for root,dirs,files in os.walk(line):
                dirs[:] = [d for d in dirs if d not in exclude] 
                for name in files:
                    updateBwwList(c, os.path.join(root,name), 3)
                    
        f.close()

        file_out = open("/tmp/file_change.log", 'w')
        directory = open("./directory", "r")
        for dline in directory:
            dline=removeComments(dline)
            if(dline != '' and os.path.isfile(dline)):
                if email_flag == 0:
                    email_flag = updateFileInfo(c, os.path.join(root,name),file_out)
                else:
                    updateFileInfo(c, os.path.join(root,name),file_out)
            for root,dirs,files in os.walk(dline, topdown=True):
                dirs[:] = [d for d in dirs if d not in exclude] 
                for name in files:
                    if email_flag == 0:
                        email_flag = updateFileInfo(c, os.path.join(root,name),file_out)
                    else:
                        updateFileInfo(c, os.path.join(root,name),file_out)
        directory.close()
        file_out.close()
        if email_flag == 1:
            ###
            #setup smtp via gmail
            SMTP_SERVER = "smtp.gmail.com"
            SMTP_PORT = 587
            SMTP_USERNAME = "cs183.fi.notification@gmail.com"
            SMTP_PASSWORD = "cs183fileintegrity"

            #Sender/Recipient Header Info
            email_config=open("./config", "r")
            for cline in email_config:
                email = re.search('^email\W*[:=]\W*(.*)$', cline)
            EMAIL_TO = [email.group(1)]
            EMAIL_FROM = "cs183.fi.notification@gmail.com"
            EMAIL_SUBJECT = "File Integrity Notification: "

            DATE_FORMAT = "%m/%d/%Y"
            EMAIL_SPACE = ", "

            #Message
            #DATA='Testing SMTP.'
            file = open("/tmp/file_change.log", 'r')
            DATA = file.read()
            DATA2 = MIMEText(DATA, 'html')

            msg = DATA2
            msg['Subject'] = EMAIL_SUBJECT + "%s" % (date.today().strftime(DATE_FORMAT))
            msg['To'] = EMAIL_SPACE.join(EMAIL_TO)
            msg['From'] = EMAIL_FROM
            mail = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
            mail.starttls()
            mail.login(SMTP_USERNAME, SMTP_PASSWORD)
            mail.sendmail(EMAIL_FROM, EMAIL_TO, msg.as_string())
            mail.quit()

            ###

        conn.commit()
        conn.close()
    elif sys.argv[1]=="report":
        PrintReport(c)
        conn.commit()
        conn.close()
    else:
        print "Usage: ./oh.sh [report]"

if __name__ == "__main__":
    main()
