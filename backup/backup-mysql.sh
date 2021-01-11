#!/bin/bash
set -e

# requires following env variables
# - ARCHIVE_PATH - where to store .tar.gz files
# - DT - date/time to be add into .tar.gz name
# mysql db parameters
# - MYSQL_DBS - (optional) space separated DBs list, if not specified - nothing will do
# - MYSQL_SERVER - (optional) fqdn or IP of mysql server, if not specified - localhost will be use
# - MYSQL_PORT - (optional) mysql server' port
# - MYSQL_USER & MYSQL_PSWD - user/password for mysql server

if [[ ! -z ${MYSQL_DBS} ]]; then
  echo "MySQL_DBs specified - ${MYSQL_DBS}, preparing to backup..."

  # lookup MYSQL_PSWD configuration in secrets volume
  if [[ -z ${MYSQL_PSWD} && -f /etc/backup-secrets/database-password ]]; then
    MYSQL_PSWD=$(cat /etc/backup-secrets/database-password)
  fi

  if [[ -z ${MYSQL_USER} || -z ${MYSQL_PSWD} ]]; then
    echo "ERROR: Please setup MYSQL_USER and MYSQL_PSWD variables, or map /etc/backup-secrets/database-password file"
    exit 1
  fi

cat > .my.cnf << EOF
[mysqldump]
password=${MYSQL_PSWD}
EOF
 
  if [[ ! -z ${MYSQL_PORT} && ${MYSQL_PORT} -gt 0 ]]; then
    MYSQL_PORT="-P ${MYSQL_PORT}"
    echo " - Port specified - ${MYSQL_PORT}"
  else
    echo " - No MYSQL_PORT specified, ignoring..."
  fi

  SERVERNAME=$(hostname)
  if [[ -z ${MYSQL_SERVER} ]]; then
    echo " - No MYSQL_SERVER specified, using localhost - ${SERVERNAME}"
  else
    if [[ ${MYSQL_SERVER} != "localhost" ]]; then
      SERVERNAME=${MYSQL_SERVER}
    fi
    MYSQL_SERVER="-h ${SERVERNAME}"
    echo " - MYSQL_SERVER specified, using it - ${MYSQL_SERVER}"
  fi
  
  echo "Starting backup databases..."
  for MYSQL_DB in ${MYSQL_DBS}; do
    echo " - ${MYSQL_DB}..."
    mysqldump --defaults-file=.my.cnf ${MYSQL_PORT} ${MYSQL_SERVER} -u ${MYSQL_USER} ${MYSQL_DB} | gzip > ${ARCHIVE_PATH}/${SERVERNAME}-${MYSQL_DB}-${DT}-sql.gz
  done
  echo "Finished backup databases."
fi