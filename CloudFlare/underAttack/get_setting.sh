#!/bin/bash

# This script retrieves the "Under Attack" mode setting from Cloudflare for a specified domain.

# shellcheck source=/dev/null
source .env



echo "Retrieving 'Under Attack' mode setting for Zone ID: $ZONE_ID"
 
# curl --request GET \
#     "https://api.cloudflare.com/client/v4/zones/52ec52eacce4d77db80368c5d7e67172/settings/security_level" \
#     --header "Authorization: Bearer jrKr-NEeVoy_BoZeeJsgHrqMl-BSd3VZv7RqqhCY" \
#     --header "Content-Type: application/json" 


curl --request GET \
    "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings/security_level" \
    --header "Authorization: Bearer $API_TOKEN" \
    --header "Content-Type: application/json" | jq .