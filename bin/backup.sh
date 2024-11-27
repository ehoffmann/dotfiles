#!/bin/bash

PID_FILE=/tmp/my_backup.pid

find_last_complete_backup () {
  for dir in $(find $1 -maxdepth 1 -type d -name 'manu-*' | sort -r)
  do
    if [ -f "$dir/completed_at.txt" ] && [ -d "$dir/manu" ]; then
      echo -n $dir
      return
    fi
  done
}

echo "Backup started at $(date +%Y-%m-%d-%H:%M:%S)"

if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  if ps -p $PID > /dev/null 2>&1; then
    echo "Backup already running with PID $PID, exiting."
    echo "---"
    exit
  else
    echo "Stale PID file found. Removing it."
    rm "$PID_FILE"
  fi
fi
echo $$ > $PID_FILE

BACKUP_FOLDERS=(
  "/media/manu/backup1"
  "/media/manu/backup2"
  "/media/manu/backup3"
  "/media/manu/backup4"
)

for BACKUP_FOLDER in "${BACKUP_FOLDERS[@]}"; do
  if [ -d "$BACKUP_FOLDER" ]; then
    echo "Backup folder $BACKUP_FOLDER exists. Running backup..."
    DEST="$BACKUP_FOLDER/manu-$(date +%Y-%m-%d-%H-%M)"
    mkdir $DEST
    LAST_BKP=$(find_last_complete_backup $BACKUP_FOLDER)
    if [ -d "$LAST_BKP" ]; then
      OPTS="--link-dest $LAST_BKP"
    fi
    # CMD="time rsync $OPTS --delete -az --stats --include=\".password-store\" --exclude=\".*\" --exclude=tmp/ --exclude=data/ /home/manu \"$DEST\""
    CMD="time rsync $OPTS --delete -azh --info=progress2 --info=name0 --stats --include=\".password-store\" --exclude=\".*\" --exclude=tmp/ --exclude=botros-assets/ --exclude=data/ /home/manu \"$DEST\""
    echo "$CMD"
    eval $CMD
    echo "$(date +%Y-%m-%d-%H-%M-%S)" > $DEST/completed_at.txt
  else
    echo "No folder $BACKUP_FOLDER, skipping..."
  fi
done
echo "---"
rm -f $PID_FILE
