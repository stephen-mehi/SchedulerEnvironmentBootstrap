apt-get update

#ENABLE KEY SYS MODULES 
for module in br_netfilter ip6_udp_tunnel ip_set ip_set_hash_ip ip_set_hash_net iptable_filter iptable_nat iptable_mangle iptable_raw nf_conntrack_netlink nf_conntrack nf_conntrack_ipv4   nf_defrag_ipv4 nf_nat nf_nat_ipv4 nf_nat_masquerade_ipv4 nfnetlink udp_tunnel veth vxlan x_tables xt_addrtype xt_conntrack xt_comment xt_mark xt_multiport xt_nat xt_recent xt_set  xt_statistic xt_tcpudp;
  do
    if ! lsmod | grep -q $module; then
      modprobe $module
    fi;
done

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

#PULL AND INSTALL DOCKER AND ADD CURRENT USER TO DOCKER GROUP
curl https://releases.rancher.com/install-docker/19.03.sh | bash -

systemctl enable --now docker
usermod -aG docker $USER
id $USER
docker version --format '{{.Server.Version}}'

#PULL AND INSTALL KUBECTL 
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.8/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

#PULL AND INSTALL RANCHER RKE v1.1.7
curl -s https://api.github.com/repos/rancher/rke/releases/31094769 | grep download_url | grep amd64 | cut -d '"' -f 4 | wget -qi -
chmod +x rke_linux-amd64
mv rke_linux-amd64 /usr/local/bin/rke
rke –version

#PULL AND INSTALL HELM
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/v2.16.12/scripts/get
chmod 700 get_helm.sh
./get_helm.sh
helm version

#GET RKE MANIFEST
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/stephen-mehi/SchedulerEnvironmentBootstrap/v0.0.1/manifests/cluster.yaml
rke up

#SET KUBCTL CONFIG ENV VAR
chown vagrant:vagrant /home/vagrant/kube_config_cluster.yml

tee -a /etc/environment<<EOF
export KUBECONFIG='/home/vagrant/kube_config_cluster.yml'
EOF

export KUBECONFIG=/home/vagrant/kube_config_cluster.yml

#ENABLE FEATURE GATES FOR PROVISIONER
tee -a /etc/environment<<EOF
export KUBE_FEATURE_GATES='PersistentLocalVolumes=true,VolumeScheduling=true,MountPropagation=true'
EOF

export KUBE_FEATURE_GATES="PersistentLocalVolumes=true,VolumeScheduling=true,MountPropagation=true"

#PULL RABBITMQ CLUSTER OPERATOR AND INSTALL 
git clone https://github.com/rabbitmq/cluster-operator.git
cd cluster-operator
git pull --tags
git checkout 0.39.0
kubectl create -f config/namespace/base/namespace.yaml
kubectl create -f config/crd/bases/rabbitmq.com_rabbitmqclusters.yaml
kubectl -n rabbitmq-system create --kustomize config/rbac/
kubectl -n rabbitmq-system create --kustomize config/manager/
cd

#PULL AND INSTALL LOCAL VOLUME PROVISIONER
git clone --depth=1 https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner.git
cd sig-storage-local-static-provisioner
git pull --tags
git checkout v2.3.4
helm template ./helm/provisioner > provisioner_generated.yaml

#REPLACE PLACEHOLDER TEXT IN PROVISIONER YAML
sed -i 's/RELEASE-NAME/rke-local-pv/g' /root/sig-storage-local-static-provisioner/provisioner_generated.yaml

kubectl create -f /root/sig-storage-local-static-provisioner/provisioner_generated.yaml

cd

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/stephen-mehi/SchedulerEnvironmentBootstrap/v0.0.1/manifests/local-storage-class.yaml

kubectl create namespace rabbitmq
kubectl apply -f local-storage-class.yaml --namespace rabbitmq

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/stephen-mehi/SchedulerEnvironmentBootstrap/v0.0.1/manifests/rabbitmq-cluster.yaml

#APPLY RABBITMQ CLUSTER YAML
kubectl apply -f rabbitmq-cluster.yaml --namespace rabbitmq

kubectl create namespace cockroachdb
kubectl config set-context $(kubectl config current-context) --namespace=cockroachdb

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/stephen-mehi/SchedulerEnvironmentBootstrap/v0.0.1/manifests/cockroachdb-cluster.yaml

kubectl create -f cockroachdb-cluster.yaml

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/stephen-mehi/SchedulerEnvironmentBootstrap/v0.0.1/manifests/cockroachdb-cluster-init.yaml

kubectl create -f cockroachdb-cluster-init.yaml

kubectl config set-context $(kubectl config current-context) --namespace=default

git clone https://github.com/prometheus-operator/kube-prometheus.git
cd kube-prometheus
git checkout v0.6.0
kubectl create -f manifests/setup
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
kubectl create -f manifests/

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/stephen-mehi/SchedulerEnvironmentBootstrap/v0.0.1/manifests/prometheus-role.yaml

#ESTABLISH ELEVATED PROMETHEUS PERMISSIONS 
kubectl apply -f prometheus-role.yaml -n monitoring

#CONFIGURE POD MONITORING FOR PROMETHEUS TO START SCRAPING RMQ METRICs
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/stephen-mehi/SchedulerEnvironmentBootstrap/v0.0.1/manifests/prometheus-monitors.yaml

kubectl apply -f prometheus-monitors.yaml -n monitoring

#EXPOSE PROMETHEUS THROUGH INGRESS
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/stephen-mehi/SchedulerEnvironmentBootstrap/v0.0.1/manifests/ingress.yaml

kubectl apply -f ingress.yaml -n monitoring

apt-get install jq

grafana_host="http://scheduler.com"
grafana_cred="admin:admin"
grafana_datasource="prometheus"
ds=(11465);
for d in "${ds[@]}"; do
  echo -n "Processing $d: "
  j=$(curl -k -u "$grafana_cred" $grafana_host/api/gnet/dashboards/$d | jq .json)
  curl -s -k -u "$grafana_cred" -XPOST -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{\"dashboard\":$j,\"overwrite\":true, \
        \"inputs\":[{\"name\":\"prometheus\",\"type\":\"datasource\", \
        \"pluginId\":\"prometheus\",\"value\":\"$grafana_datasource\"}]}" \
    $grafana_host/api/dashboards/import; echo ""
done


#UPDATE SSH SETTINGS TO ALLOW TCP FORWARDING
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/#AllowTcpForwarding/AllowTcpForwarding/g' /etc/ssh/sshd_config

systemctl restart ssh