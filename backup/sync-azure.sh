#!/bin/bash
set -e

BACKUP_PATH=${BACKUP_PATHS:-}

if [[ -z ${BACKUP_PATHS} ]]; then
  ERROR="Please configure backup path."
fi

export AZ_CONTAINER_NAME=${AZ_CONTAINER_NAME:-}
export AZURE_STORAGE_ACCOUNT=$(cat /etc/backup-secrets/azure-cloud-storage-key | cut -d ":" -f1)
export AZURE_STORAGE_KEY=$(cat /etc/backup-secrets/azure-cloud-storage-key | cut -d ":" -f2)

if [[ -z ${AZURE_STORAGE_ACCOUNT} || -z ${AZURE_STORAGE_KEY} || -z ${AZ_CONTAINER_NAME} ]]; then
  ERROR="Please configure azure connection."
fi

if [[ ! -z ${ERROR} ]]; then
  echo "ERROR: ${ERROR}"
  echo "  Required environment parameters:"
  echo "  - BACKUP_PATHS - path where is mounted files for backup"
  echo "  - AZ_CONTAINER_NAME - azure container name"
  echo "  Configuration files:"
  echo "  - /etc/backup-secrets/azure-cloud-storage-key - s3 passwd formatted file with Azure credentials, access_key:secret_key, mandatory"
  exit 1
fi

# EXPIRY_TIME=$(date -u -d "1 days" '+%Y-%m-%dT%H:%MZ' | sed 's/\s$//')
# echo "Generating SAS..."
# SAS_TOKEN=$(az storage container generate-sas --name ${AZ_CONTAINER_NAME} --permission acdlrw --expiry "${EXPIRY_TIME}" | sed 's/"//g')
# DEST_PATH="https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZ_CONTAINER_NAME}?${SAS_TOKEN}"
# echo "Destination url - ${DEST_PATH}"

echo "Syncing..."
az storage blob sync -c ${AZ_CONTAINER_NAME} -s "${BACKUP_PATHS}/"
# #azcopy sync "${BACKUP_PATHS}/" "${DEST_PATH}" --delete-destination=true
echo "Synced."

# echo "Setting Archive tier for synced files..."
# az storage blob list --container-name ${AZ_CONTAINER_NAME} --query "[?properties.blobTier!='Archive'].name" -o tsv --num-results "*" | while read -r f; do echo "$f" && az storage blob set-tier --container-name ${AZ_CONTAINER_NAME} --name "$f" --tier Archive --verbose; done
# echo "Set Archive tier finished."

pwsh -f ./sync-azure.ps1
