apt-get update

apt-get install sshpass

#remove strict remote host config to prevent being prompted during ssh
echo "    UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config  
echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config

#set vagrant home dir permissions to allow ssh 
chmod 0700 /home/vagrant

sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/#AllowTcpForwarding/AllowTcpForwarding/g' /etc/ssh/sshd_config

systemctl restart ssh
systemctl restart sshd
