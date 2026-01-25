#!/bin/bash
polling_interval=5		# default polling interval in seconds
high_cpu_threshold=25	# The value at which under_attack mode is triggered, must be an integer value between 0 and 100
low_cpu_threshold=15	# The value at which under_attack mode is disabled,	 must be an integer value between 0 and 100
default_security_level="high" # security level to revert to when CPU load is normal
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
# Accepts one optional argument: load average period (1, 5, or 15 minutes)
get_cpu_load() {
	local load_index=${1:-1}  # Default to 1-minute average (index 1), or 5-minute (index 3)
	case $load_index in
		1) load_index=1 ;;  # 1-minute average
		5) load_index=2 ;;  # 5-minute average
		15) load_index=3 ;; # 15-minute average
		*) load_index=1 ;;  # Default to 1-minute average for invalid input
	esac
	local cores load
	if [[ "$OSTYPE" == "darwin"* ]]; then
		# macOS, for testing purposes
		cores=$(sysctl -n hw.logicalcpu)
		load=$(sysctl -n vm.loadavg | awk -v idx="$((load_index + 1))" '{print $idx}')
	else
		# Linux
		cores=$(nproc)
		load=$(awk -v idx="$load_index" '{print $idx}' < /proc/loadavg)
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
		--get-cpu-load=* |--get-cpu-load)
			average=${key#*=}
			# Default to 1-minute average if no value specified
			if [ "$average" == "" ] || [ "$average" == "--get-cpu-load" ]; then
				average=1
			elif [ "$average" != "1" ] && [ "$average" != "5" ] && [ "$average" != "15" ]; then
				echo "$0: Invalid value for '--get-cpu-load'. Valid options are 1 , 5 , or 15."
			fi
			load=$(get_cpu_load "$average")
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
echo  "Starting watcher, polling every $polling_interval seconds"
current_level=$(get_security_level)
echo "Initial security level: $current_level"
while (true)
do
	cpu_load=$(get_cpu_load)
	
	if [ "$cpu_load" -ge "$high_cpu_threshold" ]; then
		if [ "$current_level" != "under_attack" ]; then
			echo "High CPU load detected ($cpu_load%). Setting security level to 'under_attack'."
			set_security_level "under_attack"
			current_level="under_attack"
		fi
	else
		# Check if CPU load has been below the low threshold for one minute and fifteen minutes
		cpu_load_fifteen_min=$(get_cpu_load 15)
		if [ "$cpu_load" -le "$low_cpu_threshold" ] && [ "$cpu_load_fifteen_min" -le "$low_cpu_threshold" ] && [ "$current_level" != "$default_security_level" ]; then
			echo "CPU load back to normal ($cpu_load%). Reverting security level to '$default_security_level'."
			set_security_level "$default_security_level"
			current_level="$default_security_level"
		fi
	fi
	if [ "$verbose" = true ]; then
		if [[ "$OSTYPE" == "darwin"* ]]; then
			# macOS, for testing purposes
			raw_loadavg=$(sysctl -n vm.loadavg )
		else
			# Linux
			raw_loadavg=$(awk '{print $1, $2, $3}' < /proc/loadavg)	
		fi
		echo "CPU load 1min: $cpu_load%, 5min: $cpu_load_fifteen_min%, CF: $current_level, Loadavg: $raw_loadavg"
	fi
	sleep "$polling_interval"
done

