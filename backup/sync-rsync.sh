#!/bin/bash
set -e

BACKUP_PATH=${BACKUP_PATHS:-}
RSYNC_PATH=${RSYNC_PATH:-}

if [[ -z ${BACKUP_PATHS} || -z ${RSYNC_PATH} ]]; then
  ERROR="Please configure backup path."
fi

if [[ -z ${RSYNC_PATH} ]]; then
  ERROR="Please configure rsync path."
fi

if [[ ! -z ${ERROR} ]]; then
  echo "ERROR: ${ERROR}"
  echo "  Required environment parameters:"
  echo "  - BACKUP_PATHS - path where is mounted files for backup"
  echo "  - RSYNC_PATH - path for rsync target"
  exit 1
fi

OPT_DELETE=
if [[ -f $BACKUP_PATHS/rsync-sync.state ]]; then
  echo "State file exist. Reading last state..."
  CNT_LAST=$(cat $BACKUP_PATHS/rsync-sync.state)
  CNT_CUR=$(find ${BACKUP_PATHS} -type f | wc -l)
  CNT_DIFF=$[$CNT_LAST-$CNT_CUR]
  echo "CNT_DIFF=$CNT_DIFF; CNT_CUR=$CNT_CUR; CNT_LAST=$CNT_LAST"
  if [[ $CNT_DIFF -lt 100 ]]; then
    OPT_DELETE="--delete --delete-after"
  fi
  echo $CNT_CUR > $BACKUP_PATHS/rsync-sync.state
else
  echo "No state file. Initializing it..."
  OPT_DELETE="--delete --delete-after"
  echo 0 > $BACKUP_PATHS/rsync-sync.state
fi
echo "OPT_DELETE=$OPT_DELETE"

echo "Syncing..."
rsync -aiv $OPT_DELETE ${BACKUP_PATHS} ${RSYNC_PATH}
echo "Synced."
