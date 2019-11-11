
#!/bin/bash
set -e
# Authors:      Rodrigo Cuadra
#               with Collaboration of Jose Miguel Rivera
#				06-Nov-2019 - Version 2
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
	echo -e "IP Master................ > $ip_master"	
	echo -e "IP Slave................. > $ip_slave"
	echo -e "Floating IP.............. > $ip_floating "
	echo -e "Floating IP Mask (SIDR).. > $ip_floating_mask"
	echo -e "Disk (sdax).............. > $disk"
	echo -e "hacluster password....... > $hapassword"
fi
	
while [[ $ip_master == '' ]]
do
    read -p "IP Master................ > " ip_master 
done 

while [[ $ip_slave == '' ]]
do
    read -p "IP Slave................. > " ip_slave 
done 

while [[ $ip_floating == '' ]]
do
    read -p "Floating IP.............. > " ip_floating 
done 

while [[ $ip_floating_mask == '' ]]
do
    read -p "Floating IP Mask (SIDR).. > " ip_floating_mask
done 

while [[ $disk == '' ]]
do
    read -p "Disk (sdax).............. > " disk 
done 

while [[ $hapassword == '' ]]
do
    read -p "hacluster password....... > " hapassword 
done

echo -e "************************************************************"
echo -e "*                   Check Information                      *"
echo -e "*        Make sure you have internet on both servers       *"
echo -e "************************************************************"
while [[ $veryfy_info != yes && $veryfy_info != no ]]
do
    read -p "Are you sure to continue with this settings? (yes,no) > " veryfy_info 
done

if [ "$veryfy_info" = yes ] ;then
	echo -e "************************************************************"
	echo -e "*                Starting to run the scripts               *"
	echo -e "************************************************************"
else
    	exit;
fi

cat > config.txt << EOF
$ip_master
$ip_slave
$ip_floating
$ip_floating_mask
$disk
$hapassword
EOF

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
	1)
		start=${1:-"format_partition"}
  	;;
	2)
		start=${1:-"create_hostname"}
  	;;
	3)
		start=${1:-"update_firewall"}
  	;;
	4)
		start=${1:-"loading_drbd"}
  	;;
	5)
		start=${1:-"configure_drbd"}
  	;;
	6)
		start=${1:-"formating_drbd"}
  	;;
	7)
		start=${1:-"create_hacluster_password"}
  	;;
	8)
		start=${1:-"starting_pcs"}
  	;;
	9)
		start=${1:-"auth_hacluster"}
  	;;
	10)
		start=${1:-"creating_cluster"}
  	;;
	11)
		start=${1:-"starting_cluster"}
  	;;
	12)
		start=${1:-"creating_floating_ip"}
  	;;
	13)
		start=${1:-"creating_drbd_resources"}
  	;;
	14)
		start=${1:-"creating_filesystem"}
  	;;
	15)
		start=${1:-"stop_all_services"}
  	;;
	16)
		start=${1:-"setting_mariadb_resource"}
  	;;
	17)
		start=${1:-"creating_mariadb_resource"}
  	;;
	18)
		start=${1:-"create_dahdi_resource"}
  	;;
	19)
		start=${1:-"creating_asterisk_resource"}
  	;;
	20)
		start=${1:-"compress_asterisk_files"}
  	;;
	21)
		start=${1:-"copy_asterisk_files"}
  	;;
	22)
		start=${1:-"remove_master_asterisk_files"}
  	;;
	23)
		start=${1:-"create_symbolic_linlk_master_asterisk_files"}
  	;;
	24)
		start=${1:-"remove_slave_asterisk_files"}
  	;;
	25)
		start=${1:-"create_symbolic_linlk_slave_asterisk_files"}
  	;;
	26)
		start=${1:-"create_vitalpbx_resource"}
  	;;
	27)
		start=${1:-"create_fail2ban_resource"}
  	;;
	28)
		start=${1:-"vitalpbx_cluster_bascul"}
	;;
	29)
		start=${1:-"ceate_welcome_message"}
	;;
	30)
		start=${1:-"vitalpbx_cluster_ok"}
	;;
esac
jumpto $start
echo -e "1"	> step.txt

format_partition:
echo -e "************************************************************"
echo -e "*             Format new drive in Master/Slave             *"
echo -e "************************************************************"
mke2fs -j /dev/$disk
dd if=/dev/zero bs=1M count=500 of=/dev/$disk; sync
ssh root@$ip_slave "mke2fs -j /dev/$disk"
ssh root@$ip_slave "dd if=/dev/zero bs=1M count=500 of=/dev/$disk; sync"
echo -e "*** Done ***"
echo -e "2"	> step.txt

create_hostname:
echo -e "************************************************************"
echo -e "*            Creating hosts name in Master/Slave           *"
echo -e "************************************************************"
echo -e "$ip_master \t$host_master" >> /etc/hosts
echo -e "$ip_slave \t$host_slave" >> /etc/hosts
ssh root@$ip_slave "echo -e '$ip_master \t$host_master' >> /etc/hosts"
ssh root@$ip_slave "echo -e '$ip_slave \t$host_slave' >> /etc/hosts"
echo -e "*** Done ***"
echo -e "3"	> step.txt

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
echo -e "4"	> step.txt

loading_drbd:
echo -e "************************************************************"
echo -e "*               Loading drbd in Master/Slave               *"
echo -e "************************************************************"
modprobe drbd
ssh root@$ip_slave "modprobe drbd"
systemctl enable drbd.service
ssh root@$ip_slave "systemctl enable drbd.service"
echo -e "*** Done ***"
echo -e "5"	> step.txt

configure_drbd:
echo -e "************************************************************"
echo -e "*       Configure drbr resources in Master/Slave           *"
echo -e "************************************************************"
mv /etc/drbd.d/global_common.conf /etc/drbd.d/global_common.conf.orig
ssh root@$ip_slave "mv /etc/drbd.d/global_common.conf /etc/drbd.d/global_common.conf.orig"
echo -e "global { \n\tusage-count no; \n} \ncommon { \n\tnet { \n\tprotocol C; \n\t} \n}"  > /etc/drbd.d/global_common.conf
scp /etc/drbd.d/global_common.conf root@$ip_slave:/etc/drbd.d/global_common.conf

cat > /etc/drbd.d/drbd0.res << EOF
resource drbd0 {
protocol C;
on $host_master {
	device /dev/drbd0;
   	disk /dev/$disk;
   	address $ip_master:7789;
	meta-disk internal;
	}
on $host_slave {
	device /dev/drbd0;
   	disk /dev/$disk;
   	address $ip_slave:7789;
	meta-disk internal;
   	}
handlers {
    split-brain "/usr/lib/drbd/notify-split-brain.sh root";
    }
net {
    after-sb-0pri discard-zero-changes;
    after-sb-1pri discard-secondary;
    after-sb-2pri disconnect;
    }
}
EOF

scp /etc/drbd.d/drbd0.res root@$ip_slave:/etc/drbd.d/drbd0.res
drbdadm create-md drbd0
ssh root@$ip_slave "drbdadm create-md drbd0"
drbdadm up drbd0
drbdadm primary drbd0 --force
ssh root@$ip_slave "drbdadm up drbd0"
sleep 3
echo -e "*** Done ***"
echo -e "6"	> step.txt

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
echo -e "7"	> step.txt

create_hacluster_password:
echo -e "************************************************************"
echo -e "*     Create password for hacluster in Master/Slave        *"
echo -e "************************************************************"
echo $hapassword | passwd --stdin hacluster
ssh root@$ip_slave "echo $hapassword | passwd --stdin hacluster"
echo -e "*** Done ***"
echo -e "8"	> step.txt

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
echo -e "9"	> step.txt

auth_hacluster:
echo -e "************************************************************"
echo -e "*            Server Authenticate in Master                 *"
echo -e "************************************************************"
pcs cluster auth $host_master $host_slave -u hacluster -p $hapassword
echo -e "*** Done ***"
echo -e "10"	> step.txt

creating_cluster:
echo -e "************************************************************"
echo -e "*              Creating Cluster in Master                  *"
echo -e "************************************************************"
pcs cluster setup --name cluster_voip $host_master $host_slave
echo -e "*** Done ***"
echo -e "11"	> step.txt

starting_cluster:
echo -e "************************************************************"
echo -e "*              Starting Cluster in Master                  *"
echo -e "************************************************************"
pcs cluster start --all
pcs cluster enable --all
pcs property set stonith-enabled=false
pcs property set no-quorum-policy=ignore
echo -e "*** Done ***"
echo -e "12"	> step.txt

creating_floating_ip:
echo -e "************************************************************"
echo -e "*            Creating Floating IP in Master                *"
echo -e "************************************************************"
pcs resource create virtual_ip ocf:heartbeat:IPaddr2 ip=$ip_floating cidr_netmask=$ip_floating_mask op monitor interval=30s on-fail=restart
pcs cluster cib drbd_cfg
pcs cluster cib-push drbd_cfg
echo -e "*** Done ***"
echo -e "13"	> step.txt

creating_drbd_resources:
echo -e "************************************************************"
echo -e "*        Creating Resources for drbd in Master             *"
echo -e "************************************************************"
pcs -f drbd_cfg resource create DrbdData ocf:linbit:drbd drbd_resource=drbd0 op monitor interval=60s
pcs -f drbd_cfg resource master DrbdDataClone DrbdData master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
pcs cluster cib-push drbd_cfg
echo -e "*** Done ***"
echo -e "14"	> step.txt

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
echo -e "15"	> step.txt

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
usermod -u 1000 asterisk
ssh root@$ip_slave "systemctl stop asterisk"
ssh root@$ip_slave "systemctl disable asterisk"
ssh root@$ip_slave "usermod -u 1000 asterisk"
systemctl stop vpbx-monitor
systemctl disable vpbx-monitor
ssh root@$ip_slave "systemctl stop vpbx-monitor"
ssh root@$ip_slave "systemctl disable vpbx-monitor"
systemctl stop mariadb
systemctl disable mariadb
ssh root@$ip_slave "systemctl stop mariadb"
ssh root@$ip_slave "systemctl disable mariadb"
systemctl stop dahdi
systemctl disable dahdi
ssh root@$ip_slave "systemctl stop dahdi"
ssh root@$ip_slave "systemctl disable dahdi"
echo -e "*** Done ***"
echo -e "16"	> step.txt

setting_mariadb_resource:
echo -e "************************************************************"
echo -e "*             Setting MariaDB in Master/Slave              *"
echo -e "************************************************************"
mkdir /mnt/mysql
mkdir /mnt/mysql/data
cp -aR /var/lib/mysql/* /mnt/mysql/data
sed -i 's/var\/lib\/mysql/mnt\/mysql\/data/g' /etc/my.cnf
ssh root@$ip_slave "sed -i 's/var\/lib\/mysql/mnt\/mysql\/data/g' /etc/my.cnf"
mv /etc/my.cnf /mnt/mysql/
ln -s /mnt/mysql/my.cnf /etc/
ssh root@$ip_slave "rm -rf /etc/my.cnf"
ssh root@$ip_slave "ln -s /mnt/mysql/my.cnf /etc/"
chown mysql:mysql -R /mnt/mysql
echo -e "*** Done ***"
echo -e "17"	> step.txt

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
echo -e "18"	> step.txt

create_dahdi_resource:
echo -e "************************************************************"
echo -e "*                    DAHDI Service                      *"
echo -e "************************************************************"
pcs resource create dahdi service:dahdi op monitor interval=30s
pcs cluster cib fs_cfg
pcs cluster cib-push fs_cfg --config
pcs -f fs_cfg constraint colocation add dahdi with virtual_ip INFINITY
pcs -f fs_cfg constraint order mysql then dahdi
pcs cluster cib-push fs_cfg --config
echo -e "*** Done ***"
echo -e "19"	> step.txt

creating_asterisk_resource:
echo -e "************************************************************"
echo -e "*            Create resource for Asterisk                  *"
echo -e "************************************************************"
sed -i 's/RestartSec=10/RestartSec=1/g'  /usr/lib/systemd/system/asterisk.service
sed -i 's/Wants=mariadb.service/#Wants=mariadb.service/g'  /usr/lib/systemd/system/asterisk.service
sed -i 's/After=mariadb.service/#After=mariadb.service/g'  /usr/lib/systemd/system/asterisk.service
ssh root@$ip_slave "sed -i 's/RestartSec=10/RestartSec=1/g'  /usr/lib/systemd/system/asterisk.service"
ssh root@$ip_slave "sed -i 's/Wants=mariadb.service/#Wants=mariadb.service/g'  /usr/lib/systemd/system/asterisk.service"
ssh root@$ip_slave "sed -i 's/After=mariadb.service/#After=mariadb.service/g'  /usr/lib/systemd/system/asterisk.service"
pcs resource create asterisk service:asterisk op monitor interval=30s
pcs cluster cib fs_cfg
pcs cluster cib-push fs_cfg --config
pcs -f fs_cfg constraint colocation add asterisk with virtual_ip INFINITY
pcs -f fs_cfg constraint order mysql then asterisk
pcs cluster cib-push fs_cfg --config
echo -e "*** Done ***"
echo -e "20"	> step.txt

compress_asterisk_files:
echo -e "************************************************************"
echo -e "*   Copy folders and files the DRBD partition on Master    *"
echo -e "************************************************************"
tar -zcvf /mnt/var-asterisk.tgz /var/log/asterisk 
tar -zcvf /mnt/var-lib-asterisk.tgz /var/lib/asterisk
tar -zcvf /mnt/var-lib-ombutel.tgz /var/lib/ombutel
tar -zcvf /mnt/usr-share-ombutel.tgz /usr/share/ombutel
tar -zcvf /mnt/usr-lib64-asterisk.tgz /usr/lib64/asterisk
tar -zcvf /mnt/var-spool-asterisk.tgz /var/spool/asterisk
tar -zcvf /mnt/etc-asterisk.tgz /etc/asterisk
echo -e "21"	> step.txt

copy_asterisk_files:
tar xvfz /mnt/var-asterisk.tgz -C /mnt/
tar xvfz /mnt/var-lib-asterisk.tgz -C /mnt/
tar xvfz /mnt/var-lib-ombutel.tgz -C /mnt/
tar xvfz /mnt/usr-share-ombutel.tgz -C /mnt/
tar xvfz /mnt/usr-lib64-asterisk.tgz -C /mnt/
tar xvfz /mnt/var-spool-asterisk.tgz -C /mnt/
tar xvfz /mnt/etc-asterisk.tgz -C /mnt/
echo -e "22"	> step.txt

remove_master_asterisk_files:
rm -f /mnt/var-asterisk.tgz 
rm -f /mnt/var-lib-asterisk.tgz
rm -f /mnt/var-lib-ombutel.tgz
rm -f /mnt/usr-share-ombutel.tgz
rm -f /mnt/usr-lib64-asterisk.tgz 
rm -f /mnt/var-spool-asterisk.tgz 
rm -f /mnt/etc-asterisk.tgz
rm -rf /var/log/asterisk 
rm -rf /var/lib/asterisk
rm -rf /var/lib/ombutel 
rm -rf /usr/share/ombutel 
rm -rf /usr/lib64/asterisk
rm -rf /var/spool/asterisk
rm -rf /etc/asterisk
echo -e "23"	> step.txt

create_symbolic_linlk_master_asterisk_files:
ln -s /mnt/var/log/asterisk /var/log/asterisk
ln -s /mnt/var/lib/asterisk /var/lib/asterisk
ln -s /mnt/var/lib/ombutel /var/lib/ombutel
ln -s /mnt/usr/share/ombutel /usr/share/ombutel
ln -s /mnt/usr/lib64/asterisk /usr/lib64/asterisk
ln -s /mnt/var/spool/asterisk /var/spool/asterisk
ln -s /mnt/etc/asterisk /etc/asterisk
ln -s /mnt/usr/share/ombutel /usr/share/ombutel
echo -e "*** Done ***"
echo -e "24"	> step.txt

remove_slave_asterisk_files:
echo -e "************************************************************"
echo -e "*           Configure symbolic links on Slave              *"
echo -e "************************************************************"
ssh root@$ip_slave 'rm -rf /var/log/asterisk'
ssh root@$ip_slave 'rm -rf /var/lib/asterisk'
ssh root@$ip_slave 'rm -rf /var/lib/ombutel'
ssh root@$ip_slave 'rm -rf /usr/share/ombutel'
ssh root@$ip_slave 'rm -rf /usr/lib64/asterisk'
ssh root@$ip_slave 'rm -rf /var/spool/asterisk'
ssh root@$ip_slave 'rm -rf /etc/asterisk'
echo -e "25"	> step.txt

create_symbolic_linlk_slave_asterisk_files:
ssh root@$ip_slave 'ln -s /mnt/var/log/asterisk /var/log/asterisk'
ssh root@$ip_slave 'ln -s /mnt/var/lib/asterisk /var/lib/asterisk'
ssh root@$ip_slave 'ln -s /mnt/var/lib/ombutel /var/lib/ombutel'
ssh root@$ip_slave 'ln -s /mnt/usr/share/ombutel /usr/share/ombutel'
ssh root@$ip_slave 'ln -s /mnt/usr/lib64/asterisk /usr/lib64/asterisk'
ssh root@$ip_slave 'ln -s /mnt/var/spool/asterisk /var/spool/asterisk'
ssh root@$ip_slave 'ln -s /mnt/etc/asterisk /etc/asterisk'
ssh root@$ip_slave 'ln -s /mnt/usr/share/ombutel /usr/share/ombutel'
echo -e "*** Done ***"
echo -e "26"	> step.txt

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
echo -e "27"	> step.txt

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
echo -e "28"	> step.txt

vitalpbx_cluster_bascul:
echo -e "************************************************************"
echo -e "*    Creating VitalPBX Cluster bascul_asterisk command     *"
echo -e "************************************************************"
cat > /usr/local/bin/bascul << EOF
#!/bin/bash
set -e
# Authors:      Rodrigo Cuadra
#               with Collaboration of Jose Miguel Rivera
#               06-Nov-2019
# Support:      rcuadra@aplitel.com
#

#funtion for draw a progress bar
#You must pass as argument the amount of secconds that the progress bar will run
# progress-bar 10 --> it will generate a progress bar that will run per 10 seconds
progress-bar() {
	local duration=\${1}

    already_done() { for ((done=0; done<\$elapsed; done++)); do printf "▇"; done }
    remaining() { for ((remain=\$elapsed; remain<\$duration; remain++)); do printf " "; done }
    percentage() { printf "| %s%%" \$(( ((\$elapsed)*100)/(\$duration)*100/100 )); }
    clean_line() { printf "\r"; }

	for (( elapsed=1; elapsed<=\$duration; elapsed++ )); do
		already_done; remaining; percentage
		sleep 1
		clean_line
	done
	clean_line
}

#Define some global variables
host_master=\`pcs status resources | awk '/Masters/ {print \$3}'\`
host_slave=\`pcs status resources | awk '/Slaves/ {print \$3}'\`
drbd_disk_status=\`drbdadm status | awk '/peer-disk/ {print \$1}'\`

#Perform some validations
if [ "\${host_master}" = "" ] || [ "\${host_slave}" = "" ]
then
    echo -e "\e[41m There are problems with high availability, please check with the command *pcs status* (we recommend applying the command *pcs cluster unstandby* in both servers) \e[0m"
    exit;
fi

if [ "\$drbd_disk_status" != "peer-disk:UpToDate" ]
then
	echo -e "\e[41m There are problems with high availability, please check with the command *drbdadm status* (we recommend applying the command *drbdadm up* in both servers) \e[0m"
	exit;
fi

# Print a warning message and ask to the user if he wants to continue
echo -e "************************************************************"
echo -e "*     Change the roles of servers in high availability     *"
echo -e "*\e[41m WARNING-WARNING-WARNING-WARNING-WARNING-WARNING-WARNING  \e[0m*"
echo -e "*All calls in progress will be lost and the system will be *"
echo -e "*     be in an unavailable state for a few seconds.        *"
echo -e "************************************************************"

#Perform a loop until the users confirm if wants to proceed or not
while [[ \$perform_bascul != yes && \$perform_bascul != no ]]; do
	read -p "Are you sure to switch from $host_master to $host_slave? (yes,no) > " perform_bascul
done

if [[ "\${perform_bascul}" = "yes" ]]; then
	#Unstandby both nodes
	pcs cluster unstandby $host_master
	pcs cluster unstandby $host_slave

	#Do a loop per resource
	pcs status resources | grep "^\s.*\s(.*):\s.*" | awk '{print \$1}' | while read -r resource ; do
		#Skip moving the virutal_ip resource, it will be moved at the end
		if [[ "\${resource}" != "virtual_ip" ]]; then
			echo "Moving \${resource} from \${host_master} to \${host_slave}"
			pcs resource move \${resource} \${host_slave}
		fi
	done

	sleep 5 && pcs cluster standby \$host_master & #Standby current Master node after five seconds
	sleep 20 && pcs cluster unstandby \$host_master & #Automatically Unstandby current Master node after 20 seconds

	#Move the Virtual IP resource to slave node
	echo "Moving virutal_ip from \${host_master} to \${host_slave}"
	pcs resource move virtual_ip \${host_slave}

	#End the script
	echo "Becoming \${host_slave} to Master"
	progress-bar 30
	echo "Done"
	pcs status resources
	drbdadm status
else
	echo "Nothing to do, bye, bye"
fi
EOF
chmod +x /usr/local/bin/bascul
scp /usr/local/bin/bascul root@$ip_slave:/usr/local/bin/bascul
ssh root@$ip_slave 'chmod +x /usr/local/bin/bascul'
cat > /usr/local/bin/role << EOF
#!/bin/bash
set -e
# Authors:      Rodrigo Cuadra
#               with Collaboration of Jose Miguel Rivera
#                               2019/11/06
# Support:      rcuadra@aplitel.com
#
host=\`hostname\`
server_mode=\`pcs status | grep ":\s\[\s\$host\s\]" | awk -F ":" '{print \$1}' | sed -e 's/^[[:space:]]*//'\`
echo ""
echo "Host Local: " \$host
echo "Role:       " \$server_mode
echo ""
echo "Disk Status"
drbdadm status
EOF
chmod +x /usr/local/bin/role
scp /usr/local/bin/role root@$ip_slave:/usr/local/bin/role
ssh root@$ip_slave 'chmod +x /usr/local/bin/role'

cat > /usr/local/bin/drbdsplit << EOF
#!/bin/bash
set -e
# Authors:      Rodrigo Cuadra
#               with Collaboration of Jose Miguel Rivera
#                               2019/11/06
# Support:      rcuadra@aplitel.com
#
drbdadm secondary drbd0
drbdadm disconnect drbd0
drbdadm -- --discard-my-data connect drbd0
ssh root@$ip_slave "drbdadm connect drbd0"
echo "Disk Status"
drbdadm status
EOF
chmod +x /usr/local/bin/drbdsplit
cat > /tmp/drbdsplit << EOF
#!/bin/bash
set -e
# Authors:      Rodrigo Cuadra
#               with Collaboration of Jose Miguel Rivera
#                               2019/11/06
# Support:      rcuadra@aplitel.com
#
drbdadm secondary drbd0
drbdadm disconnect drbd0
drbdadm -- --discard-my-data connect drbd0
ssh root@$ip_master "drbdadm connect drbd0"
echo "Disk Status"
drbdadm status
EOF
scp /tmp/drbdsplit root@$ip_slave:/usr/local/bin/drbdsplit
ssh root@$ip_slave 'chmod +x /usr/local/bin/drbdsplit'
echo -e "*** Done ***"
echo -e "29"	> step.txt

ceate_welcome_message:
echo -e "************************************************************"
echo -e "*              Creating Welcome message                    *"
echo -e "************************************************************"
cat > /etc/profile.d/vitalwelcome.sh << EOF
#!/bin/bash
#Bash Colour Codes
green="\033[00;32m"
txtrst="\033[00;0m"

if [ -f /etc/redhat-release ]; then
        linux_ver=\`cat /etc/redhat-release\`
        vitalpbx_ver=\`rpm -qi vitalpbx |awk -F: '/^Version/ {print \$2}'\`
        vitalpbx_release=\`rpm -qi vitalpbx |awk -F: '/^Release/ {print \$2}'\`
elif [ -f /etc/debian_version ]; then
        linux_ver="Debian "\`cat /etc/debian_version\`
        vitalpbx_ver=\`dpkg -l vitalpbx |awk '/ombutel/ {print \$3}'\`
else
        linux_ver=""
        vitalpbx_ver=""
        vitalpbx_release=""
fi
vpbx_version="\${vitalpbx_ver}-\${vitalpbx_release}"
asterisk_version=\`rpm -q --qf "%{VERSION}" asterisk\`
host=\`hostname\`
server_mode=\`pcs status | grep ":\s\[\s\$host\s\]" | awk -F ":" '{print \$1}' | sed -e 's/^[[:space:]]*//'\`
logo='
 _    _ _           _ ______ ______ _    _
| |  | (_)_        | (_____ (____  \ \  / /
| |  | |_| |_  ____| |_____) )___)  ) \/ /
 \ \/ /| |  _)/ _  | |  ____/  __  ( )  (
  \  / | | |_( ( | | | |    | |__)  ) /\ \\
   \/  |_|\___)_||_|_|_|    |______/_/  \_\\
'
echo -e "
\${green}
\${logo}
\${txtrst}

 Role           : \$server_mode
 Version        : \${vpbx_version//[[:space:]]}
 Asterisk       : \${asterisk_version}
 Linux Version  : \${linux_ver}
 Welcome to     : \`hostname\`
 Uptime         : \`uptime | grep -ohe 'up .*' | sed 's/up //g' | awk -F "," '{print \$1}'\`
 Load           : \`uptime | grep -ohe 'load average[s:][: ].*' | awk '{ print "Last Minute: " \$3" Last 5 Minutes: "\$4" Last 15 Minutes: "\$5 }'\`
 Users          : \`uptime | grep -ohe '[0-9.*] user[s,]'\`
 IP Address     : \${green}\`ip addr | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | xargs\`\${txtrst}
 Clock          :\`timedatectl | sed -n '/Local time/ s/^[ \t]*Local time:\(.*$\)/\1/p'\`
 NTP Sync.      :\`timedatectl |awk -F: '/NTP sync/ {print \$2}'\`
"
EOF

chmod 755 /etc/profile.d/vitalwelcome.sh
echo -e "*** Done ***"
scp /etc/profile.d/vitalwelcome.sh root@$ip_slave:/etc/profile.d/vitalwelcome.sh
ssh root@$ip_slave "chmod 755 /etc/profile.d/vitalwelcome.sh"
echo -e "*** Done ***"
echo -e "30"	> step.txt

vitalpbx_cluster_ok:
echo -e "************************************************************"
echo -e "*                VitalPBX Cluster OK                       *"
echo -e "************************************************************"
ssh root@$ip_slave "systemctl restart corosync.service"
ssh root@$ip_slave "systemctl restart pacemaker.service"
mkdir -p /etc/systemd/system/pacemaker.service.d 
echo "[Unit] After=dbus.service" > /etc/systemd/system/pacemaker.service.d/after-dbus.conf
systemctl daemon-reload
ssh root@$ip_slave "mkdir -p /etc/systemd/system/pacemaker.service.d"
ssh root@$ip_slave "echo '[Unit] After=dbus.service' > /etc/systemd/system/pacemaker.service.d/after-dbus.conf"
ssh root@$ip_slave "systemctl daemon-reload"
sleep 5
pcs status resources
drbdadm status
echo -e "************************************************************"
echo -e "*       Before restarting the servers wait for drbd        *"
echo -e "*            to finish synchronizing the disks             *"
echo -e "*    Use the *drbdadm status* command to see its status    *"
echo -e "************************************************************"
echo -e "*** Done ***"
