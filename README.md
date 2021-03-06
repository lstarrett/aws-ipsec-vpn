# EC2 IPSec VPN Tool
This script quickly and painlessly launches an AWS EC2 Instance running Ubuntu
16.04LTS and installs and launches a libreswan IPSec VPN server that can be
used to tunnel traffic through the AWS geographic region in which the instance
resides. This script is intended to be single click and dead simple to use.

### Dependencies
1. Bash
2. Required packages: 'awscli', 'perl', 'jq'
3. Optional packages: 'pbcopy'


### Pre-requisites
1. Must have an AWS account with provisioned CLI access profile and keys.
2. Must have a Security Group created in your AWS account in every region you
   will target with this tool named 'IPSECVPN' with the following inbound rules
   set
	1. Custom UDP port 500 (ISAKMP) - Allow from any source
	2. Custom UDP port 1701 (L2TP) - Allow from any source
	3. Custom UDP port 4500 (ESP) - Allow from any source

### Installation
1. Clone this repository to a capable local machine and cd into the project's root
   directory
2. Edit configuration file setting proper AWS region, AWS profile, and desired
   IPSec VPN PSK, username, and password

### Use
1. Run `./vpn.sh start` to launch VPN instance with configuration settings in
   'config.json'
2. After launching, check status of VPN instance with `./vpn.sh status` (NOTE:
   it may take a minute or two for any status to be available)
3. When VPN instance is running, retrieve IP address with `./vpn.sh ip`
4. Configure a new VPN connection profile on your local device with the
   following settings
	1. VPN type: L2TP over IPSec
	2. VPN server: IP address retrieved with `./vpn.sh ip`
	3. VPN shared secret or PSK: PSK in 'config.json'
	4. VPN username: username in 'config.json'
	5. VPN password: password in 'config.json'
	6. For configuration of the above steps on MacOS, see following guide.
	   Configuration on other operating systems (including iOS and Android)
	   is similar. https://www.softether.org/4-docs/2-howto/9.L2TPIPsec_Setup_Guide_for_SoftEther_VPN_Server/5.Mac_OS_X_L2TP_Client_Setup
5. Connect to VPN, and test connection by checking public IP of local device
6. When you are done with the VPN, run `./vpn.sh stop` to shut down and
   terminate the VPN instance. Nothing related to this tool will be left behind
   in your AWS account, other than the Security Group you created. To start the
   VPN again, start again from step (1). The configuration will remain the same,
   but the IP address will change and your local client configuration will need
   to be updated with the new VPN server address.
