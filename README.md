# vitalpbx_ha
VitalPBX High Availability

Prerequisites
In order to install VitalPBX in high availability you need the following:<br>
a.- 3 IP addresses.<br>
b.- Install VitalPBX on two servers with similar characteristics.<br>
c.- At the time of installation leave the largest amount of space on the hard drive to store the variable data on both servers.<br>

We are going to start installing VitalPBX on two servers<br>

1.- When starting the installation go to "INSTALLATION DESTINATION (Custom partitioning selected)".<br>
2.- Now we will remove the "/" partitions to create a new one with less hard disk space.<br>

2.- Install on both srrvers<br>

yum -y install drbd90-utils kmod-drbd90 corosync pacemaker pcs<br>
