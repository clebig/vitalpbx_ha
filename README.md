# vitalpbx_ha
VitalPBX High Availability

1.- Prerequisites
In order to install VitalPBX in high availability you need the following:<br>
a.- 3 IP addresses.<br>
b.- Install VitalPBX on two servers with similar characteristics.<br>
c.- At the time of installation leave the largest amount of space on the hard drive to store the variable data on both servers.<br>

2.- We are going to start installing VitalPBX on two servers<br>
a.- When starting the installation go to "INSTALLATION DESTINATION (Custom partitioning selected)".<br>
b.- Now we will remove the "/" partitions to create a new one with less hard disk space. Select the partition and press the button with the minus sign (-) at the bottom. <br>
c.- Now press the plus button (+) and select in Mount Point: the root partition (/), and in Desired Capacity: 20GB (Or another enough value to reach the operating system and its applications in the future). Then press the "Add mount point" button.<br>
d.- Then go to the "File System:" and select "ext4" and press the "Update Settigs" button.<br>
e.- Finally we press the "Done" button and press "Accept Changes" button and continue with the installation.<br>

3.- Install on both srrvers<br>
yum -y install drbd90-utils kmod-drbd90 corosync pacemaker pcs<br>
