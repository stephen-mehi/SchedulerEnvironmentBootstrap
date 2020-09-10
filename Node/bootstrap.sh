
apt-get update

#MAKE VOLUME MOUNT DIRECTORY
mkdir /mnt/fast-disks/vol1

#MOUNT EXT4 FORMATTED DISK AT SPECIFIED DIR
#USED BY KUBERNETES LOCAL PERSISTEN VOLS
mount -t ext4 /kubevol /mnt/fast-disks/vol1

#ENABLE KEY SYS MODULES 
for module in br_netfilter ip6_udp_tunnel ip_set ip_set_hash_ip ip_set_hash_net iptable_filter iptable_nat iptable_mangle iptable_raw nf_conntrack_netlink nf_conntrack nf_conntrack_ipv4   nf_defrag_ipv4 nf_nat nf_nat_ipv4 nf_nat_masquerade_ipv4 nfnetlink udp_tunnel veth vxlan x_tables xt_addrtype xt_conntrack xt_comment xt_mark xt_multiport xt_nat xt_recent xt_set  xt_statistic xt_tcpudp;
  do
    if ! lsmod | grep -q $module; then
      modprobe $module
    fi;
done

#DISABLE SWAP DISK
#THIS PREVENTS OS FROM DUMPING MEMORY OVERFLOW INTO HARD DISK
swapoff -a

#COMMENT OUT SWAP RECORD
sed -i 's/^([^#].*?\sswap\s+.*)$/#\1/g' /etc/fstab

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
usermod -aG docker $USER
id $USER

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

systemctl restart ssh
