#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

CERT_DIR=/etc/ssl/ukrgb/letsencrypt
CERT_DATE=$(date +%Y-%m-%d)

ARN=$(aws acm import-certificate \
	--certificate file://${CERT_DIR}/cert.pem \
	--certificate-chain file://${CERT_DIR}/fullchain.pem \
	--private-key file://${CERT_DIR}/key.pem \
	--profile certMgr \
	--output text)

echo "Imported"
echo "$ARN"

aws acm add-tags-to-certificate --certificate-arn "${ARN}" --tags "Key=Name,Value=LetsEncrypt-${CERT_DATE}" --profile=certMgr

