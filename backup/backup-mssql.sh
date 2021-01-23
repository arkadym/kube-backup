#!/bin/bash
set -e

# requires following env variables
# - ARCHIVE_PATH - where to store .tar.gz files
# - DT - date/time to be add into .tar.gz name
# MSSQL db parameters
# - MSSQL_DBS - (optional) space separated DBs list, if not specified - nothing will do
# - MSSQL_SERVER - (optional) fqdn or IP of MSSQL server, if not specified - localhost will be use
# - MSSQL_PORT - (optional) MSSQL server' port
# - MSSQL_USER & MSSQL_PSWD - user/password for MSSQL server

if [[ ! -z ${MSSQL_DBS} ]]; then
  echo "MSSQL_DBs specified - ${MSSQL_DBS}, preparing to backup..."

  # lookup MSSQL_PSWD configuration in secrets volume
  if [[ -z ${MSSQL_PSWD} && -f /etc/backup-secrets/database-password ]]; then
    MSSQL_PSWD=$(cat /etc/backup-secrets/database-password)
  fi

  if [[ -z ${MSSQL_USER} || -z ${MSSQL_PSWD} ]]; then
    echo "ERROR: Please setup MSSQL_USER and MSSQL_PSWD variables, or map /etc/backup-secrets/database-password file"
    exit 1
  fi

  SQLCMDPASSWORD=$MSSQL_PSWD
  
  SERVERNAME=$(hostname)
  if [[ -z ${MSSQL_SERVER} ]]; then
    echo " - No MSSQL_SERVER specified, using localhost - ${SERVERNAME}"
  else
    if [[ ${MSSQL_SERVER} != "localhost" ]]; then
      SERVERNAME=${MSSQL_SERVER}
    fi
    MSSQL_SERVER="${SERVERNAME}"
    echo " - MSSQL_SERVER specified, using it - ${MSSQL_SERVER}"
  fi

  if [[ ! -z ${MSSQL_PORT} && ${MSSQL_PORT} -gt 0 ]]; then
    MSSQL_SERVER="$MSSQL_SERVER,${MSSQL_PORT}"
    echo " - Port specified - ${MSSQL_PORT}"
  else
    echo " - No MSSQL_PORT specified, ignoring..."
  fi
  
  echo "Starting backup databases..."
  for MSSQL_DB in ${MSSQL_DBS}; do
    echo " - ${MSSQL_DB}..."
    sqlcmd -S ${MSSQL_SERVER} -U ${MSSQL_USER} -Q "BACKUP DATABASE [${MSSQL_DB}] TO DISK = N'${ARCHIVE_PATH}/${SERVERNAME}-${MSSQL_DB}-${DT}-data.bak' WITH NOFORMAT, NOINIT, NAME = '${MSSQL_DB}-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"
    gzip ${ARCHIVE_PATH}/${SERVERNAME}-${MSSQL_DB}-${DT}-data.bak
  done
  echo "Finished backup databases."
fi