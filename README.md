VitalPBX High Availability
=====
![VitalPBX HA](https://github.com/VitalPBX/vitalpbx_ha/blob/master/VitalPBX_HA.png)

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

-----------------
1.- Prerequisites
In order to install VitalPBX in high availability you need the following:<br>
a.- 3 IP addresses.<br>
b.- Install VitalPBX on two servers with similar characteristics.<br>
c.- At the time of installation leave the largest amount of space on the hard drive to store the variable data on both servers.<br>

2.- We are going to start installing VitalPBX on two servers<br>
a.- When starting the installation go to "INSTALLATION DESTINATION (Custom partitioning selected)".<br>
b.- Select "I will configurate partitioning" and press "Done" button.<br>
b.- Select the "/" partition, change the "Desired Capacity" to 20GB (we need enough space for operating system and its applications in the future), click Modify button, select disk and press "Select" button and "Update Settings" button.<br>
e.- Finally we press the "Done" button and press "Accept Changes" button and continue with the installation.<br>

3.- We will configure each server the IP address and the host name. Go to the web interface to: Admin/System Settinngs/Network Settings.<br>
<strong>Master</strong><br>
a.- Hostname: <strong>vitalpbx1.local</strong> (then press check button) <br>
b.- DHCP: <strong>No</strong><br>
c.- IP Address: <strong>192.168.30.10</strong><br>
d.- Netmask: <strong>255.255.248.0</strong><br>
e.- Gateway: <strong>192.168.24.1</strong><br>
f.- Primary DNS: <strong>8.8.8.8</strong><br>
g.- Secundary DNS: <strong>8.8.4.4</strong><br>
<strong>Slave</strong><br>
a.- Hostname: <strong>vitalpbx2.local</strong> (then press check button) <br>
b.- DHCP: <strong>No</strong><br>
c.- IP Address: <strong>192.168.30.20</strong><br>
d.- Netmask: <strong>255.255.248.0</strong><br>
e.- Gateway: <strong>192.168.24.1</strong><br>
f.- Primary DNS: <strong>8.8.8.8</strong><br>
g.- Secundary DNS: <strong>8.8.4.4</strong><br>

4.- Now we connect with ssh to each of the servers.<br>
a.- Initialize the partition to assign the remainder of the hard disk in both servers<br>
[root@vitalpbx1-2 ~]#  fdisk /dev/sda<br>
Command (m for help): <strong>n</strong><br>
Select (default e): <strong>p</strong><br>
Selected partition <strong>x</strong> (take note of the assigned partition number as we will need it later)<br>
<strong>[Enter]</strong><br>
<strong>[Enter]</strong><br>
Command (m for help): <strong>w</strong><br>
[root@vitalpbx1-2 ~]#  <strong>reboot</strong><br>

5.- Install on both srrvers<br>
[root@vitalpbx1-2 ~]#  yum -y install drbd90-utils kmod-drbd90 corosync pacemaker pcs<br>

6.- install the script<br>
[root@vitalpbx1 ~]#  cd /<br>
[root@vitalpbx1 ~]#  wget https://raw.githubusercontent.com/VitalPBX/vitalpbx_ha/master/vital_ha.sh<br>
[root@vitalpbx1 ~]#  chmod +x vital_ha.sh<br>
[root@vitalpbx1 ~]#  ./vital_ha.sh<br>
