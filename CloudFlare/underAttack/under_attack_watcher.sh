#!/bin/bash
polling_interval=5		# default polling interval in seconds
high_cpu_threshold=25	# must be an integer value between 0 and 100
default_security_level="high" # security level to revert to when CPU load is normal
sleep_after_change=120	# seconds to wait after changing security level
cloudflare_config="/usr/local/etc/under_attack/cloudflare.config" # path to CloudFlare API config file
verbose=false		# verbose output flag

# Function to get CloudFlare security level
# Returns the current security level as a string
get_security_level() {
    curl --request GET \
        "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings/security_level" \
        --header "Authorization: Bearer $API_TOKEN" \
        --header "Content-Type: application/json" 2>/dev/null | jq -r '.result.value'
}

# Function to set CloudFlare security level
# Accepts one argument: the desired security level
# Returns the new security level if successful, or an error message
# Example levels: "off", "low", "medium", "high", "under_attack"
set_security_level() {
	local level=$1
	curl --request PATCH \
		"https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings/security_level" \
		--header "Authorization: Bearer $API_TOKEN" \
		--header "Content-Type: application/json" \
		--data "{\"value\":\"$level\"}" 2>/dev/null | jq -r '.result.value'
}

# Function to get current CPU load percentage, normalized by number of CPU cores
# Returns an integer value between 0 and 100
get_cpu_load() {
	if [[ "$OSTYPE" == "darwin"* ]]; then
		# macOS, for testing purposes
		cores=$(sysctl -n hw.logicalcpu)
		load=$(sysctl -n vm.loadavg | awk '{print $2}')
	else
		# Linux
		cores=$(nproc)
		load=$(awk '{print $1}' < /proc/loadavg)
	fi
	awk -v c="${cores}" -v l="${load}" 'BEGIN{print l*100/c }' <<< "${load}" | awk '{printf "%.0f", $0}'
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
	key=$1
	case $key in
		--cf-config=*)
			cloudflare_config=${key#*=}
			shift
			;;
		--get-security-level)
			level=$(get_security_level)
			echo "Current security level: $level"
			exit 0
			;;
		--set-security-level=*)
			level=${key#*=}
			if [ "$level" == "" ]; then
				echo "$0: A security level must be specified with the '--set-security-level' switch."
			else
				result=$(set_security_level "$level")
				if [ "$result" == "$level" ]; then
					echo "Security level successfully set to: $result"
				else
					echo "Failed to set security level. Result: $result"
				fi
			fi
			exit 0
			;;
		--get-cpu-load)
			load=$(get_cpu_load)
			echo "Current CPU load: $load"
			exit 0
			;;
		--high-cpu-threshold=*)
			threshold=${key#*=}
			if [ "$threshold" == "" ]; then
				echo "$0: A threshold value must be specified with the '--high-cpu-threshold' switch."
			else
				high_cpu_threshold=$threshold
			fi
			shift
			;;
        --poll=*)
            interval=${key#*=}
			if [ "$interval" == "" ]; then
				echo "$0: A interval must be specified with the '--poll' switch."
			else
				polling_interval=$interval
			fi
			shift
            ;;
		--verbose)
			verbose=true
			shift
			;;
		--help)
			echo "  --get-security-level          Get the CloudFlare security level "
			echo "  --set-security-level=<level>  Set the CloudFlare security level (options: 'off', 'low', 'medium', 'high', 'under_attack')"
			echo "  --poll=<seconds>              Polling interval in seconds (default: 10s)"
			echo "  --cf-config=<path>            Path to CloudFlare API config file (default: /usr/local/etc/under_attack/cloudflare.config)"
			echo "  --high-cpu-threshold=<value>  CPU load percentage threshold to trigger 'Under Attack' mode (default: 30%)"
			echo "  --get-cpu-load                Get the current CPU load percentage"
			exit
			;;
		*)  # unknown option
			echo "$0: unrecognized option '$key'"
			echo "Try '$0 --help' for more information."
			exit
			;;
	esac
done

# Load CloudFlare API config and validate
if [ ! -f "$cloudflare_config" ]; then
	echo "Error: CloudFlare config file '$cloudflare_config' not found."
	exit 1
fi
# shellcheck source=/dev/null
if ! source "$cloudflare_config"; then
	echo "Error: Failed to source CloudFlare config file '$cloudflare_config'."
	exit 1
fi
# Check if required values are set in the config file
if [[ -z "$API_TOKEN" || -z "$ZONE_ID" ]]; then
	echo "Error: API_TOKEN and ZONE_ID must be set in the CloudFlare config file."
	exit 1
fi


# Main watcher loop
#
#logger -p user.info "Starting watcher, polling every $polling_interval seconds"
echo  "Starting watcher, polling every $polling_interval seconds"
current_level=$(get_security_level)
echo "Initial security level: $current_level"
while (true)
do
	cpu_load=$(get_cpu_load)
	if [ "$verbose" = true ]; then
		echo "Current CPU load: $cpu_load%"
	fi
	if [ "$cpu_load" -ge "$high_cpu_threshold" ]; then
		if [ "$current_level" != "under_attack" ]; then
			echo "High CPU load detected ($cpu_load%). Setting security level to 'under_attack'."
			set_security_level "under_attack"
			current_level="under_attack"
			sleep "$sleep_after_change"
		fi
	else
		if [ "$current_level" != "$default_security_level" ]; then
			echo "CPU load normal. Setting security level to '$default_security_level'."
			set_security_level "$default_security_level"
			current_level="$default_security_level"
		fi
	fi
	sleep "$polling_interval"
done

