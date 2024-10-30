#!/usr/bin/env bash

set -o nounset
set -o errexit

http_host=${S3_URL#*//}
http_host=${http_host%:*}
http_request_date=$(date -R)

echo "Download TrueNAS pxm-odin config file ..."
config_filename="pxm-odin-$(date "+%Y%m%d-%H%M%S").tar"
http_filepath="truenas-backup/${config_filename}"
http_signature=$(
    printf "PUT\n\napplication/tar\n%s\n/%s" "${http_request_date}" "${http_filepath}" \
        | openssl sha1 -hmac "${AWS_SECRET_ACCESS_KEY}" -binary \
        | base64
)
curl -k -X 'POST' \
  "${TRUENAS_PXM_ODIN_URL}/api/v2.0/config/save" \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' --user "${TRUENAS_USER}:${TRUENAS_PASS}" --output "/tmp/${config_filename}"

echo "Upload backup to s3 bucket ..."
curl -fsSL \
    -X PUT -T "/tmp/${config_filename}" \
    -H "Host: ${http_host}" \
    -H "Date: ${http_request_date}" \
    -H "Content-Type: application/tar" \
    -H "Authorization: AWS ${AWS_ACCESS_KEY_ID}:${http_signature}" \
    "${S3_URL}/${http_filepath}"

echo "Download TrueNAS proxmox config file ..."
config_filename="proxmox-$(date "+%Y%m%d-%H%M%S").tar"
http_filepath="truenas-backup/${config_filename}"
http_signature=$(
    printf "PUT\n\napplication/tar\n%s\n/%s" "${http_request_date}" "${http_filepath}" \
        | openssl sha1 -hmac "${AWS_SECRET_ACCESS_KEY}" -binary \
        | base64
)
curl -k -X 'POST' \
  "${TRUENAS_PROXMOX_URL}/api/v2.0/config/save" \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' --user "${TRUENAS_USER}:${TRUENAS_PASS}" --output "/tmp/${config_filename}"

echo "Upload backup to s3 bucket ..."
curl -fsSL \
    -X PUT -T "/tmp/${config_filename}" \
    -H "Host: ${http_host}" \
    -H "Date: ${http_request_date}" \
    -H "Content-Type: application/tar" \
    -H "Authorization: AWS ${AWS_ACCESS_KEY_ID}:${http_signature}" \
    "${S3_URL}/${http_filepath}"
