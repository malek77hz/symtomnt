#!/bin/bash

#   _____   ____  __ _    ___ _  _ _  __  ___   __  __  ___  _   _ _  _ _____ 
#  / __\ \ / /  \/  | |  |_ _| \| | |/ / |_  ) |  \/  |/ _ \| | | | \| |_   _|
#  \__ \\ V /| |\/| | |__ | || .` | ' <   / /  | |\/| | (_) | |_| | .` | | |  
#  |___/ |_| |_|  |_|____|___|_|\_|_|\_\ /___| |_|  |_|\___/ \___/|_|\_| |_|  
#                                                                             
# SYMLINK 2 MOUNT
# v1.0 May 2nd 2016
# by Malek Nasser
# 
# Bash script to search for all symlinks and
# replace with dirs + suffix then mount binds the symlink location
# 
# This is specifily to deal with Docker on Windows and its problem
# with symlinks on host/containers shared drives
# https://forums.docker.com/t/symlinks-on-shared-volumes-not-supported/9288
# 
# Its hopefully something that will not be needed in the future but this may
# still be useful 
# 
# At the moment this just deals with Dirs but could be made to work with actual files
# in which case instead of making a dir and mounting it would simply copy the file
# 
# THe way this works is by searching out all symlinks the docker/vm combo
# has broken, finding out where they are pointing and making a new dir + suffix
# then simply mount binding the location
# 
# The reason I chose this method instead of 
# 1) Simply copying the dirs and 
# 2) Using the same name as the symlink
# is that it does not actually change anything that `git` can see
# However it will mean you need code to trigger when you are in symlink mode
# and mount mode... adjusting name slightly in each case
# 
# As the links are broken instead of finding symlinks with
# <nix>
# find . -type l | while read -r filename ; do
# we have to use
# <win/docker>
# egrep -lir "(\!\<symlink\>)" . | while read -r filename ; do
# 
# Also instead of simply using readfile to get location of the symlink
# We have to use a convoluted method os reading the file, wiping the <symlink> text
# wiping any junk windows crap etc
# 
# ALso when running the docker container you will have to run with --privileged
# 
# docker run --name %NAME% -it --privileged -v %%localdir%%:%%linkdir%% %%imagename%%

if [ $# -ne 1 ]; then
    mode="add"
else
    mode=$1
fi

set -e
SUFFIX="_mnt"
#STORE="./symlinks.txt"
#> $STORE
FINDSYM='<syml'
FINDSYM=$FINDSYM'ink>'
CRAP='M-^?M-~'
#  find . -type l | while read -r filename ; do # <nix>
egrep -lir "(\!$FINDSYM)" . | while read -r filename ; do # <win/docker>
    # reltarget = readfile $filename # <nix>
    myline=$(head -n 1 $filename) # <win/docker>
    linkto=${myline/\!$FINDSYM/}  # <win/docker>
    dir=$(dirname "$filename")
    reltarget=$linkto
    case $reltarget in
        /*) abstarget=$reltarget;;
        *)  abstarget=$dir/$reltarget;;
    esac
    abstarget=$(echo "$abstarget" | cat -v)  # <win/docker>
    abstarget=${abstarget/$CRAP/}  # <win/docker>
    mountname=$filename$SUFFIX

    if [ $mode = "remove" ]; then
        # removing all mounted dirs
        if [ -d "$mountname" ]; then
            echo -e "\e[42mFOUND\e[49m $mountname -> $abstarget"
            absfile=$(echo "$a" | readlink -f $mountname)
            failtrigger=0
            umount $absfile || {
                echo -e "\e[41mCANT UNMOUNT\e[49m"
                failtrigger=1
            }
            rmdir $absfile || {
                echo -e "\e[41mCANT REMOVE\e[49m"
                failtrigger=1
            }
            if [ $failtrigger != 1 ];then
                echo -e "\e[32mSUCCESS\e[39m"
            fi
        else
            echo -e "\e[43mNOT FOUND\e[40m $mountname -> $abstarget"
        fi
    else
         if [ -d "$abstarget" ]; then
            # Normal dir.. do the mount stuff
            echo -e "\e[42mDIR\e[49m $filename -> $abstarget"
            if [ -d "$mountname" ]; then
                echo -e "\e[43mEXISTS\e[49m"
            else
                echo -e "START -> $mountname"
                failtrigger=0
                mkdir $mountname || {
                    echo -e "\e[41mFAILED MKDIR\e[49m"
                }
                mount -o bind $abstarget $mountname || {
                    echo -e "\e[41mFAILED MOUNT\e[49m"
                }
                if [ $failtrigger != 1 ];then
                    echo -e "\e[32mSUCCESS\e[39m"
                fi
            fi
        elif [ -f "$abstarget" ]; then
            echo -e "\e[45mFILE\e[49m $filename -> $abstarget"
            echo -e "\e[35mNOT YET SUPPORTED\e[39m"
            # This is a file, cant help for now
        else
            echo -e "\e[39mUNKNOWN\e[49m $filename -> $abstarget"
            # This is simething else, do nothing
        fi
    fi
done

