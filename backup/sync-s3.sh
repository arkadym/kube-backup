#!/bin/bash
set -e

BACKUP_PATH=${BACKUP_PATHS:-}
S3_BUCKET_NAME=${S3_BUCKET_NAME:-}
S3_REGION_NAME=${S3_REGION_NAME:-}

if [[ -z ${BACKUP_PATH} ]]; then
  ERROR="Please configure backup path."
fi

export AWS_ACCESS_KEY_ID=$(cat /etc/backup-secrets/s3-cloud-storage-key | cut -d ":" -f1)
export AWS_SECRET_ACCESS_KEY=$(cat /etc/backup-secrets/s3-cloud-storage-key | cut -d ":" -f2)
export AWS_DEFAULT_REGION=$S3_REGION_NAME

if [[ -z ${S3_BUCKET_NAME} || -z ${S3_REGION_NAME} || -z ${AWS_ACCESS_KEY_ID} || -z ${AWS_SECRET_ACCESS_KEY} ]]; then
  ERROR="Please configure s3 connection."
fi

if [[ ! -z ${ERROR} ]]; then
  echo "ERROR: ${ERROR}"
  echo "  Required environment parameters:"
  echo "  - BACKUP_PATH - path where is mounted files for backup"
  echo "  - S3_BUCKET_NAME, S3_REGION_NAME - AWS S3 bucket information"
  echo "  Configuration files:"
  echo "  - /etc/backup-secrets/s3-cloud-storage-key - s3 passwd formatted file with AWS S3 credentials, access_key:secret_key"
  exit 1
fi

OPT_DELETE=
if [[ -f $BACKUP_PATH/s3-sync.state ]]; then
  echo "State file exist. Reading last state..."
  CNT_LAST=$(cat $BACKUP_PATH/s3-sync.state)
  CNT_CUR=$(find ${BACKUP_PATH} -type f | wc -l)
  CNT_DIFF=$[$CNT_LAST-$CNT_CUR]
  echo "CNT_DIFF=$CNT_DIFF; CNT_CUR=$CNT_CUR; CNT_LAST=$CNT_LAST"
  if [[ $CNT_DIFF -lt 100 ]]; then
    OPT_DELETE=--delete
  fi
  echo $CNT_CUR > $BACKUP_PATH/s3-sync.state
else
  echo "No state file. Initializing it..."
  OPT_DELETE=--delete
  echo 0 > $BACKUP_PATH/s3-sync.state
fi
echo "OPT_DELETE=$OPT_DELETE"

echo "Syncing..."
aws s3 sync ${BACKUP_PATH} s3://${S3_BUCKET_NAME} --exact-timestamps $OPT_DELETE
echo "Synced."
