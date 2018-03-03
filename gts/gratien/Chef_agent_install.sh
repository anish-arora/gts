#! /bin/bash
#################################################################################
# Script Name          : Chef_agent_install.sh
# Script Version       : 1.1
# Script Status        : Production
# Author               : Ashok Chauhan
# Creation Date        : 27-Jun-2017
# Last Modified        : 30-Jun-2017
# Validation Reference :
# Description          : Install Chef agent on linux system
# Change History       : Added a condition to verify if Chef is already installed
##################################################################################

typeset -x CHG_CONTROL=$1
typeset -x PRGNAME=${0##*/}                             # This script short name
typeset -x PRGDIR=${0%/*}                               # This script directory name
typeset -x PATH=$PATH:/sbin:/usr/sbin                   # Setting up rudimentary path
typeset -r platform=$(uname -s)                         # Platform
typeset -r dlog=/var/adm/install-logs                   # Log directory
typeset lhost=$(uname -n)
typeset osVer=$(uname -r)
typeset whoAMI=$(whoami)
typeset instlog=$dlog/$CHG_CONTROL-$lhost-${PRGNAME%???}.$(date +'%m%d%Y-%H%M').scriptlog
[[ $PRGDIR = /* ]] || PRGDIR=$(pwd) # Acquire absolute path to the script

function Error_trap()
{
        echo "Error: $1 $(uname -n)";
        exit
}

{
# turn on debugging
#set -x
echo ""
echo "###################################################################################################################"
echo ""
echo "                                   Script: $PRGNAME"
echo "                                     Host: $lhost"
echo "                                  OS Type: $osVer"
echo "                          OS Distribution: $( [ -f /etc/SuSE-release ] && cat /etc/SuSE-release || cat /etc/redhat-release )"
echo "                                     User: $whoAMI"
echo "                                     Date: $(date)"
echo "                                      Log: $instlog"
echo "                              Description: Install Chef agent on linux systems."
echo ""
echo "###################################################################################################################"
echo ""

### Only for Treasury Systems
rpm -e `rpm -qa | grep -i chef-12`

yum clean all

if [ -f /opt/chef/embedded/bin/chef-client ]; then Error_trap "Chef agent is already installed on"; fi

if [ ! -d /etc/jnj-install ]; then mkdir -p /etc/jnj-install; fi

if [ -f /tmp/scm_facts.txt ]; then echo "Copying scm_fact file to /etc/jnj-install & /root..."; cp -pv /tmp/scm_facts.txt /etc/jnj-install/ ; cp -pv /tmp/scm_facts.txt /root/ ; else Error_trap "/tmp/scm_facts.txt not exist on"; fi

if [ -f /etc/jnj-install/scm_facts.txt ]; 
then 
	cd /opt
	wget http://itsusralsp03287.jnj.com/jnj-dvl-opcx-scm/packages/chef/JnJServerBuild-Linux.tgz
	if [ $? -eq 0 ];
	then
		tar -xvf JnJServerBuild-Linux.tgz
		rm -rf JnJServerBuild-Linux.tgz
		sh /opt/JnJServerBuild-Linux/chef_install.sh
		if [ $? -ne 0 ]; then Error_trap "The chef_install.sh script isn't executed successfully"; fi
	else
		Error_trap "Package download failed on";
	fi
else
	Error_trap "/etc/jnj-install/scm_facts.txt file is not exist on";
fi

if [ -f /opt/chef/embedded/bin/chef-client ]; then echo "Final status....Chef agent is installed on $(uname -n)"; fi

} | tee $instlog
