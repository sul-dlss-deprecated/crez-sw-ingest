#!/bin/bash
# index_latest
# Index the latest course reserve data file (already pulled) 
# Naomi Dushay 2012-04-26

LANG="en_US.UTF-8"
export LANG

CODE_DIR="/home/blacklight/crez-sw-ingest"

# move to code directory to get correct rvm dir
cd $CODE_DIR
source /usr/local/rvm/scripts/rvm

LOCAL_DATA_DIR="/data/sirsi/crez"

FULL_DATA_FILE_NAME=$(ls -t $LOCAL_DATA_DIR/reserves-data.* | head -1)
FILE=${FULL_DATA_FILE_NAME##*/}

LOG_FILE=$LOCAL_DATA_DIR/logs/$FILE.log
#echo $LOG_FILE

$($CODE_DIR/bin/crez-sw-ingest $@ $LOCAL_DATA_DIR/$FILE &>$LOG_FILE)
#$(mail -s "$FILE update" sulcirchelp@stanford.edu, dlrueda@stanford.edu, searchworks-reports@lists.stanford.edu < $LOG_FILE)
