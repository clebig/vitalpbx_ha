VitalPBX High Availability (Version 2)
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

| Name          | Master                 | Slave                 |
| ------------- | ---------------------- | --------------------- |
| Hostname      | vitalpbx-master.local  | vitalpbx-slave.local  |
| IP Address    | 192.168.30.10          | 192.168.30.20         |
| Netmask       | 255.255.248.0          | 255.255.248.0         |
| Gateway       | 192.168.24.1           | 192.168.24.1          |
| Primary DNS   | 8.8.8.8                | 8.8.8.8               |
| Secondary DNS | 8.8.4.4                | 8.8.4.4               |

## Create Disk
Now we connect through ssh to each of the servers.<br>
a.- Initialize the partition to allocate the available space on the hard disk. Do these on both servers.<br>
<pre>
[root@vitalpbx-master ~]#  fdisk /dev/sda
Command (m for help): <strong>n</strong>
Select (default e): <strong>p</strong><br>
Selected partition <strong>x</strong> (take note of the assigned partition number as we will need it later)
<strong>[Enter]</strong>
<strong>[Enter]</strong>
Command (m for help): t
Partition number (1-4, default 4): 4
Hex code (type L to list all codes): 8e
Changed type of partition 'Linux' to 'Linux LVM'
Command (m for help): <strong>w</strong>
[root@vitalpbx-master ~]#  <strong>reboot</strong>
</pre>

## Install Dependencies
Install the necessary dependencies on both servers<br>
<pre>
[root@vitalpbx-master ~]#  yum -y install drbd90-utils kmod-drbd90 corosync pacemaker pcs<br>
[root@vitalpbx-slave ~]#  yum -y install drbd90-utils kmod-drbd90 corosync pacemaker pcs<br>
</pre>

## Script
Now copy and run the following script<br>
<pre>
[root@vitalpbx-master ~]#  cd /
[root@vitalpbx-master ~]#  wget https://raw.githubusercontent.com/VitalPBX/vitalpbx_ha/master/vital_ha.sh
[root@vitalpbx-master ~]#  chmod +x vital_ha.sh
[root@vitalpbx-master ~]#  ./vital_ha.sh
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
virtual_ip     (ocf::heartbeat:IPaddr2):       Started vitalpbx-master.local
Master/Slave Set: DrbdDataClone [DrbdData]
     Masters: [ vitalpbx-master.local ]
     Slaves: [ vitalpbx-slave.local ]
DrbdFS (ocf::heartbeat:Filesystem):    Started vitalpbx-master.local
mysql  (ocf::heartbeat:mysql): Started vitalpbx-master.local
dahdi  (service:dahdi):        Started vitalpbx-master.local
asterisk       (service:asterisk):     Started vitalpbx-master.local
vpbx-monitor   (service:vpbx-monitor): Started vitalpbx-master.local
fail2ban       (service:fail2ban):     Started vitalpbx-master.local
drbd0 role:Primary
  disk:UpToDate
  vitalpbx-slave.local role:Secondary
  peer-disk:UpToDate

************************************************************
*       Before restarting the servers wait for drbd        *
*            to finish synchronizing the disks             *
*    Use the *drbdadm status* command to see its status    *
************************************************************
*** Done ***
</pre>

Now check if drbd has finished synchronizing the discs 
<pre>

[root@vitalpbx-master ~]# drbdadm status
drbd0 role:Primary
  disk:UpToDate
  vitalpbx2.local role:Secondary
    peer-disk:UpToDate

[root@vitalpbx-master ~]#
</pre>
If it shows the previous message it means that everything is fine and we can continue, otherwise we have to wait for it to finish synchronizing.

Now, reboot the vitalpbx-master and wait for status change in vitalpbx-slave.<br>
<pre>
[root@vitalpbx-master ~]# reboot

[root@vitalpbx-slave ~]# pcs status
</pre>

Then reboot the vitalpbx-slave, connect to vitalpbx-master and wait for status change in server1.
<pre>
[root@vitalpbx-slave ~]# reboot

[root@vitalpbx-master ~]# pcs status
</pre>

## Test

To execute the process of changing the role, we recommend using the following command:<br>

<pre>
[root@vitalpbx-master /]# bascul
************************************************************
*     Change the roles of servers in high availability     *
* <strong>WARNING-WARNING-WARNING-WARNING-WARNING-WARNING-WARNING</strong>  *
*All calls in progress will be lost and the system will be *
*     be in an unavailable state for a few seconds.        *
************************************************************
Are you sure to switch from vitalpbx-master.local to vitalpbx-slave.local? (yes,no) >
</pre>

This action convert the vitalpbx-master.local to Slave and vitalpbx-slave.local to Master. If you want to return to default do the same again.<br>

Next we will show a short video how high availability works in VitalPBX<br>
<div align="center">
  <a href="https://www.youtube.com/watch?v=3yoa3KXKMy0"><img src="https://img.youtube.com/vi/3yoa3KXKMy0/0.jpg" alt="High Availability demo video on VitalPBX"></a>
</div>

## Turn on and turn off
When you have to turn off the servers, when you turn it on always start with the Master, wait for the Master to start and then turn on the Slave<br>

## Sonata Switchboard
If you are going to install Sonata Switchboard we recommend you to execute the following commands in the Master

<pre>
[root@vitalpbx1 ~]# systemctl stop switchboard
[root@vitalpbx1 ~]# systemctl disable switchboard
[root@vitalpbx1 ~]# pcs resource create switchboard service:switchboard op monitor interval=30s
[root@vitalpbx1 ~]# pcs cluster cib fs_cfg
[root@vitalpbx1 ~]# pcs cluster cib-push fs_cfg --config
[root@vitalpbx1 ~]# pcs -f fs_cfg constraint colocation add switchboard with virtual_ip INFINITY
[root@vitalpbx1 ~]# pcs -f fs_cfg constraint order asterisk then switchboard
[root@vitalpbx1 ~]# pcs cluster cib-push fs_cfg --config
</pre>

and in the Slave

<pre>
[root@vitalpbx2 ~]# systemctl stop switchboard
[root@vitalpbx2 ~]# systemctl disable switchboard
</pre>

## Update VitalPBX version

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

## Some useful commands
• <strong>bascul</strong>, is used to change roles between high availability servers. If all is well, a confirmation question should appear if we wish to execute the action.<br>
• <strong>role</strong>, shows the status of the current server. If all is well you should return Masters or Slaves.<br>
• <strong>pcs resource refresh --full</strong>, to poll all resources even if the status is unknown, enter the following command.<br>
• <strong>pcs cluster unstandby host</strong>, in some cases the bascul command does not finish tilting, which causes one of the servers to be in standby (stop), with this command the state is restored to normal.<br>
• <strong>drbdadm status</strong>, shows the integrity status of the disks that are being shared between both servers in high availability. If for some reason the status of Connecting or Standalone returns to us, wait a while and if the state remains it is because there are synchronization problems between both servers and you should execute the drbdsplit command.<br>
• <strong>drbdsplit</strong>, solves DRBD split brain recovery.<br>

<strong>CONGRATULATIONS</strong>, you have installed and tested the high availability in <strong>VitalPBX</strong><br>
:+1:
