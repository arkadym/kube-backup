#!/bin/bash
set -e

RSYNC_PATH=${RSYNC_PATH:-}

if [[ -z ${RSYNC_PATH} ]]; then
  ERROR="Please configure rsync path connection."
fi

[ -d ${RSYNC_PATH} ] || mkdir -p ${RSYNC_PATH}

if [[ ! -z ${ERROR} ]]; then
  echo "ERROR: ${ERROR}"
  echo "  Required environment parameters:"
  echo "  - BACKUP_PATHS - space separated folders where are mounted files for backup, optional"
  echo "  - RSYNC_PATH - Destination path for Rsync"
  exit 1
fi

echo "Syncing..."
rsync -aiv ${ARCHIVE_PATH} ${RSYNC_PATH}
echo "Synced."

LMT=$(date -d "-$[${BACKUP_DAYS}-1] days" +%Y-%m-%d | sed 's/\s$//')
echo "Keep only backup after $LMT..."

echo "Counting .sha256 backups with LastModified >= $LMT..."
HASH_COUNT=$(find ${RSYNC_PATH} -type f -name '*.sha256' -mtime +${BACKUP_DAYS} -exec echo {} \; | wc -l)

if [[ ${HASH_COUNT} -lt ${BACKUP_DAYS} ]]; then
  echo "Found < ${BACKUP_DAYS} hash files, nothing to delete yet, will delete once ${BACKUP_DAYS} valid backups appear."
  exit 0
fi

echo "Deleting backups with LastModified < $LMT..."
FILES_TO_DELETE=$(find ${RSYNC_PATH} -type f -name '*' -mtime +${BACKUP_DAYS} -exec echo {} \;)
for FILE_TO_DELETE in $FILES_TO_DELETE; do
  echo " - Deleting ${FILE_TO_DELETE}..."
  rm -f ${FILE_TO_DELETE}
done