#!/usr/bin/env bash
#
dry_run=""
#dry_run="--dry-run"
profile="developer"
name="Area51-test"
aim_id="ami-09e0d6fdf60750e33"
subnet="subnet-8ffcbbea"
security_group="sg-05bfa9ba4f2b741ed"
#repositiry='https://github.com/markgawler/ukriversguidebook.co.uk.tools/blob/master'
repositiry='https://raw.githubusercontent.com/markgawler/ukriversguidebook.co.uk.tools/master'

function create_cloud_init_script () {
    #local temp_dir=\$(mktemp -d)
    local script_dir='/root/bin'
    cat << EOF >> cloud_init.sh
#!/usr/bin/env bash

mkdir -p "$script_dir"
curl "${repositiry}/misc-scripts/setup/build_site.sh" >  "${script_dir}/build_site.sh"
curl "${repositiry}/misc-scripts/setup/configre_base_system.sh" >  "${script_dir}/configre_base_system.sh"

source "${script_dir}/configre_base_system.sh"
source "${script_dir}/build_site.sh"
EOF
}
rm cloud_init.sh
create_cloud_init_script


id=$(aws ec2 run-instances "$dry_run" \
    --image-id "$aim_id" \
    --count 1 \
    --instance-type t4g.nano\
    --key-name Area51\
    --security-group-ids "$security_group" \
    --subnet-id "$subnet" \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":10,\"DeleteOnTermination\":true}}]" \
    --profile="$profile"  \
    --iam-instance-profile Arn="arn:aws:iam::702054536108:instance-profile/EC2_Production_Access" \
    --user-data file://cloud_init.sh \
    --query 'Instances[*].InstanceId' --output text
    )
echo "Created: $id"

aws ec2 create-tags "$dry_run" \
    --resources "$id" \
    --tags Key=Name,Value="$name" \
    --profile="$profile"

public_ip=$(aws ec2 describe-instances --profile=$profile --instance-ids "$id"  --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
echo "IP Address: $public_ip"