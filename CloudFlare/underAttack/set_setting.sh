#!/bin/bash

# This script retrieves the "Under Attack" mode setting from Cloudflare for a specified domain.

# shellcheck source=/dev/null
source .env 
echo "Setting 'Under Attack' mode for Zone ID: $ZONE_ID"
#level="under_attack"
level="high"

curl --request PATCH \
  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings/security_level"\
  --header "Authorization: Bearer $API_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"value": "'$level'"}' | jq .