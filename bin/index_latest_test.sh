#! /bin/bash
# index_latest_test.sh
#  run this script with  "source (script)" or ". (script)"  so all commands are executed as part of the same shell 
# Index the latest course reserve data file (already pulled) 
# Naomi Dushay 2012-04-26

JRUBY_OPTS="--1.9"
export JRUBY_OPTS
LANG="en_US.UTF-8"
export LANG

CODE_DIR="/Users/ndushay/searchworks/course-rez/crez-sw-ingest"

# move to code directory to get correct rvm dir
cd $CODE_DIR
source $CODE_DIR/.rvmrc; ruby -v
#pwd
ruby -v

LOCAL_DATA_DIR="/Users/ndushay/searchworks/course-rez/data"

FULL_DATA_FILE_NAME=$(ls -t $LOCAL_DATA_DIR/reserves-data.* | head -1)
FILE=${FULL_DATA_FILE_NAME##*/}
LOG_FILE=$LOCAL_DATA_DIR/logs/$FILE.log
echo $LOG_FILE

$($CODE_DIR/bin/crez-sw-ingest $@ $LOCAL_DATA_DIR/$FILE &>$LOG_FILE)
#$(mail -s '$FILE update' ndushay@stanford.edu < $LOG_FILE)
