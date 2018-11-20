# vitalpbx_ha
italPBX Hih Availability

Example:<br>
Master<br>
Host Name Master: vitalpbx1.local<br>
IP Master: 192.168.30.10<br>
Netmask: 255.255.248.0<br>
Gateway: 192.168.24.1<br>
Primary DNS: 8.8.8.8<br>
Secundary DNS: 8.8.4.4<br>

Slave<br>
Host name Slave: vitalpbx2.local<br>
IP Slave: 192.168.30.20<br>
Netmask: 255.255.248.0<br>
Gateway: 192.168.24.1<br>
Primary DNS: 8.8.8.8<br>
Secundary DNS: 8.8.4.4<br>

Floating IP: 192.168.30.30<br>
Netmask: 21<br>


1.- Prerequisites
In order to install VitalPBX in high availability you need the following:<br>
a.- 3 IP addresses.<br>
b.- Install VitalPBX on two servers with similar characteristics.<br>
c.- At the time of installation leave the largest amount of space on the hard drive to store the variable data on both servers.<br>

2.- We are going to start installing VitalPBX on two servers<br>
a.- When starting the installation go to "INSTALLATION DESTINATION (Custom partitioning selected)".<br>
b.- Now we will remove the "/" partitions to create a new one with less hard disk space. Select the partition and press the button with the minus sign (-) at the bottom. <br>
c.- Now press the plus button (+) and select in Mount Point: the root partition (/), and in Desired Capacity: 20GB (Or another enough value to reach the operating system and its applications in the future). Then press the "Add mount point" button.<br>
d.- Then go to the "Device Type" and select Standard Partition and also go to "File System:" and select "ext4" and press the "Update Settigs" button.<br>
e.- Finally we press the "Done" button and press "Accept Changes" button and continue with the installation.<br>

3.- We will configure each server the IP address and the host name. Go to the web interface to: Admin/System Settinngs/Network Settings.<br>
a.- Hostname: Your hostname (then press check button) <br>
b.- DHCP: No<br>
c.- IP Address: Your IP<br>
d.- Netmask: Yor netmask<br>
e.- Gateway: Your gateway<br>
f.- Primary DNS: Your primary DNS<br>
g.- Secundary DNS: Your secundary DNS<br>

4.- Now we connect by means of ssh to each of the servers.<br>
a.- Initialize the partition to assign the remainder of the hard disk in both servers<br>
[root@vitalpbx1-2 ~]#  fdisk /dev/sda<br>
Command (m for help): <strong>n</strong><br>
Select (default e): <strong>p</strong><br>
Selected partition <strong>x</strong> (take note of the assigned partition number as we will need it later)<br>
<strong>[Enter]</strong><br>
<strong>[Enter]</strong><br>
Command (m for help): <strong>w</strong><br>
[root@vitalpbx1-2 ~]#  <strong>reboot</strong><br>

b.- Now we will proceed to format the new partition with the following command on both servers<br>
[root@vitalpbx1-2 ~]#  mke2fs -j /dev/sda<strong>x</strong> (replace the x with the partition number assigned in the previous point)<br>
[root@vitalpbx1-2 ~]#  dd if=/dev/zero bs=1M count=500 of=/dev/sda4; sync<br>

5.- Install on both srrvers<br>
[root@vitalpbx1-2 ~]#  yum -y install drbd90-utils kmod-drbd90 corosync pacemaker pcs<br>

6.- install the script<br>
[root@vitalpbx1 ~]#  cd /<br>
[root@vitalpbx1 ~]#  wget https://raw.githubusercontent.com/VitalPBX/vitalpbx_ha/master/vital_ha.sh<br>
[root@vitalpbx1 ~]#  chmod +x vital_ha.sh<br>
[root@vitalpbx1 ~]#  ./vital_ha.sh<br>
