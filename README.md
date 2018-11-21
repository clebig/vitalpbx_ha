VitalPBX High Availability
High availability is a characteristic of a system, which aims to ensure an agreed level of operational performance, usually uptime, for a higher than normal period.<br>
=====
![VitalPBX HA](https://github.com/VitalPBX/vitalpbx_ha/blob/master/VitalPBX_HA.png)

## Example:<br>
### Master<br>
Host Name Master: vitalpbx1.local<br>
IP Master: 192.168.30.10<br>
Netmask: 255.255.248.0<br>
Gateway: 192.168.24.1<br>
Primary DNS: 8.8.8.8<br>
Secundary DNS: 8.8.4.4<br>

### Slave<br>
Host name Slave: vitalpbx2.local<br>
IP Slave: 192.168.30.20<br>
Netmask: 255.255.248.0<br>
Gateway: 192.168.24.1<br>
Primary DNS: 8.8.8.8<br>
Secundary DNS: 8.8.4.4<br>

Floating IP: 192.168.30.30<br>
Netmask: 21<br>

-----------------
## Prerequisites
In order to install VitalPBX in high availability you need the following:<br>
a.- 3 IP addresses.<br>
b.- Install VitalPBX on two servers with similar characteristics.<br>
c.- At the time of installation leave the largest amount of space on the hard drive to store the variable data on both servers.<br>

## Installation
We are going to start installing VitalPBX on two servers<br>
a.- When starting the installation go to:<br>
<pre>
INSTALLATION DESTINATION (Custom partitioning selected)
</pre>
b.- Select:
<pre>
I will configurate partitioning
</pre>
And press the button
<pre>
Done
</pre>
b.- Select the root partition:
<pre>
/ 
</pre>
Change the capacity to:
<pre>
Desired Capacity: 20GB
</pre>
We need enough space for operating system and its applications in the future, then click<br>
<pre>
Modify button
</pre>
Select disk and press the bttons 
<pre>
Select
Update Settings
</pre>
e.- Finally we press the button:
<pre>
Done
</pre>
And press the button
</pre>
Accept Changes
</pre>
And continue with the installation.<br>

## Configurations
We will configure each server the IP address and the host name. Go to the web interface to: Admin/System Settinngs/Network Settings.<br>
### Master
a.- Hostname: <strong>vitalpbx1.local</strong> (then press check button) <br>
b.- DHCP: <strong>No</strong><br>
c.- IP Address: <strong>192.168.30.10</strong><br>
d.- Netmask: <strong>255.255.248.0</strong><br>
e.- Gateway: <strong>192.168.24.1</strong><br>
f.- Primary DNS: <strong>8.8.8.8</strong><br>
g.- Secundary DNS: <strong>8.8.4.4</strong><br>
### Slave
a.- Hostname: <strong>vitalpbx2.local</strong> (then press check button) <br>
b.- DHCP: <strong>No</strong><br>
c.- IP Address: <strong>192.168.30.20</strong><br>
d.- Netmask: <strong>255.255.248.0</strong><br>
e.- Gateway: <strong>192.168.24.1</strong><br>
f.- Primary DNS: <strong>8.8.8.8</strong><br>
g.- Secundary DNS: <strong>8.8.4.4</strong><br>

## Create Disk
Now we connect with ssh to each of the servers.<br>
a.- Initialize the partition to allocate the available space on the hard disk. Do these on both servers.<br>
<pre>
[root@vitalpbx1-2 ~]#  fdisk /dev/sda
Command (m for help): <strong>n</strong>
Select (default e): <strong>p</strong><br>
Selected partition <strong>x</strong> (take note of the assigned partition number as we will need it later)
<strong>[Enter]</strong>
<strong>[Enter]</strong>
Command (m for help): <strong>w</strong>
[root@vitalpbx1-2 ~]#  <strong>reboot</strong>
</pre>

## Install Apps
Install the necessary applications on both servers<br>
<pre>
[root@vitalpbx1-2 ~]#  yum -y install drbd90-utils kmod-drbd90 corosync pacemaker pcs<br>
</pre>

## Script
Now copy and run the following script<br>
<pre>
[root@vitalpbx1 ~]#  cd /
[root@vitalpbx1 ~]#  wget https://raw.githubusercontent.com/VitalPBX/vitalpbx_ha/master/vital_ha.sh
[root@vitalpbx1 ~]#  chmod +x vital_ha.sh
[root@vitalpbx1 ~]#  ./vital_ha.sh
</pre>

<pre>
IP Master.......... > <strong>192.168.30.10</strong>
Host Name Master... > <strong>vitalpbx1.loca</strong>
IP Slave........... > <strong>192.168.30.20</strong>
Host Name Slave.... > <strong>vitalpbx2.local</strong>
Floating IP........ > <strong>192.168.30.30</strong>
Floating IP Mask... > <strong>21</strong>
Disk (sdax)........ > <strong>sda4</strong>
hacluster password. > <strong>mypassword</strong>

Are you sure to continue with this settings? (yes,no) > <strong>yes</strong>

Are you sure you want to continue connecting (yes/no)? <strong>yes</strong>

root@192.168.30.20's password: <strong>The root password of Slave Server</strong>
</pre>

:+1:

## Test<br>

To see the status of the cluster use the following command:<br>
<pre>
[root@vitalpbx1 /]# <strong>pcs status resources</strong>
</pre>

If all is well, you will see the following<br>

<pre>
 virtual_ip     (ocf::'heartbeat':IPaddr2):       Started vitalpbx1.local
 Master/Slave Set: DrbdDataClone [DrbdData]
     Masters: [ vitalpbx1.local ]
     Slaves: [ vitalpbx2.local ]
 DrbdFS (ocf::'heartbeat':Filesystem):    Started vitalpbx1.local
 mysql  (ocf::'heartbeat':mysql): Started vitalpbx1.local
 asterisk       (ocf::'heartbeat':asterisk):      Started vitalpbx1.local
 vpbx-monitor   (service:vpbx-monitor): Started vitalpbx1.local
</pre>

Poweroff the Server1 vitalpbx1.local, and check the server2 vitalpbx2.local<br>
<pre>
[root@vitalpbx2 /]# <strong>pcs status resources</strong>
 virtual_ip     (ocf::heartbeat:IPaddr2):       Started vitalpbx2.local
 Master/Slave Set: DrbdDataClone [DrbdData]
     Masters: [ vitalpbx2.local ]
     Stopped: [ vitalpbx1.local ]
 DrbdFS (ocf::heartbeat:Filesystem):    Started vitalpbx2.local
 mysql  (ocf::heartbeat:mysql): Started vitalpbx2.local
 asterisk       (ocf::heartbeat:asterisk):      Started vitalpbx2.local
 vpbx-monitor   (service:vpbx-monitor): Started vitalpbx2.local
</pre>

All services moved to server2.<br>

Now turn on the server1. You will see that the services continue on the server2. To return everything to normal on server2, execute the following command:<br>
<pre>
[root@vitalpbx2 /]# <strong>pcs cluster standby vitalpbx2.local</strong>
</pre>

The server1 takes control again. <br>
<pre>
[root@vitalpbx1 ~]# pcs status resources
 virtual_ip     (ocf::heartbeat:IPaddr2):       Started vitalpbx1.local
 Master/Slave Set: DrbdDataClone [DrbdData]
     Masters: [ vitalpbx1.local ]
     <strong>Stopped</strong>: [ vitalpbx2.local ]
 DrbdFS (ocf::heartbeat:Filesystem):    Started vitalpbx1.local
 mysql  (ocf::heartbeat:mysql): Started vitalpbx1.local
 asterisk       (ocf::heartbeat:asterisk):      Started vitalpbx1.local
 vpbx-monitor   (service:vpbx-monitor): Started vitalpbx1.local
</pre>

We see that the server2 is in the stop state, this is why we must return it to normal state again by applying the following command:<br>

<pre>
[root@vitalpbx2 /]# <strong>pcs cluster unstandby vitalpbx2.local</strong>
</pre>





