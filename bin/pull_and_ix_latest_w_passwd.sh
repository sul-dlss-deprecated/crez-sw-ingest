#! /bin/bash
# pull_and_ix_latest_w_passwd
# Pull the latest course reserve data file from jenson with password prompts
#  and index that file
# If we already have the latest file on jenson, do nothing.
# Naomi Dushay 2012-03-23

REMOTE_DATA_DIR=/s/Dataload/SearchworksReserves/Data

#LOCAL_DATA_DIR=/data/sirsi/crez
LOCAL_DATA_DIR=../data

FULL_REMOTE_FILE_PATH="$(ssh apache@jenson ls -t $REMOTE_DATA_DIR/reserves-data.* | head -1)"
FILE="$(basename $FULL_REMOTE_FILE_PATH)"

if [ -r $LOCAL_DATA_DIR/$FILE ]; 
then
  echo "already have latest data: $FILE"
  exit 1
else
  scp -p apache@jenson:$FULL_REMOTE_FILE_PATH $LOCAL_DATA_DIR	
  ruby bin/crez-sw-ingest $* $LOCAL_DATA_DIR/$FILE &>$LOCAL_DATA_DIR/logs/$FILE.log
  exit 0
fi

