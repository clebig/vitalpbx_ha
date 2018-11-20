# vitalpbx_ha
italPBX Hih Availability

Example:<br>
Master<br>
IP Master: 192.168.30.10<br>
Netmask: 255.255.248.0<br>
Gateway: 192.168.24.1<br>
Primary DNS: 8.8.8.8<br>
Secundary DNS: 8.8.4.4<br>
Host Name Master: vitalpbx1.local<br>

Slave<br>
IP Slave: 192.168.30.20<br>
Host name Slave: vitalpbx2.local<br>
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
e.- Gateway: Your gateway<br><br>
f.- Primary DNS: Your primary DNS<br>
g.- Secundary DNS: Your secundary DNS<br>

4.- Install on both srrvers<br>
yum -y install drbd90-utils kmod-drbd90 corosync pacemaker pcs<br>

5.- install the script<br>
cd /<br>
wget https://raw.githubusercontent.com/VitalPBX/vitalpbx_ha/master/vital_ha.sh<br>
chmod +x vital_ha.sh<br>
./vital_ha.sh<br>
