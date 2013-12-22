#! /bin/bash
# pull_and_ix_latest_w_passwd
# pull the latest course reserve data file from bodoni with password prompts
#  and index that file
# If we already have the latest file on bodoni, do nothing.
# Naomi Dushay 2012-03-23

REMOTE_DATA_DIR=/s/SUL/Dataload/SearchworksReserves/Data

#LOCAL_DATA_DIR=/data/sirsi/crez
LOCAL_DATA_DIR=../data

FULL_REMOTE_FILE_PATH="$(ssh sirsi@bodoni ls -t $REMOTE_DATA_DIR/reserves-data.* | head -1)"
FILE="$(basename $FULL_REMOTE_FILE_PATH)"

if [ -r $LOCAL_DATA_DIR/$FILE ]; 
then
  echo "already have latest data: $FILE"
  exit 1
else
  scp -p sirsi@bodoni:$FULL_REMOTE_FILE_PATH $LOCAL_DATA_DIR	
  ruby bin/crez-sw-ingest $* $LOCAL_DATA_DIR/$FILE &>$LOCAL_DATA_DIR/logs/$FILE.log
  exit 0
fi

