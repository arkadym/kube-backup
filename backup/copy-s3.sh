#!/bin/bash
set -e

S3_BUCKET_NAME=${S3_BUCKET_NAME:-}
S3_REGION_NAME=${S3_REGION_NAME:-}
S3_ENDPOINT=${S3_ENDPOINT:-}

export AWS_ACCESS_KEY_ID=$(cat /etc/backup-secrets/s3-cloud-storage-key | cut -d ":" -f1)
export AWS_SECRET_ACCESS_KEY=$(cat /etc/backup-secrets/s3-cloud-storage-key | cut -d ":" -f2)
export AWS_DEFAULT_REGION=$S3_REGION_NAME

if [[ -z ${S3_BUCKET_NAME} || -z ${S3_REGION_NAME} || -z ${AWS_ACCESS_KEY_ID} || -z ${AWS_SECRET_ACCESS_KEY} ]]; then
  ERROR="Please configure s3 connection."
fi

if [[ ! -z ${ERROR} ]]; then
  echo "ERROR: ${ERROR}"
  echo "  Required environment parameters:"
  echo "  - BACKUP_PATHS - space separated folders where are mounted files for backup, optional"
  echo "  - S3_BUCKET_NAME, S3_REGION_NAME - AWS S3 bucket information"
  echo "  Configuration files:"
  echo "  - /etc/backup-secrets/s3-cloud-storage-key - s3 passwd formatted file with AWS S3 credentials, access_key:secret_key, mandatory"
  echo "  - /etc/backup-secrets/database-password - password to access DBs, can be specified also by MYSQL_PSWD var, mandatory"
  exit 1
fi

OPT_ENDPOINT=
if [[ ! -z ${S3_ENDPOINT} ]]; then
  OPT_ENDPOINT="--endpoint-url=${S3_ENDPOINT}"
fi
echo "OPT_ENDPOINT=$OPT_ENDPOINT"

echo "Syncing..."
aws s3 $OPT_ENDPOINT cp ${ARCHIVE_PATH} s3://${S3_BUCKET_NAME} --recursive
echo "Synced."

echo "Listing..."
aws s3 $OPT_ENDPOINT ls s3://${S3_BUCKET_NAME}
echo "Listed."

LMT=$(date -d "-$[${BACKUP_DAYS}-1] days" +%Y-%m-%d | sed 's/\s$//')
echo "Keep only backup after $LMT..."

echo "Counting .sha256 backups with LastModified >= $LMT..."
HASH_COUNT=$(aws s3api list-objects --bucket ${S3_BUCKET_NAME} --query "Contents[?LastModified >= '$LMT' && contains(Key,'.sha256')]" --output text | wc -l)

if [[ ${HASH_COUNT} -lt ${BACKUP_DAYS} ]]; then
  echo "Found < ${BACKUP_DAYS} hash files, nothing to delete yet, will delete once ${BACKUP_DAYS} valid backups appear."
  exit 0
fi

echo "Deleting backups with LastModified < $LMT..."
FILES_TO_DELETE=$(aws s3api list-objects --bucket ${S3_BUCKET_NAME} --query "Contents[?LastModified < '$LMT'].Key" --output text)
for FILE_TO_DELETE in $FILES_TO_DELETE; do
  echo " - Deleting ${FILE_TO_DELETE}..."
  aws s3api $OPT_ENDPOINT delete-object --bucket ${S3_BUCKET_NAME} --key ${FILE_TO_DELETE} --output text
done