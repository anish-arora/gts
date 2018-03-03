#!/bin/bash

# This script is use to get the output of pre-reboot commands and save to NA REAR (itsusravlnx01.jnj.com:/vol/itsusravlnx01_its/linux_images/pre-reboot-output) location.

if [ `id -u` -ne 0 ]; then echo -en "\nTo run this script you must be a root user\n\n"; exit; fi;

if [ $1 ]; then Request_Number=CHG000010333569; 
else 
	echo -en "\nPlease provide Incident/Service/Change/Task number: \n";
#	read Request_Number;
fi

Log_File=/var/adm/install-logs/`uname -n`-$Request_Number-pre-reboot-output-`date +%F-%R`

if [ `dmidecode | grep "Product Name" | head -1 | awk '{print $3}'` == "VMware" ];then VM=1; else VM=0; fi;

echo -en "Servername: $(uname -n)\nDate: $(date)\n" >> $Log_File;
echo -en "\n=====================================================\n" >> $Log_File;

function Execute_command()
{
	echo -en "\nBEGIN $1\n" >> $Log_File;
	$1 >> $Log_File
	echo -en "END $1\n" >> $Log_File;
}

echo $Log_File;

Execute_command "ifconfig -a"
Execute_command "ip addr"
Execute_command "last"
Execute_command "who -r"
Execute_command "w"
Execute_command "hwclock"
Execute_command "fdisk -l"
Execute_command "df -k"
Execute_command "finger"
Execute_command "ps -aef"
Execute_command "netstat -pant"
Execute_command "dmidecode"
Execute_command "mount"
Execute_command "iptables -L"
Execute_command "cat /proc/cpuinfo"
Execute_command "cat /proc/meminfo"
Execute_command "adinfo"
Execute_command "route -n"
Execute_command "ip route"
Execute_command "pvdisplay"
Execute_command "vgdisplay"
Execute_command "lvdisplay"
Execute_command "cat /etc/passwd"
Execute_command "cat /etc/group"
Execute_command "cat /etc/fstab"

## Commands which needs to run specifically on physical server
if [ $VM -eq 0 ];then 

	Execute_command "multipath -ll" ; 
	Execute_command "adapter_info" ; 

	echo -en "\nBEGIN Total LUN\n" >> $Log_File; multipath -ll|grep mpath|wc -l >> $Log_File; echo -en "\nEND Total LUN\n" >> $Log_File;

	SAN_Disks_Size=0; for i in `multipath -ll|grep size|awk -FG '{print $1}'|awk -F= '{print $NF}'`; do let SAN_Disks_Size+=$i; done;
	echo -en "\nBEGIN Total LUN Size\n" >> $Log_File; echo $SAN_Disks_Size >> $Log_File; echo -en "\nEND Total LUN Size\n" >> $Log_File;

	echo -en "\nBEGIN LUN State\n" >> $Log_File; multipath -ll|egrep 'active|ready'|wc -l >> $Log_File; echo -en "\nEND LUN State\n" >> $Log_File;
fi

function Call_Suse_Customized()
{
	## SuSe Heartbeat Cluster
	if [ -f /usr/sbin/crm_mon ]; then Execute_command "crm_mon -1" ; fi
	Execute_command "cat /etc/udev/rules.d/30-net_persistent_names.rules"
}

function Call_Redhat_Customized()
{
	## Redhat HP Service Guard Cluster
	if [ -f /usr/local/cmcluster/bin/cmviewcl ]; then Execute_command "/usr/local/cmcluster/bin/cmviewcl" ; fi
	Execute_command "cat /etc/udev/rules.d/70-persistent-net.rules"
}

OS_Version=`cat /proc/version | awk '{print $9}' | sed 's/(//'`

case "$OS_Version" in

Red)    Call_Redhat_Customized
                ;;
SUSE)   Call_Suse_Customized
                ;;
esac
# NA
 mount itsusravlnx01.jnj.com:/vol/itsusravlnx01_its/linux_images/pre-reboot-output /mnt
# EMEA
#10.130.85.112:/vol/itsbebevlnx01_its/linux_images/pre-reboot-output /mnt
cp $Log_File /mnt/
umount /mnt
