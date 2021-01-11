#!/bin/bash
set -e

#export BACKUPNAME=${BACKUP_NAME:-}
export BACKUP_DAYS=${BACKUP_DAYS:-5}

if [[ -z ${BACKUP_NAME} ]]; then
  ERROR="Please configure backup name."
fi

export ARCHIVE_PATH=${ARCHIVE_PATH:-/var/backup}
[ -d ${ARCHIVE_PATH} ] || mkdir -p ${ARCHIVE_PATH}

export DT=$(date +%Y-%m-%d_%H:%M:%S_%Z)

if [[ -z ${ARCHIVE_PATH} ]]; then
  ERROR="ARCHIVE_PATH is undefined."
fi
if [[ -z ${DT} ]]; then
  ERROR="DT is undefined."
fi

BACKUP_MODE=${BACKUP_MODE:-}
S3_BUCKET_NAME=${S3_BUCKET_NAME:-}
AZ_CONTAINER_NAME=${AZ_CONTAINER_NAME:-}
RSYNC_ARCHIVE_PATH=${RSYNC_ARCHIVE_PATH:-}

echo " backupMode = ${BACKUP_MODE}"
echo " S3 bucketName = ${S3_BUCKET_NAME}"
echo " Azure containerName = ${AZ_CONTAINER_NAME}"
echo " RSync path = ${RSYNC_ARCHIVE_PATH}"

if [[ ${BACKUP_MODE} == "backup" ]]; then
  echo " +++ backup MySQL DB"
  ./backup-mysql.sh
  echo " +++ backup Files"
  ./backup-files.sh

  if [[ ! -z ${S3_BUCKET_NAME} ]]; then
    echo " +++ upload to AWS S3"
    ./copy-s3.sh
  fi
  if [[ ! -z ${AZ_CONTAINER_NAME} ]]; then
    echo " +++ upload to Azure Blob"
    ./copy-azure.sh
  fi
  if [[ ! -z ${RSYNC_ARCHIVE_PATH} ]]; then
    echo " +++ copy with RSync"
    ./copy-rsync.sh
  fi
  if [[ -z ${S3_BUCKET_NAME} && -z ${AZ_CONTAINER_NAME} && -z ${RSYNC_ARCHIVE_PATH} ]]; then
    echo " +++ copy as Local"
    ./copy-local.sh
  fi
fi
if [[ ${BACKUP_MODE} == "sync" ]]; then
  if [[ ! -z ${S3_BUCKET_NAME} ]]; then
    echo " +++ sync to AWS S3"
    ./sync-s3.sh
  fi
  if [[ ! -z ${AZ_CONTAINER_NAME} ]]; then
    echo " +++ sync to Azure Blob"
    ./sync-azure.sh
  fi
  if [[ ! -z ${RSYNC_ARCHIVE_PATH} ]]; then
    echo " +++ sync with RSync"
    ./sync-rsync.sh
  fi
fi