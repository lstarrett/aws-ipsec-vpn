#!/bin/bash
#
# Author(s): Lucas Starrett (lucas.c.starrett@gmail.com)
#
# This script launches an Ubuntu 16.04 LTS t2.micro EC2 instance and installs a libreswan IPSec
# VPN server on it that may be used to tunnel traffic through geographic region in which EC2 instance
# resides.
#
# This script is intended to be single click, dead simple use.
#

CONFIG=`cat config.json`

VPN_CREATE_SCRIPT=`echo $CONFIG | jq -r '.vpn_create_script_path'`
REGION=`echo $CONFIG | jq -r '.aws_region'`
PROFILE=`echo $CONFIG | jq -r '.aws_profile'`
USERNAME=`echo $CONFIG | jq -r '.ipsec_username'`
PASSWORD=`echo $CONFIG | jq -r '.ipsec_password'`
PSK=`echo $CONFIG | jq -r '.ipsec_psk'`

# check for dependencies
command -v aws >/dev/null 2>&1 || { echo >&2 "Dependency 'awscli' required, please install before continuing. Aborting."; exit 1; }
command -v perl >/dev/null 2>&1 || { echo >&2 "Dependency 'perl' required, please install before continuing. Aborting."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "Dependency 'jq' required, please install before continuing. Aborting."; exit 1; }
command -v pbcopy >/dev/null 2>&1 || { echo >&2 "Dependency 'pbcopy' required, please install before continuing, or comment out line in 'vpn.sh'. Aborting."; exit 1; }

# parse command
case "$1" in
    start)
        # replace username, password, and PSK variables in VPN create script
        cp $VPN_CREATE_SCRIPT temp
        perl -pi -e "s/IPSEC-USERNAME-PLACEHOLDER/$USERNAME/g" temp
        perl -pi -e "s/IPSEC-PASSWORD-PLACEHOLDER/$PASSWORD/g" temp
        perl -pi -e "s/IPSEC-PSK-PLACEHOLDER/$PSK/g" temp

        # choose the right AMI based on region
        case "$REGION" in
            us-east-1)
                AMI=`echo $CONFIG | jq -r '.ubuntu_us_east_1'`
                ;;
            us-east-2)
                AMI=`echo $CONFIG | jq -r '.ubuntu_us_east_2'`
                ;;
            eu-west-1)
                AMI=`echo $CONFIG | jq -r '.ubuntu_eu_west_1'`
                ;;
            sa-east-1)
                AMI=`echo $CONFIG | jq -r '.ubuntu_sa_east_1'`
                ;;
            *)
                echo "Unsupported region. Use 'us-east-1', 'us-east-2', 'eu-west-1', 'sa-east-1', or add support for more AMIs to the script. Exiting."
                exit 1
                ;;
        esac

        # start the VPN instance and pass it the create script as userdata
        echo "Starting IPsec VPN on AWS EC2..."
        aws ec2 run-instances \
                --profile $PROFILE \
                --region $REGION \
                --image-id $AMI \
                --count 1 \
                --instance-type t3.nano \
                --security-groups IPSECVPN \
                --user-data file://temp \
                --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ipsecvpn}]' \
                > vpn-instance-config

        # clean up
        rm temp
        echo "Done."
        ;;

    ip)
        echo "Retrieving AWS VPN Instance IP Address..."
        INSTANCE_IP=`aws ec2 describe-instances \
                --profile $PROFILE \
                --region $REGION \
                --query 'Reservations[*].Instances[*].[PublicIpAddress]' \
                --filters "Name=tag-value,Values=ipsecvpn" \
                --output text`
        echo -n $INSTANCE_IP | pbcopy
        echo "Instance IP $INSTANCE_IP copied to clipboard"
        echo
        ;;

    status)
        echo "Retrieving AWS VPN Instance Status..."
        INSTANCE_ID=`cat vpn-instance-config | jq -r '.Instances | .[] | .InstanceId'`
        aws ec2 describe-instance-status \
                --profile $PROFILE \
                --region $REGION \
                --instance-id $INSTANCE_ID
        ;;

    stop)
        echo "Stopping and Terminating AWS VPN Instance..."
        INSTANCE_ID=`cat vpn-instance-config | jq -r '.Instances | .[] | .InstanceId'`
        aws ec2 terminate-instances \
                --profile $PROFILE \
                --region $REGION \
                --instance-ids $INSTANCE_ID

        # clean up
        rm vpn-instance-config
        echo "Done."
        ;;

    *)
        echo "Usage: $0 {start|ip|status|stop}"
        exit 1
esac

exit $?

