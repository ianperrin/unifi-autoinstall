#!/bin/bash

#=====================================================================================
# Author: Michael Tabor
# Website: https://miketabor.com
# Description: Script to automate the updating and securing of a Ubuntu server and
#              installing the Ubiquiti UniFi controller software.
#
#=====================================================================================


# Update apt-get source list and upgrade all packages.
sudo apt-get update && sudo apt-get upgrade -y

# Allow SSH ports on UFW firewall.
sudo ufw allow 22/tcp

# Allow UniFi Video ports on UFW firewall.
# see https://help.ubnt.com/hc/en-us/articles/217875218-UniFi-Video-Ports-Used
sudo ufw allow 1935/tcp
sudo ufw allow 6666/tcp
sudo ufw allow 7080/tcp
sudo ufw allow 7443/tcp
sudo ufw allow 7445/tcp
sudo ufw allow 7446/tcp
sudo ufw allow 7447/tcp

# Allow UniFi Controller ports on UFW firewall.
# see https://help.ubnt.com/hc/en-us/articles/218506997-UniFi-Ports-Used
sudo ufw allow 6789/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 8443/tcp
sudo ufw allow 8843/tcp
sudo ufw allow 8880/tcp
sudo ufw allow 3478/udp

# Enable UFW firewall.
sudo ufw --force enable

# Add Ubiquiti UniFi repo to system source list.
sudo echo 'deb http://www.ubnt.com/downloads/unifi/debian unifi5 ubiquiti' | sudo tee -a /etc/apt/sources.list.d/100-ubnt.list

# Add Ubiquiti GPG Keys
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50

# Update source list to include the UniFi repo then install Ubiquiti UniFi.
sudo apt-get update && sudo apt-get install unifi -y

# Download and install UniFi Video
wget http://dl.ubnt.com/firmwares/unifi-video/3.6.3/unifi-video_3.6.3~Debian7_amd64.deb
sudo dpkg -i unifi-video_3.6.3~Debian7_amd64.deb

# Install Fail2Ban
sudo apt-get install fail2ban -y

# Copy config Fail2ban config files to preserve overwriting changes during Fail2ban upgrades.
sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Create unifi-controller Fail2ban definition and set fail regex. 
sudo echo -e '# Fail2Ban filter for Ubiquiti UniFi Controller\n#\n#\n\n[Definition]\nfailregex =^.*Failed .* login .* <HOST>*\s*$
' | sudo tee -a /etc/fail2ban/filter.d/unifi-controller.conf

# Add unifi-controller JAIL to Fail2ban setting log path and blocking IPs after 3 failed logins within 15 minutes for 1 hour.
sudo echo -e '\n[unifi-controller]\nenabled  = true\nfilter   = unifi-controller\nlogpath  = /usr/lib/unifi/logs/server.log\nmaxretry = 3\nbantime = 3600\nfindtime = 900' | sudo tee -a /etc/fail2ban/jail.local

# Create unifi-video Fail2ban definition and set fail regex. 
sudo echo -e '# Fail2Ban filter for Ubiquiti UniFi Video\n#\n#\n\n[Definition]\nfailregex =^.*INFO .* bad login attempt \(<HOST>\) in tomcat-(?:HTTP|HTTPS)-exec-\d*$
' | sudo tee -a /etc/fail2ban/filter.d/unifi-video.conf

# Add unifi-video JAIL to Fail2ban setting log path and blocking IPs after 3 failed logins within 15 minutes for 1 hour.
sudo echo -e '\n[unifi-video]\nenabled  = true\nfilter   = unifi-video\nlogpath  = /var/log/unifi-video/login.log\nmaxretry = 3\nbantime = 3600\nfindtime = 900' | sudo tee -a /etc/fail2ban/jail.local

# Restart Fail2ban to apply changes above.
sudo service fail2ban restart

echo -e '\n\n\n  Ubiquiti UniFi Controller Install Complete...!'
echo '  Access controller by going to https://<SERVER_IP>:8443'
