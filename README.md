VitalPBX High Availability
=====
High availability is a characteristic of a system which aims to ensure an agreed level of operational performance, usually uptime, for a higher than normal period.<br>

make a high-availability cluster out of any pair of VitalPBX servers. VitalPBX can detect a range of failures on one VitalPBX server and automatically transfer control to the other server, resulting in a telephony environment with minimal down time.<br>

![VitalPBX HA](https://github.com/VitalPBX/vitalpbx_ha/blob/master/VitalPBX_HA.png)

## Example:<br>
| Name          | Master           | Slave            |
| ------------- | ---------------- | ---------------- |
| Host Name     | vitalpbx1.local  | vitalpbx2.local  |
| IP Address    | 192.168.30.10    | 192.168.30.20    |
| Netmask       | 255.255.248.0    | 255.255.248.0    |
| Gateway       | 192.168.24.1     | 192.168.24.1     |
| Primary DNS   | 8.8.8.8          | 8.8.8.8          |
| Secundary DNS | 8.8.4.4          | 8.8.4.4          |

| Floating IP     | Netmask   |
| --------------- | --------- |
| 192.168.30.30   | 21        |


-----------------
## Prerequisites
In order to install VitalPBX in high availability you need the following:<br>
a.- 3 IP addresses.<br>
b.- Install VitalPBX on two servers with similar characteristics.<br>
c.- At the time of installation leave the largest amount of space on the hard drive to store the variable data on both servers.<br>

## Installation
We are going to start by installing VitalPBX on two servers<br>
a.- When starting the installation go to:<br>
<pre>
INSTALLATION DESTINATION (Custom partitioning selected)
</pre>
b.- Select:
<pre>
I will configure partitioning
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
We need enough space for the operating system and its applications in the future; then click<br>
<pre>
Modify button
</pre>
Select disk and press the buttons 
<pre>
Select
Update Settings
</pre>
e.- Finally, we press the button:
<pre>
Done
</pre>
And press the button
</pre>
Accept Changes
</pre>
And continue with the installation.<br>

## Configurations
We will configure in each server the IP address and the host name. Go to the web interface to: Admin>System Settinngs>Network Settings.<br>
First change the Hostname, remember press the Check button.<br>
Disable the DHCP option and set these values<br>

| Name          | Master           | Slave            |
| ------------- | ---------------- | ---------------- |
| Hostname      | vitalpbx1.local  | vitalpbx2.local  |
| IP Address    | 192.168.30.10    | 192.168.30.20    |
| Netmask       | 255.255.248.0    | 255.255.248.0    |
| Gateway       | 192.168.24.1     | 192.168.24.1     |
| Primary DNS   | 8.8.8.8          | 8.8.8.8          |
| Secondary DNS | 8.8.4.4          | 8.8.4.4          |

## Create Disk
Now we connect through ssh to each of the servers.<br>
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
Install the necessary dependencies on both servers<br>
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

Are you sure to continue with these settings? (yes,no) > <strong>yes</strong>

Are you sure you want to continue connecting (yes/no)? <strong>yes</strong>

root@192.168.30.20's password: <strong>The root password from Slave Server</strong>
</pre>

At the end of the installation you have to see the following message

<pre>
************************************************************
*                VitalPBX Cluster OK                       *
************************************************************
 virtual_ip     (ocf::heartbeat:IPaddr2):       Started vitalpbx1.local
 Master/Slave Set: DrbdDataClone [DrbdData]
     Masters: [ vitalpbx1.local ]
     Slaves: [ vitalpbx2.local ]
 DrbdFS (ocf::heartbeat:Filesystem):    Started vitalpbx1.local
 mysql  (ocf::heartbeat:mysql): Started vitalpbx1.local
 asterisk       (ocf::heartbeat:asterisk):      Started vitalpbx1.local
 fail2ban       (service:fail2ban):     Started vitalpbx1.local
 vpbx-monitor   (service:vpbx-monitor): Started vitalpbx1.local
*** Done ***
</pre>

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
 fail2ban       (service:fail2ban):     Started vitalpbx1.local
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
 fail2ban       (service:fail2ban):     Started vitalpbx1.local
 vpbx-monitor   (service:vpbx-monitor): Started vitalpbx2.local
</pre>

All services moved to server2.<br>

Now turn on server1. You will see that the services continue on server2. To return everything to normal on server2, execute the following command:<br>
<pre>
[root@vitalpbx2 /]# <strong>pcs cluster standby vitalpbx2.local</strong>
</pre>

Server1 takes control again. <br>
<pre>
[root@vitalpbx1 ~]# pcs status resources
 virtual_ip     (ocf::heartbeat:IPaddr2):       Started vitalpbx1.local
 Master/Slave Set: DrbdDataClone [DrbdData]
     Masters: [ vitalpbx1.local ]
     <strong>Stopped</strong>: [ vitalpbx2.local ]
 DrbdFS (ocf::heartbeat:Filesystem):    Started vitalpbx1.local
 mysql  (ocf::heartbeat:mysql): Started vitalpbx1.local
 asterisk       (ocf::heartbeat:asterisk):      Started vitalpbx1.local
 fail2ban       (service:fail2ban):     Started vitalpbx1.local
 vpbx-monitor   (service:vpbx-monitor): Started vitalpbx1.local
</pre>

We see that the server2 is in the stop state, therefore we must return it to normal state again by applying the following command:<br>

<pre>
[root@vitalpbx2 /]# <strong>pcs cluster unstandby vitalpbx2.local</strong>
</pre>

To execute the process of changing the role automatically, we recommend downloading the following scripts:<br>

<pre>
[root@vitalpbx1-2 /]# wget https://github.com/VitalPBX/vitalpbx_ha/blob/master/bascul
[root@vitalpbx1-2 /]# chmod +x bascul
[root@vitalpbx1-2 /]# mv bascul /usr/local/bin
[root@vitalpbx1-2 /]# bascul
************************************************************
*     Change the roles of servers in high availability     *
* <strong>WARNING-WARNING-WARNING-WARNING-WARNING-WARNING-WARNING</strong>  *
*All calls in progress will be lost and the system will be *
*     be in an unavailable state for a few seconds.        *
************************************************************
Are you sure to switch from vitalpbx1.local to vitalpbx2.local? (yes,no) >
</pre>

This action convert the vitalpbx1.local to Slave and vitalpbx2.local to Master. If you want to return to default do the same again.<br>

<strong>CONGRATULATIONS</strong>, you have installed and tested the high availability in <strong>VitalPBX</strong><br>
:+1:




