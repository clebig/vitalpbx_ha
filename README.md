VitalPBX High Availability
=====
High availability is a characteristic of a system which aims to ensure an agreed level of operational performance, usually uptime, for a higher than normal period.<br>

Make a high-availability cluster out of any pair of VitalPBX servers. VitalPBX can detect a range of failures on one VitalPBX server and automatically transfer control to the other server, resulting in a telephony environment with minimal down time.<br>

## Example:<br>
![VitalPBX HA](https://github.com/VitalPBX/vitalpbx_ha/blob/master/VitalPBX_HA.png)

-----------------
## Prerequisites
In order to install VitalPBX in high availability you need the following:<br>
a.- 3 IP addresses.<br>
b.- Install VitalPBX on two servers with similar characteristics.<br>
c.- At the time of installation leave the largest amount of space on the hard drive to store the variable data on both servers.<br>

## Installation
We are going to start by installing VitalPBX on two servers
<pre>
a.- When starting the installation go to:
<strong>INSTALLATION DESTINATION (Custom partitioning selected)</strong><br>
b.- Select:
<strong>I will configure partitioning</strong>
And press the button
<strong>Done</strong><br>
c.- Select the root partition:
<strong>/</strong>
Change the capacity to:
<strong>Desired Capacity: 20GB</strong>
We need enough space for the operating system and its applications in the future; then click<br>
<strong>Modify button</strong>
Select disk and press the buttons 
<strong>Select</strong>
<strong>Update Settings</strong><br>
d.- Finally, we press the button:
<strong>Done</strong>
And press the button
<strong>Accept Changes</strong>
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

## Install Dependencies
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
Set these values, remember the Floating IP Mask must be 2 digit format (SIDR) and the Disk is that you created in the step “Create Disk”:
<pre>
IP Master.......... > <strong>192.168.30.10</strong>
IP Slave........... > <strong>192.168.30.20</strong>
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

Now, reboot the server1 and wait for status change in server2.<br>
<pre>
[root@vitalpbx1 ~]# reboot
[root@vitalpbx2 ~]# pcs status
</pre>

Then reboot the server2, connect to server1 and wait for status change in server1.
<pre>
[root@vitalpbx2 ~]# reboot
[root@vitalpbx1 ~]# pcs status
</pre>

## Test

To execute the process of changing the role, we recommend using the following command:<br>

<pre>
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

## Update

To update VitalPBX to the latest version just follow the following steps:<br>
1.- From your browser, go to ip 192.168.30.30<br>
2.- Update VitalPBX from the interface<br>
3.- Execute the following command in Master console<br>
<pre>
[root@vitalpbx1 /]# bascul
</pre>
4.- From your browser, go to ip 192.168.30.30 again<br>
5.- Update VitalPBX from the interface<br>
6.- Execute the following command in Master console<br>
<pre>
[root@vitalpbx1 /]# bascul
</pre>

<strong>CONGRATULATIONS</strong>, you have installed and tested the high availability in <strong>VitalPBX</strong><br>
:+1:




