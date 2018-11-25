#!/bin/bash
set -e
# Authors:      Rodrigo Cuadra
#               with Colaboration of Jose Miguel Rivera
#
# Support:      rcuadra@aplitel.com
#
function jumpto
{
    label=$1
    cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$')
    eval "$cmd"
    exit
}

echo -e "\n"
echo -e "************************************************************"
echo -e "*  Welcome to the VitalPBX high availability installation  *"
echo -e "*                All options are mandatory                 *"
echo -e "************************************************************"

filename="config.txt"
if [ -f $filename ]; then
	echo -e "config file"
	n=1
	while read line; do
		case $n in
			1)
				ip_master=$line
  			;;
			2)
				ip_slave=$line
  			;;
			3)
				ip_floating=$line
  			;;
			4)
				ip_floating_mask=$line
  			;;
			5)
				disk=$line
  			;;
			6)
				hapassword=$line
  			;;
		esac
		n=$((n+1))
	done < $filename
	echo -e "IP Master......... > $ip_master"	
	echo -e "IP Slave.......... > $ip_slave"
	echo -e "Floating IP....... > $ip_floating "
	echo -e "Floating IP Mask.. > $ip_floating_mask"
	echo -e "Disk (sdax)....... > $disk"
	echo -e "hacluster password > $hapassword"
fi
	
while [[ $ip_master == '' ]]
do
    read -p "IP Master......... > " ip_master 
done 

while [[ $ip_slave == '' ]]
do
    read -p "IP Slave.......... > " ip_slave 
done 

while [[ $ip_floating == '' ]]
do
    read -p "Floating IP....... > " ip_floating 
done 

while [[ $ip_floating_mask == '' ]]
do
    read -p "Floating IP Mask.. > " ip_floating_mask
done 

while [[ $disk == '' ]]
do
    read -p "Disk (sdax)....... > " disk 
done 

while [[ $hapassword == '' ]]
do
    read -p "hacluster password > " hapassword 
done

echo -e "************************************************************"
echo -e "*                   Check Information                      *"
echo -e "*        Make sure you have internet on both servers       *"
echo -e "************************************************************"
while [[ $veryfy_info != yes && $veryfy_info != no ]]
do
    read -p "Are you sure to continue with this settings? (yes,no) > " veryfy_info 
done

if [ "$veryfy_info" != "yes" ] ;then
	echo -e "************************************************************"
	echo -e "*                Starting to run the scripts               *"
	echo -e "************************************************************"
else
    	exit;
fi

echo -e "$ip_master" 		> config.txt
echo -e "$ip_slave" 		>> config.txt
echo -e "$ip_floating" 		>> config.txt
echo -e "$ip_floating" 		>> config.txt
echo -e "$ip_floating_mask" 	>> config.txt
echo -e "$disk" 		>> config.txt
echo -e "$hapassword" 		>> config.txt

echo -e "************************************************************"
echo -e "*          Copy Authorization key to slave server          *"
echo -e "************************************************************"
sshKeyFile=/root/.ssh/id_rsa
if [ ! -f $sshKeyFile ]; then
	ssh-keygen -f /root/.ssh/id_rsa -t rsa -N '' >/dev/null
fi
ssh-copy-id root@$ip_slave
echo -e "*** Done ***"

echo -e "************************************************************"
echo -e "*            Get the hostname in Master and Slave          *"
echo -e "************************************************************"
host_master=`hostname -f`
host_slave=`ssh root@$ip_slave 'hostname -f'`
echo -e "$host_master"
echo -e "$host_slave"
echo -e "*** Done ***"

stepFile=step.txt
if [ -f $stepFile ]; then
	step=`cat $stepFile`
else
	step=0
fi

start=${1:-"format_partition"}
case $step in
	3)
		start=${1:-"format_partition"}
  	;;
	4)
		start=${1:-"create_hostname"}
  	;;
	5)
		start=${1:-"update_firewall"}
  	;;
	6)
		start=${1:-"loading_drbd"}
  	;;
	7)
		start=${1:-"configure_drbd"}
  	;;
	8)
		start=${1:-"formating_drbd"}
  	;;
	9)
		start=${1:-"create_hacluster_password"}
  	;;
	10)
		start=${1:-"starting_pcs"}
  	;;
	11)
		start=${1:-"auth_hacluster"}
  	;;
	12)
		start=${1:-"creating_cluster"}
  	;;
	13)
		start=${1:-"starting_cluster"}
  	;;
	14)
		start=${1:-"creating_floating_ip"}
  	;;
	15)
		start=${1:-"creating_drbd_resources"}
  	;;
	16)
		start=${1:-"creating_filesystem"}
  	;;
	17)
		start=${1:-"stop_all_services"}
  	;;
	18)
		start=${1:-"setting_mariadb_resource"}
  	;;
	19)
		start=${1:-"creating_mariadb_resource"}
  	;;
	20)
		start=${1:-"creating_asterisk_resource"}
  	;;
	21)
		start=${1:-"compress_asterisk_files"}
  	;;
	22)
		start=${1:-"copy_asterisk_files"}
  	;;
	23)
		start=${1:-"remove_master_asterisk_files"}
  	;;
	24)
		start=${1:-"create_symbolic_linlk_master_asterisk_files"}
  	;;
	25)
		start=${1:-"remove_slave_asterisk_files"}
  	;;
	26)
		start=${1:-"create_symbolic_linlk_slave_asterisk_files"}
  	;;
	27)
		start=${1:-"create_vitalpbx_resource"}
  	;;
	28)
		start=${1:-"create_fail2ban_resource"}
  	;;
	29)
		start=${1:-"vitalpbx_cluster_ok"}
	;;
esac
jumpto $start

format_partition:
echo -e "************************************************************"
echo -e "*             Format new drive in Master/Slave             *"
echo -e "************************************************************"
mke2fs -j /dev/$disk
dd if=/dev/zero bs=1M count=500 of=/dev/$disk; sync
ssh root@$ip_slave "mke2fs -j /dev/$disk"
ssh root@$ip_slave "dd if=/dev/zero bs=1M count=500 of=/dev/$disk; sync"
echo -e "*** Done ***"
echo -e "4"	> step.txt

create_hostname:
echo -e "************************************************************"
echo -e "*            Creating hosts name in Master/Slave           *"
echo -e "************************************************************"
echo -e "$ip_master \t$host_master" >> /etc/hosts
echo -e "$ip_slave \t$host_slave" >> /etc/hosts
ssh root@$ip_slave "echo -e '$ip_master \t$host_master' >> /etc/hosts"
ssh root@$ip_slave "echo -e '$ip_slave \t$host_slave' >> /etc/hosts"
echo -e "*** Done ***"
echo -e "5"	> step.txt

update_firewall:
echo -e "************************************************************"
echo -e "*            Update Firewall in Master/Slave               *"
echo -e "************************************************************"
firewall-cmd --permanent --add-service=high-availability
firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="$ip_slave" port port="7789" protocol="tcp" accept"
firewall-cmd --reload
ssh root@$ip_slave "firewall-cmd --permanent --add-service=high-availability"
ssh root@$ip_slave "firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="$ip_master" port port="7789" protocol="tcp" accept'"
ssh root@$ip_slave "firewall-cmd --reload"
echo -e "*** Done ***"
echo -e "6"	> step.txt

loading_drbd:
echo -e "************************************************************"
echo -e "*               Loading drbd in Master/Slave               *"
echo -e "************************************************************"
modprobe drbd
ssh root@$ip_slave "modprobe drbd"
systemctl enable drbd.service
ssh root@$ip_slave "systemctl enable drbd.service"
echo -e "*** Done ***"
echo -e "7"	> step.txt

configure_drbd:
echo -e "************************************************************"
echo -e "*       Configure drbr resources in Master/Slave           *"
echo -e "************************************************************"
mv /etc/drbd.d/global_common.conf /etc/drbd.d/global_common.conf.orig
ssh root@$ip_slave "mv /etc/drbd.d/global_common.conf /etc/drbd.d/global_common.conf.orig"
echo -e "global { \n\tusage-count no; \n} \ncommon { \n\tnet { \n\tprotocol C; \n\t} \n}"  > /etc/drbd.d/global_common.conf
scp /etc/drbd.d/global_common.conf root@$ip_slave:/etc/drbd.d/global_common.conf
echo -e "resource drbd0 {" 			> /etc/drbd.d/drbd0.res
echo -e "protocol C;" 				>> /etc/drbd.d/drbd0.res
echo -e "on $host_master {" 			>> /etc/drbd.d/drbd0.res
echo -e "	device /dev/drbd0;" 		>> /etc/drbd.d/drbd0.res
echo -e "   	disk /dev/sda4;" 		>> /etc/drbd.d/drbd0.res
echo -e "   	address $ip_master:7789;" 	>> /etc/drbd.d/drbd0.res
echo -e "	meta-disk internal;"		>> /etc/drbd.d/drbd0.res
echo -e "	}" 				>> /etc/drbd.d/drbd0.res
echo -e "on $host_slave {" 			>> /etc/drbd.d/drbd0.res
echo -e "	device /dev/drbd0;" 		>> /etc/drbd.d/drbd0.res
echo -e "   	disk /dev/sda4;" 		>> /etc/drbd.d/drbd0.res
echo -e "   	address $ip_slave:7789;" 	>> /etc/drbd.d/drbd0.res
echo -e "	meta-disk internal;" 		>> /etc/drbd.d/drbd0.res
echo -e "   	}" 				>> /etc/drbd.d/drbd0.res
echo -e "}" 					>> /etc/drbd.d/drbd0.res
scp /etc/drbd.d/drbd0.res root@$ip_slave:/etc/drbd.d/drbd0.res
drbdadm create-md drbd0
ssh root@$ip_slave "drbdadm create-md drbd0"
drbdadm up drbd0
ssh root@$ip_slave "drbdadm up drbd0"
drbdadm primary drbd0 --force
sleep 3
echo -e "*** Done ***"
echo -e "8"	> step.txt

formating_drbd:
echo -e "************************************************************"
echo -e "*              Formating drbd disk in Master               *"
echo -e "*           Wait, this process may take a while            *"
echo -e "************************************************************"
mkfs.xfs /dev/drbd0
mount /dev/drbd0 /mnt
touch /mnt/testfile1
umount /mnt
drbdadm secondary drbd0
sleep 2
ssh root@$ip_slave "drbdadm primary drbd0 --force"
ssh root@$ip_slave "mount /dev/drbd0 /mnt"
ssh root@$ip_slave "touch /mnt/testfile2"
ssh root@$ip_slave "umount /mnt"
ssh root@$ip_slave "drbdadm secondary drbd0"
sleep 2
drbdadm primary drbd0
mount /dev/drbd0 /mnt
echo -e "*** Done ***"
echo -e "9"	> step.txt

create_hacluster_password:
echo -e "************************************************************"
echo -e "*     Create password for hacluster in Master/Slave        *"
echo -e "************************************************************"
echo $hapassword | passwd --stdin hacluster
ssh root@$ip_slave "echo $hapassword | passwd --stdin hacluster"
echo -e "*** Done ***"
echo -e "10"	> step.txt

starting_pcs:
echo -e "************************************************************"
echo -e "*          Starting pcsd services in Master/Slave          *"
echo -e "************************************************************"
systemctl start pcsd
ssh root@$ip_slave "systemctl start pcsd"
systemctl enable pcsd.service 
systemctl enable corosync.service 
systemctl enable pacemaker.service
ssh root@$ip_slave "systemctl enable pcsd.service"
ssh root@$ip_slave "systemctl enable corosync.service"
ssh root@$ip_slave "systemctl enable pacemaker.service"
echo -e "*** Done ***"
echo -e "11"	> step.txt

auth_hacluster:
echo -e "************************************************************"
echo -e "*            Server Authenticate in Master                 *"
echo -e "************************************************************"
pcs cluster auth $host_master $host_slave -u hacluster -p $hapassword
echo -e "*** Done ***"
echo -e "12"	> step.txt

creating_cluster:
echo -e "************************************************************"
echo -e "*              Creating Cluster in Master                  *"
echo -e "************************************************************"
pcs cluster setup --name cluster_voip $host_master $host_slave
echo -e "*** Done ***"
echo -e "13"	> step.txt

starting_cluster:
echo -e "************************************************************"
echo -e "*              Starting Cluster in Master                  *"
echo -e "************************************************************"
pcs cluster start --all
pcs cluster enable --all
pcs property set stonith-enabled=false
pcs property set no-quorum-policy=ignore
echo -e "*** Done ***"
echo -e "14"	> step.txt

creating_floating_ip:
echo -e "************************************************************"
echo -e "*            Creating Floating IP in Master                *"
echo -e "************************************************************"
pcs resource create virtual_ip ocf:heartbeat:IPaddr2 ip=$ip_floating cidr_netmask=$ip_floating_mask op monitor interval=30s on-fail=restart
pcs cluster cib drbd_cfg
pcs cluster cib-push drbd_cfg
echo -e "*** Done ***"
echo -e "15"	> step.txt

creating_drbd_resources:
echo -e "************************************************************"
echo -e "*        Creating Resources for drbd in Master             *"
echo -e "************************************************************"
pcs -f drbd_cfg resource create DrbdData ocf:linbit:drbd drbd_resource=drbd0 op monitor interval=60s
pcs -f drbd_cfg resource master DrbdDataClone DrbdData master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
pcs cluster cib-push drbd_cfg
echo -e "*** Done ***"
echo -e "16"	> step.txt

creating_filesystem:
echo -e "************************************************************"
echo -e "* Create FILESYSTEM resource for the automated mount point *"
echo -e "************************************************************"
pcs cluster cib fs_cfg
pcs -f fs_cfg resource create DrbdFS Filesystem device="/dev/drbd0" directory="/mnt" fstype="xfs" 
pcs -f fs_cfg constraint colocation add DrbdFS with DrbdDataClone INFINITY with-rsc-role=Master 
pcs -f fs_cfg constraint order promote DrbdDataClone then start DrbdFS
pcs -f fs_cfg constraint colocation add DrbdFS with virtual_ip INFINITY
pcs -f fs_cfg constraint order virtual_ip then DrbdFS
pcs cluster cib-push fs_cfg
echo -e "*** Done ***"
echo -e "17"	> step.txt

stop_all_services:
echo -e "************************************************************"
echo -e "*               Stop all services                          *"
echo -e "************************************************************"
systemctl stop fail2ban
systemctl disable fail2ban
ssh root@$ip_slave "systemctl stop fail2ban"
ssh root@$ip_slave "systemctl disable fail2ban"
systemctl stop asterisk
systemctl disable asterisk
ssh root@$ip_slave "systemctl stop asterisk"
ssh root@$ip_slave "systemctl disable asterisk"
systemctl stop vpbx-monitor
systemctl disable vpbx-monitor
ssh root@$ip_slave "systemctl stop vpbx-monitor"
ssh root@$ip_slave "systemctl disable vpbx-monitor"
systemctl stop mariadb
systemctl disable mariadb
ssh root@$ip_slave "systemctl stop mariadb"
ssh root@$ip_slave "systemctl disable mariadb"
echo -e "*** Done ***"
echo -e "18"	> step.txt

setting_mariadb_resource:
echo -e "************************************************************"
echo -e "*             Setting MariaDB in Master/Slave              *"
echo -e "************************************************************"
mkdir /mnt/mysql
mkdir /mnt/mysql/data
cd /mnt/mysql
cp -aR /var/lib/mysql/* /mnt/mysql/data
sed -i 's/var\/lib\/mysql/mnt\/mysql\/data/g' /etc/my.cnf
ssh root@$ip_slave "sed -i 's/var\/lib\/mysql/mnt\/mysql\/data/g' /etc/my.cnf"
mv /etc/my.cnf /mnt/mysql/
ln -s /mnt/mysql/my.cnf /etc/
ssh root@$ip_slave "rm -rf /etc/my.cnf"
ssh root@$ip_slave "ln -s /mnt/mysql/my.cnf /etc/"
echo -e "*** Done ***"
echo -e "19"	> step.txt

creating_mariadb_resource:
echo -e "************************************************************"
echo -e "*    Create resource for the use of MariaDB in Master      *"
echo -e "************************************************************"
pcs resource create mysql ocf:heartbeat:mysql binary="/usr/bin/mysqld_safe" config="/etc/my.cnf" datadir="/mnt/mysql/data" pid="/var/lib/mysql/mysql.pid" socket="/var/lib/mysql/mysql.sock" additional_parameters="--bind-address=0.0.0.0" op start timeout=60s op stop timeout=60s op monitor interval=20s timeout=30s on-fail=standby 
pcs cluster cib fs_cfg
pcs cluster cib-push fs_cfg --config
pcs -f fs_cfg constraint colocation add mysql with virtual_ip INFINITY
pcs -f fs_cfg constraint order DrbdFS then mysql
pcs cluster cib-push fs_cfg --config
echo -e "*** Done ***"
echo -e "20"	> step.txt

creating_asterisk_resource:
echo -e "************************************************************"
echo -e "*            Create resource for Asterisk                  *"
echo -e "************************************************************"
cd /usr/lib/ocf/resource.d/heartbeat
wget https://raw.githubusercontent.com/VitalPBX/vitalpbx_ha/master/asterisk 
chmod 755 asterisk
scp /usr/lib/ocf/resource.d/heartbeat/asterisk root@$ip_slave:/usr/lib/ocf/resource.d/heartbeat/asterisk
ssh root@$ip_slave 'chmod 755 /usr/lib/ocf/resource.d/heartbeat/asterisk'
pcs resource create asterisk ocf:heartbeat:asterisk user="root" group="root" op monitor timeout="30"
pcs cluster cib fs_cfg
pcs cluster cib-push fs_cfg --config
pcs -f fs_cfg constraint colocation add asterisk with virtual_ip INFINITY
pcs -f fs_cfg constraint order mysql then asterisk
pcs cluster cib-push fs_cfg --config
echo -e "*** Done ***"
echo -e "21"	> step.txt

compress_asterisk_files:
echo -e "************************************************************"
echo -e "*   Copy folders and files the DRBD partition on Master    *"
echo -e "************************************************************"
cd /mnt/
tar -zcvf var-asterisk.tgz /var/log/asterisk 
tar -zcvf var-lib-asterisk.tgz /var/lib/asterisk
tar -zcvf usr-lib64-asterisk.tgz /usr/lib64/asterisk
tar -zcvf var-spool-asterisk.tgz /var/spool/asterisk
tar -zcvf etc-asterisk.tgz /etc/asterisk
echo -e "22"	> step.txt

copy_asterisk_files:
tar xvfz var-asterisk.tgz 
tar xvfz var-lib-asterisk.tgz 
tar xvfz usr-lib64-asterisk.tgz 
tar xvfz var-spool-asterisk.tgz 
tar xvfz etc-asterisk.tgz
echo -e "23"	> step.txt

remove_master_asterisk_files:
rm -rf /var/log/asterisk 
rm -rf /var/lib/asterisk 
rm -rf /usr/lib64/asterisk/ 
rm -rf /var/spool/asterisk/ 
rm -rf /etc/asterisk
echo -e "24"	> step.txt

create_symbolic_linlk_master_asterisk_files:
ln -s /mnt/var/log/asterisk /var/log/asterisk 
ln -s /mnt/var/lib/asterisk /var/lib/asterisk 
ln -s /mnt/usr/lib64/asterisk /usr/lib64/asterisk
ln -s /mnt/var/spool/asterisk /var/spool/asterisk
ln -s /mnt/etc/asterisk /etc/asterisk
echo -e "*** Done ***"
echo -e "25"	> step.txt

remove_slave_asterisk_files:
echo -e "************************************************************"
echo -e "*           Configure symbolic links on Slave              *"
echo -e "************************************************************"
ssh root@$ip_slave 'rm -rf /var/log/asterisk'
ssh root@$ip_slave 'rm -rf /var/lib/asterisk'
ssh root@$ip_slave 'rm -rf /usr/lib64/asterisk/'
ssh root@$ip_slave 'rm -rf /var/spool/asterisk/'
ssh root@$ip_slave 'rm -rf /etc/asterisk'
echo -e "26"	> step.txt

create_symbolic_linlk_slave_asterisk_files:
ssh root@$ip_slave 'ln -s /mnt/var/log/asterisk /var/log/asterisk'
ssh root@$ip_slave 'ln -s /mnt/var/lib/asterisk /var/lib/asterisk'
ssh root@$ip_slave 'ln -s /mnt/usr/lib64/asterisk /usr/lib64/asterisk'
ssh root@$ip_slave 'ln -s /mnt/var/spool/asterisk /var/spool/asterisk'
ssh root@$ip_slave 'ln -s /mnt/etc/asterisk /etc/asterisk'
echo -e "*** Done ***"
echo -e "27"	> step.txt

create_vitalpbx_resource:
echo -e "************************************************************"
echo -e "*                    VitalPBX Service                      *"
echo -e "************************************************************"
pcs resource create vpbx-monitor service:vpbx-monitor op monitor interval=30s
pcs cluster cib fs_cfg
pcs cluster cib-push fs_cfg --config
pcs -f fs_cfg constraint colocation add vpbx-monitor with virtual_ip INFINITY
pcs -f fs_cfg constraint order asterisk then vpbx-monitor
pcs cluster cib-push fs_cfg --config
echo -e "*** Done ***"
echo -e "28"	> step.txt

create_fail2ban_resource:
echo -e "************************************************************"
echo -e "*                    fail2ban Service                      *"
echo -e "************************************************************"
pcs resource create fail2ban service:fail2ban op monitor interval=30s
pcs cluster cib fs_cfg
pcs cluster cib-push fs_cfg --config
pcs -f fs_cfg constraint colocation add fail2ban with virtual_ip INFINITY
pcs -f fs_cfg constraint order vpbx-monitor then fail2ban
pcs cluster cib-push fs_cfg --config
echo -e "*** Done ***"
echo -e "29"	> step.txt

vitalpbx_cluster_ok:
echo -e "************************************************************"
echo -e "*                VitalPBX Cluster OK                       *"
echo -e "************************************************************"
ssh root@$ip_slave "pcs cluster standby  $host_slave"
sleep 5
ssh root@$ip_slave "pcs cluster unstandby  $host_slave"
sleep 5
pcs status resources
echo -e "*** Done ***"
