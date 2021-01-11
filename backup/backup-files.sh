#!/bin/bash
set -e

# requires following env variables
# - ARCHIVE_PATH - where to store .tar.gz files
# - DT - date/time to be add into .tar.gz name
# files backup parameters
# - BACKUP_PATHS - (optional) space separated folders where are mounted files for backup, if not specified - nothing will do
# - EXCLUDE_PATHS - (optional) must have same amount of strings with BACKUP_PATH, space separated, 
# use : to define multiple exclude path per single BACKUP_PATH
# example: BACKUP_PATHS="/path1 /path2" EXCLUDE_PATHS="ex1_1:ex1_2 ex2_1:ex2_2"

if [[ ! -z ${BACKUP_PATHS} ]]; then
  echo "Folders to backup specified - ${BACKUP_PATHS}, preparing to backup..."

  SERVERNAME=$(hostname)
  echo " - Using machine name - ${SERVERNAME}"

  i=1
  for BACKUP_PATH in ${BACKUP_PATHS}; do
    echo " - backupPath: ${BACKUP_PATH}"

    FN=$(echo ${BACKUP_PATH} | sed 's/\//-/g' | sed 's/^-//')
    echo " - backupFile: ${FN}"

    EXCLUDE_PATH=$(echo $EXCLUDE_PATHS | cut -d " " -f $i)
    echo " - excludePath: ${EXCLUDE_PATH}"
        
    EXCLUDE_PARTS=$(echo ${EXCLUDE_PATH} | sed 's/:/\s/g')
    EXCLUDE_PATH=""
    if [[ "${EXCLUDE_PARTS}" != "-" ]]; then
      for EXCLUDE_PART in ${EXCLUDE_PARTS}; do
        EXCLUDE_PATH="${EXCLUDE_PATH} --exclude=${EXCLUDE_PART}"
      done
    fi
    echo " - excludeParam: ${EXCLUDE_PATH}"   

    CMD="tar ${EXCLUDE_PATH} -czf ${ARCHIVE_PATH}/${SERVERNAME}-${FN}-${DT}.tar.gz ${BACKUP_PATH}"
    echo " - cmd: ${CMD}"
    $CMD
    
    i=$[$i+1]
  done
fi

echo "Generating SHA256 hash for created backup files..."
SERVERNAME=$(hostname)
sha256sum $(find ${ARCHIVE_PATH} -type f -name '*.gz') > ${ARCHIVE_PATH}/${SERVERNAME}-${DT}.sha256
cat ${ARCHIVE_PATH}/${SERVERNAME}-${DT}.sha256