#!/bin/bash
set -e

export AZ_CONTAINER_NAME=${AZ_CONTAINER_NAME:-}
export AZURE_STORAGE_ACCOUNT=$(cat /etc/backup-secrets/azure-cloud-storage-key | cut -d ":" -f1)
export AZURE_STORAGE_KEY=$(cat /etc/backup-secrets/azure-cloud-storage-key | cut -d ":" -f2)

if [[ -z ${AZURE_STORAGE_ACCOUNT} || -z ${AZURE_STORAGE_KEY} || -z ${AZ_CONTAINER_NAME} ]]; then
  ERROR="Please configure azure connection."
fi

if [[ ! -z ${ERROR} ]]; then
  echo "ERROR: ${ERROR}"
  echo "  Required environment parameters:"
  echo "  - AZ_CONTAINER_NAME - azure container name"
  echo "  Configuration files:"
  echo "  - /etc/backup-secrets/azure-cloud-storage-key - s3 passwd formatted file with Azure credentials, access_key:secret_key, mandatory"
  echo "  - /etc/backup-secrets/database-password - password to access DBs, can be specified also by MYSQL_PSWD var, mandatory"
  exit 1
fi

echo "Syncing..."
az storage blob upload-batch -d ${AZ_CONTAINER_NAME} -s ${ARCHIVE_PATH}/
echo "Synced."

echo "Setting Archive tier for synced files..."
idx=1
az storage blob list --container-name ${AZ_CONTAINER_NAME} --query "[?properties.blobTier!='Archive'].name" -o tsv --num-results "*" | while read -r f; do echo "$idx - $f" && idx=$[$idx+1] && az storage blob set-tier --container-name ${AZ_CONTAINER_NAME} --name "$f" --tier Archive --verbose; done
echo "Done."

LMT=$(date -d "-$[${BACKUP_DAYS}-1] days" '+%Y-%m-%dT%H:%MZ' | sed 's/\s$//')
echo "Keep only backup after $LMT..."

echo "Counting .sha256 backups with LastModified >= $LMT..."
HASH_COUNT=$(az storage blob list --container-name ${AZ_CONTAINER_NAME} --query "[?contains(name,'.sha256')].name" -o tsv --num-results "*" | wc -l)

if [[ ${HASH_COUNT} -lt ${BACKUP_DAYS} ]]; then
  echo "Found < ${BACKUP_DAYS} hash files, nothing to delete yet, will delete once ${BACKUP_DAYS} valid backups appear."
  exit 0
fi

echo "Deleting backups with LastModified < $LMT..."
az storage blob delete-batch -s ${AZ_CONTAINER_NAME} --if-unmodified-since $LMT
echo "Deleted."