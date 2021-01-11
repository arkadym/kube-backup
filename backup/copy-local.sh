#!/bin/bash
set -e

LMT=$(date -d "-$[${BACKUP_DAYS}-1] days" +%Y-%m-%d | sed 's/\s$//')
echo "Keep only backup after $LMT..."

echo "Counting .sha256 backups with LastModified >= $LMT..."
HASH_COUNT=$(find ${ARCHIVE_PATH} -type f -name '*.sha256' -mtime +${BACKUP_DAYS} -exec echo {} \; | wc -l)

if [[ ${HASH_COUNT} -lt ${BACKUP_DAYS} ]]; then
  echo "Found < ${BACKUP_DAYS} hash files, nothing to delete yet, will delete once ${BACKUP_DAYS} valid backups appear."
  exit 0
fi

echo "Deleting backups with LastModified < $LMT..."
FILES_TO_DELETE=$(find ${ARCHIVE_PATH} -type f -name '*' -mtime +${BACKUP_DAYS} -exec echo {} \;)
for FILE_TO_DELETE in $FILES_TO_DELETE; do
  echo " - Deleting ${FILE_TO_DELETE}..."
  rm -f ${FILE_TO_DELETE}
done