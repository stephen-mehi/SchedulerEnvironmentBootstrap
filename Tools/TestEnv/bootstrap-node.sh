
apt-get update

#MAKE VOLUME MOUNT DIRECTORY
mkdir /mnt/fast-disks
mkdir /mnt/fast-disks/vol1
mkdir /mnt/fast-disks/vol2

chmod 0700 /home/vagrant

echo "Creating file system from block device sdb"
mkfs.ext4 /dev/sdb
echo "File system creation complete for sdb"

echo "About to mount volume sdb"
mount -t ext4 /dev/sdb /mnt/fast-disks/vol1
echo "sdb volume mounted"

echo "Creating file system from block device sdc"
mkfs.ext4 /dev/sdc
echo "File system creation complete for sdc"

echo "About to mount volume sdc"
mount -t ext4 /dev/sdc /mnt/fast-disks/vol2
echo "sdc volume mounted"

#this is required for mount to stick around
echo "/dev/sdb /mnt/fast-disks/vol1                       ext4    defaults        1 1" >> /etc/fstab
echo "/dev/sdc /mnt/fast-disks/vol2                       ext4    defaults        1 1" >> /etc/fstab

#DISABLE SWAP DISK
#THIS PREVENTS OS FROM DUMPING MEMORY OVERFLOW INTO HARD DISK
swapoff -a

#COMMENT OUT SWAP RECORD
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

#ADD NETWORK CONFIG FOR K8S
tee -a /etc/sysctl.d/99-kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

#CONFIRM NO SWAP CONFIGURED
sysctl --system
free -h

#PULL AND INSTALL DOCKER AND ADD CURRENT USER TO DOCKER GROUP
curl https://releases.rancher.com/install-docker/19.03.sh | bash -

systemctl enable --now docker
docker version --format '{{.Server.Version}}'
usermod -aG docker vagrant
id vagrant

#INSTALL MODULE USED FOR CONFIGURING PORTS
apt-get install firewalld -y

#OPEN CORRENT UDP/TCP PORTS
for i in 22 80 443 179 5473 6443 8472 2376 8472 2379-2380 9099 10250 10251 10252 10254 30000-32767; do
    firewall-cmd --add-port=${i}/tcp --permanent
done
firewall-cmd --reload

for i in 8285 8472 4789 30000-32767; do
   firewall-cmd --add-port=${i}/udp --permanent
done

#UPDATE SSH SETTINGS TO ALLOW TCP FORWARDING
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/#AllowTcpForwarding/AllowTcpForwarding/g' /etc/ssh/sshd_config

