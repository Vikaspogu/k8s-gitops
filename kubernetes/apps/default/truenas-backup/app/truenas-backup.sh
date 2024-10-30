#!/usr/bin/env bash

set -o nounset
set -o errexit

config_filename="$(date "+%Y%m%d-%H%M%S").xml"

http_host=${S3_URL#*//}
http_host=${http_host%:*}
http_request_date=$(date -R)
http_filepath="truenas-backup/${config_filename}"
http_signature=$(
    printf "PUT\n\ntext/xml\n%s\n/%s" "${http_request_date}" "${http_filepath}" \
        | openssl sha1 -hmac "${AWS_SECRET_ACCESS_KEY}" -binary \
        | base64
)

echo "Download TrueNAS pxm-odin config file ..."
curl -Xk 'POST' \
  "${TRUENAS_PXM_ODIN_URL}/api/v2.0/config/save" \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' -d {"secretseed": true} --user "${TRUENAS_USER}:${TRUENAS_PASS}" --output "/tmp/pxm-odin-${config_filename}"

echo "Upload backup to s3 bucket ..."
curl -fsSL \
    -X PUT -T "/tmp/pxm-odin-${config_filename}" \
    -H "Host: ${http_host}" \
    -H "Date: ${http_request_date}" \
    -H "Content-Type: text/xml" \
    -H "Authorization: AWS ${AWS_ACCESS_KEY_ID}:${http_signature}" \
    "${S3_URL}/${http_filepath}"

echo "Download TrueNAS proxmox config file ..."
curl -Xk 'POST' \
  "${TRUENAS_PXM_ODIN_URL}/api/v2.0/config/save" \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' -d {"secretseed": true} --user "${TRUENAS_USER}:${TRUENAS_PASS}" --output "/tmp/proxmox-${config_filename}"

echo "Upload backup to s3 bucket ..."
curl -fsSL \
    -X PUT -T "/tmp/proxmox-${config_filename}" \
    -H "Host: ${http_host}" \
    -H "Date: ${http_request_date}" \
    -H "Content-Type: text/xml" \
    -H "Authorization: AWS ${AWS_ACCESS_KEY_ID}:${http_signature}" \
    "${S3_URL}/${http_filepath}"
