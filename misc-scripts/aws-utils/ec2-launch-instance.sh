#!/usr/bin/env bash
#

hostname="dev-area51"
domain="ukriversguidebook.co.uk"
profile="developer"
sec_group_name="Area51"
ec2_role="UKRGB-Developer-EC2"
aim_id="ami-09e0d6fdf60750e33" #  Ubuntu Server 20.04 LTS (HVM), SSD Volume Type (64-bit Arm)
subnet="subnet-8ffcbbea"

repositiry='https://raw.githubusercontent.com/markgawler/ukriversguidebook.co.uk.tools/master'
test=false
export_cloud_init=false

while [[ $# -gt 0 ]]; do
	key=$1
	case $key in
		--test)
            # Test mode, don't do anything!
			test=
			shift
			;;
		--hostname=*)
			name=${key#*=}
			if [ "$name" == "" ]; then
				echo "$0: A name must be specified with theh '--name' switch."
			else
				hostname=$name
			fi
			shift
			;;
		--help)
			echo "  --name=<instance Nameed>, Default Area51"
			echo "  --export_cloud_init, Export the cloud_init script"
			echo ""
			exit
			;;
        --export_cloud_init)
            export_cloud_init=
            test=
            shift
            ;;
		*)  # unknown option
			echo "$0: unrecognised option '$key'"
			echo "Try '$0 --help' for more information."
			exit
			;;
	esac
done

function get_security_group() {
    local name=$1
    local count

    id=$(aws ec2 describe-security-groups --filters Name=group-name,Values="$name" --query "SecurityGroups[*].{ID:GroupId}" --profile="$profile" --output=text)
    count=$(wc -w <<< "$id")

    if [ "$count" -gt "1" ]; then
        # Ambigious name
        return 2
    elif [ "$count" -lt "1" ]; then
        # Unknown security Group
        return 1
    else
        echo "$id"
        return 0
    fi

}

function check_role_name() {
    local name=$1
    name=$(aws iam list-roles --profile=developer --query 'Roles[*].{Name:RoleName}' --output=text | grep "$name")

    count=$(wc -w <<< "$name")
    if [ "$count" -gt "1" ]; then
        # Ambigious name
        return 2
    elif [ "$count" -lt "1" ]; then
        # Unknown security Group
        return 1
    else
        echo "$name"
        return 0
    fi
}


function create_cloud_init_script () {
    local cloud_init
    local script_dir='/root/bin'
    #todo: macos dosnt support --suffix
    #cloud_init="$(mktemp --suffix=_cloud-init.sh)"
    cloud_init="$(mktemp)_cloud-init.sh"
    cat << EOF >> "$cloud_init"
#!/usr/bin/env bash

mkdir -p "$script_dir"
curl "${repositiry}/misc-scripts/setup/build_site.sh" >  "${script_dir}/build_site.sh"
curl "${repositiry}/misc-scripts/setup/configre_base_system.sh" >  "${script_dir}/configre_base_system.sh"

source "${script_dir}/configre_base_system.sh"
source "${script_dir}/build_site.sh" --hostname="$hostname"
EOF
    echo "$cloud_init"
}

function create_instance() {
    local sec_group=$1
    local iam_role=$2
    local script
    script="$(create_cloud_init_script)"
   
    id=$(aws ec2 run-instances \
        --image-id "$aim_id" \
        --count 1 \
        --instance-type t4g.nano\
        --key-name Area51\
        --security-group-ids "$sec_group" \
        --subnet-id "$subnet" \
        --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":10,\"DeleteOnTermination\":true}}]" \
        --profile="$profile"  \
        --iam-instance-profile Name="$iam_role" \
        --user-data file://"$script" \
        --query 'Instances[*].InstanceId' --output text
        )
    echo "$id"
    rm "$script"
}

function tag_instance() {
    local instance=$1
    local tag=$2

    aws ec2 create-tags \
        --resources "$instance" \
        --tags Key=Name,Value="$tag" \
        --profile="$profile"
}

function get_ip() {
    local instance=$1
    public_ip=$(aws ec2 describe-instances --profile=$profile --instance-ids "$instance"  --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
    echo "$public_ip"
}
if [ "$export_cloud_init" ]; then
    echo "Export cloud_init script"
    script="$(create_cloud_init_script)"
    echo "$(cat $script)"
    rm $script
    exit
fi
if [ "$test" ]; then
    echo "Main Program"

    if ! iam_role=$(check_role_name $ec2_role) ; then
        echo "$0 Invalid role name: $ec2_role"
        exit 1
    fi
    echo "Role Arn: $iam_role"

    if ! security_group=$(get_security_group "$sec_group_name") ; then
        echo "$0: Invalid security group name $security_group"
        exit 1
    fi
    echo "Security Group: $security_group"

    
    id=$(create_instance "$security_group" "$iam_role")
    echo "Id: $id"
    tag_instance "$id" "$hostname"
    public_ip="$(get_ip "$id")"

    # Add hostname and public ID in to the local host file.
	# Remove any previous entry
    fqn="${hostname}.${domain}"
    echo "Adding host to hostfile..."
	sudo sed -ie "/[[:space:]]$fqn/d" "/etc/hosts";
	printf "%s\t%s\n" "$public_ip" "$fqn" | sudo tee -a /etc/hosts > /dev/null;
	echo "Host file updated, Public IP: $public_ip"
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$fqn"

fi