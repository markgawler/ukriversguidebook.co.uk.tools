#!/usr/bin/env bash
#
host_name="dev-area51.ukriversguidebook.co.uk"
profile="developer"

mode=toggle
instance_name="Area51"
while [[ $# -gt 0 ]]; do
	key=$1
	case $key in
		--stop)
			mode=stop
			shift
			;;
		--start)
			mode=start
			shift
			;;
		--toggle)
			mode=toggle
			shift
			;;
		--name=*)
			name=${key#*=}
			if [ "$name" == "" ]; then
				echo "$0: A name must be specified with theh '--name' switch."
			else
				instance_name=$name
			fi
			shift
			;;
		--help)
			echo "  --start"
			echo "  --stop"
			echo "  --toggle, Stop if started, Start if stoped"
			echo "  --name=<instance Nameed>, Default Area51"
			echo ""
			exit
			;;
		*)  # unknown option
			echo "$0: unrecognised option '$key'"
			echo "Try '$0 --help' for more information."
			exit
			;;
	esac
done

function get_instance_by_name() {
	local name=$1
	aws ec2 describe-instances --profile=$profile  --output text --filters "Name=tag:Name,Values=$name" --query 'Reservations[*].Instances[*].InstanceId'
}

function get_state() {
	aws ec2 describe-instances --profile=${profile} --instance-ids "${instance}" --query 'Reservations[*].Instances[*].State.Name' --output text
}

function wait() {
	echo "Waiting..."
	instance_state=$(get_state)

	while [ "$instance_state" ==  "pending" ] || [ "$instance_state" ==  "stopping" ]
	do
		sleep 1
		instance_state=$(get_state)
		echo " ${instance_state}"
	done
	echo "Instance State: ${instance_state}"
}

function start_instance() {
	sudo ls /dev/null > /dev/null # hack to make the sudo password prompt happen at the start of the script

	echo "Instance State: ${instance_state}"
	if [ "$instance_state" == "stopped" ]; then
		echo "Starting instance"
		aws ec2 start-instances --profile=${profile} --instance-ids "${instance}"  --output text
		wait 
	fi

	public_ip=$(aws ec2 describe-instances --profile=${profile} --instance-ids "${instance}"  --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)

	# Ass fost and public ID in to the local host file.
	# Remove any previous entry
	sudo sed -ie "/[[:space:]]${host_name}/d" "/etc/hosts";
	printf "%s\t%s\n" "${public_ip}" "${host_name}" | sudo tee -a /etc/hosts > /dev/null;
	echo "Host file updated, Public IP: ${public_ip}"
}

function stop_instance() {
	echo "Stopping instance"
	aws ec2 stop-instances --instance-ids "${instance}" --profile=${profile} --output text
	wait
}

instance=$(get_instance_by_name "$instance_name")
if [ "$instance" == "" ]; then
	echo "$0: Unknown Inastance name: $instance_name"
	exit
fi
echo "Instance Name: $instance_name, Instance Id: $instance, Action: $mode"

instance_state=$(get_state)
case $instance_state in
	pending|stopping)
		echo "Busy.. $instance_state"
		exit
		;;
	running)
		if [ "$mode" == "stop" ] || [ "$mode" == "toggle" ] ; then
			stop_instance
		elif [ "$mode" == "start" ]; then
			echo "Instance already running"
		fi
		;;
	stopped)
		if [ "$mode" == "start" ] || [ "$mode" == "toggle" ] ; then
			start_instance
		elif [ "$mode" == "stop" ]; then
			echo "Instance already stopped"
		fi
		;;
	*)
		echo "$0: Unexpected start: $instance_state"
		;;
esac
