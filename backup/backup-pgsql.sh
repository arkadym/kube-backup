#!/bin/bash
set -e

# requires following env variables
# - ARCHIVE_PATH - where to store .tar.gz files
# - DT - date/time to be add into .tar.gz name
# mysql db parameters
# - PGSQL_DBS - (optional) space separated DBs list, if not specified - nothing will do
# - PGSQL_SERVER - (optional) fqdn or IP of mysql server, if not specified - localhost will be use
# - PGSQL_PORT - (optional) mysql server' port
# - PGSQL_USER & PGSQL_PSWD - user/password for mysql server

if [[ ! -z ${PGSQL_DBS} ]]; then
  echo "PostgreSQL_DBs specified - ${PGSQL_DBS}, preparing to backup..."

  # lookup PGSQL_PSWD configuration in secrets volume
  if [[ -z ${PGSQL_PSWD} && -f /etc/backup-secrets/database-password ]]; then
    PGSQL_PSWD=$(cat /etc/backup-secrets/database-password)
  fi

  if [[ -z ${PGSQL_USER} || -z ${PGSQL_PSWD} ]]; then
    echo "ERROR: Please setup PGSQL_USER and PGSQL_PSWD variables, or map /etc/backup-secrets/database-password file"
    exit 1
  fi
 
  if [[ ! -z ${PGSQL_PORT} && ${PGSQL_PORT} -gt 0 ]]; then
    PGSQL_PORT="-p ${PGSQL_PORT}"
    echo " - Port specified - ${PGSQL_PORT}"
  else
    echo " - No PGSQL_PORT specified, ignoring..."
  fi

  SERVERNAME=$(hostname)
  if [[ -z ${PGSQL_SERVER} ]]; then
    echo " - No PGSQL_SERVER specified, using localhost - ${SERVERNAME}"
  else
    if [[ ${PGSQL_SERVER} != "localhost" ]]; then
      SERVERNAME=${PGSQL_SERVER}
    fi
    PGSQL_SERVER="-h ${SERVERNAME}"
    echo " - PGSQL_SERVER specified, using it - ${PGSQL_SERVER}"
  fi

  if [[ ! -z ${PGSQL_PSWD} ]]; then
    echo " - Password specified, setting..."
    PGPASSWORD="${PGSQL_PSWD}"
  fi 

  echo "Starting backup databases..."
  for PGSQL_DB in ${PGSQL_DBS}; do
    echo " - ${PGSQL_DB}..."
    pg_dump -v ${PGSQL_PORT} ${PGSQL_SERVER} -U ${PGSQL_USER} ${PGSQL_DB} | gzip > ${ARCHIVE_PATH}/${SERVERNAME}-${PGSQL_DB}-${DT}-sql.gz
  done
  echo "Finished backup databases."
fi