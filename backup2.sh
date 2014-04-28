#!/bin/bash

# *** rdiff-backup script for my laptop ***
# It figures out whether it's on a home network or not and selects full or partial backup.
# Should work for most linux distributions, tested on LMDE, Arch Linux
# Requires rdiff-backup, openssh (default port)

# update these variables for your systems:
# global vars
user='user'
server_athome='your.local.hostname' 
server_away='your.domain.com'
disk="/dev/sdX" # disk for MBR backup
args="-v 5"

# run 1 vars
backupdir_home="/backup/user-home/" # directory on server
sourcedir_home="/home/user/" # local source directory
args_home=" --exclude /home/user/.cache"

# run 2 vars
backupdir_full="/backup/user-full/"
sourcedir_full="/"
args_full=" --exclude /dev/'*' "\
"--exclude /media/'*' "\
'--exclude /mnt/"*" '\
'--exclude /proc/"*" '\
'--exclude /run/"*" '\
'--exclude /sys/"*" '\
'--exclude /lost+found '\
'--exclude /tmp/"*" '\
'--exclude /var/tmp/"*" '\
'--exclude /home/user/'

# check where we are
echo "Testing connection..."
if rdiff-backup --test-server $user@$server_athome::/ignored &> /dev/null; then
    echo "We're at home, doing a full backup."
    at_home=true
    server=$server_athome
elif rdiff-backup --test-server $user@$server_away::/ignored &> /dev/null; then
    echo "We're away; backing up /home."
    at_home=false
    server=$server_away
else
    echo "Cannot connect to server. Exiting."
    exit 1
fi

# execute backups
# this first one goes no matter what
echo "Executing /home backup..."
rdiff-backup $args$args_home $sourcedir_home $user@$server::$backupdir_home
echo "/home backup successful."

# run 2 if we have the bandwidth
if at_home == true; then
    echo "Backing up MBR..."
    dd if=$disk of=/mbr.bak bs=512 count=1
    echo "MBR Backed up."
    echo "Executing full system backup..."
    rdiff-backup $args$args_full $sourcedir_full $user@$server::$backupdir_full
    echo "Full system backup successful."
else; exit
fi

