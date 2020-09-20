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

#ADD NETWORK CONFIG FOR K8S
tee cluster.yml <<EOF
nodes:
- address: 192.168.0.11
  port: "22"
  internal_address: 192.168.0.11
  role:
  - controlplane
  - worker
  - etcd
  hostname_override: ""
  user: vagrant
  docker_socket: /var/run/docker.sock
  ssh_key: ""
  ssh_key_path: /home/vagrant/.ssh/id_rsa
  ssh_cert: ""
  ssh_cert_path: ""
  labels: {}
  taints: []
services:
  etcd:
    image: ""
    extra_args: {}
    extra_binds: []
    extra_env: []
    win_extra_args: {}
    win_extra_binds: []
    win_extra_env: []
    external_urls: []
    ca_cert: ""
    cert: ""
    key: ""
    path: ""
    uid: 0
    gid: 0
    snapshot: null
    retention: ""
    creation: ""
    backup_config: null
  kube-api:
    image: ""
    extra_args: {}
    extra_binds: []
    extra_env: []
    win_extra_args: {}
    win_extra_binds: []
    win_extra_env: []
    service_cluster_ip_range: 10.43.0.0/16
    service_node_port_range: ""
    pod_security_policy: false
    always_pull_images: false
    secrets_encryption_config: null
    audit_log: null
    admission_configuration: null
    event_rate_limit: null
  kube-controller:
    image: ""
    extra_args: {}
    extra_binds: []
    extra_env: []
    win_extra_args: {}
    win_extra_binds: []
    win_extra_env: []
    cluster_cidr: 10.42.0.0/16
    service_cluster_ip_range: 10.43.0.0/16
  scheduler:
    image: ""
    extra_args: {}
    extra_binds: []
    extra_env: []
    win_extra_args: {}
    win_extra_binds: []
    win_extra_env: []
  kubelet:
    image: ""
    extra_args: {}
    extra_binds: [/mnt/fast-disks:/mnt/fast-disks]
    extra_env: []
    win_extra_args: {}
    win_extra_binds: []
    win_extra_env: []
    cluster_domain: cluster.local
    infra_container_image: ""
    cluster_dns_server: 10.43.0.10
    fail_swap_on: false
    generate_serving_certificate: false
  kubeproxy:
    image: ""
    extra_args: {}
    extra_binds: []
    extra_env: []
    win_extra_args: {}
    win_extra_binds: []
    win_extra_env: []
network:
  plugin: canal
  options: {}
  mtu: 0
  node_selector: {}
  update_strategy: null
authentication:
  strategy: x509
  sans: []
  webhook: null
addons: ""
addons_include: []
system_images:
  etcd: rancher/coreos-etcd:v3.4.3-rancher1
  alpine: rancher/rke-tools:v0.1.64
  nginx_proxy: rancher/rke-tools:v0.1.64
  cert_downloader: rancher/rke-tools:v0.1.64
  kubernetes_services_sidecar: rancher/rke-tools:v0.1.64
  kubedns: rancher/k8s-dns-kube-dns:1.15.2
  dnsmasq: rancher/k8s-dns-dnsmasq-nanny:1.15.2
  kubedns_sidecar: rancher/k8s-dns-sidecar:1.15.2
  kubedns_autoscaler: rancher/cluster-proportional-autoscaler:1.7.1
  coredns: rancher/coredns-coredns:1.6.9
  coredns_autoscaler: rancher/cluster-proportional-autoscaler:1.7.1
  nodelocal: rancher/k8s-dns-node-cache:1.15.7
  kubernetes: rancher/hyperkube:v1.18.8-rancher1
  flannel: rancher/coreos-flannel:v0.12.0
  flannel_cni: rancher/flannel-cni:v0.3.0-rancher6
  calico_node: rancher/calico-node:v3.13.4
  calico_cni: rancher/calico-cni:v3.13.4
  calico_controllers: rancher/calico-kube-controllers:v3.13.4
  calico_ctl: rancher/calico-ctl:v3.13.4
  calico_flexvol: rancher/calico-pod2daemon-flexvol:v3.13.4
  canal_node: rancher/calico-node:v3.13.4
  canal_cni: rancher/calico-cni:v3.13.4
  canal_flannel: rancher/coreos-flannel:v0.12.0
  canal_flexvol: rancher/calico-pod2daemon-flexvol:v3.13.4
  weave_node: weaveworks/weave-kube:2.6.4
  weave_cni: weaveworks/weave-npc:2.6.4
  pod_infra_container: rancher/pause:3.1
  ingress: rancher/nginx-ingress-controller:nginx-0.32.0-rancher1
  ingress_backend: rancher/nginx-ingress-controller-defaultbackend:1.5-rancher1
  metrics_server: rancher/metrics-server:v0.3.6
  windows_pod_infra_container: rancher/kubelet-pause:v0.1.4
ssh_key_path: /home/vagrant/.ssh/id_rsa
ssh_cert_path: ""
ssh_agent_auth: false
authorization:
  mode: rbac
  options: {}
ignore_docker_version: null
kubernetes_version: ""
private_registries: []
ingress:
  provider: ""
  options: {}
  node_selector: {}
  extra_args: {}
  dns_policy: ""
  extra_envs: []
  extra_volumes: []
  extra_volume_mounts: []
  update_strategy: null
cluster_name: ""
cloud_provider:
  name: ""
prefix_path: ""
win_prefix_path: ""
addon_job_timeout: 0
bastion_host:
  address: ""
  port: ""
  user: ""
  ssh_key: ""
  ssh_key_path: ""
  ssh_cert: ""
  ssh_cert_path: ""
monitoring:
  provider: ""
  options: {}
  node_selector: {}
  update_strategy: null
  replicas: null
restore:
  restore: false
  snapshot_name: ""
dns: null
EOF


#REPLACE IP AND USER IN RKE CLUSTER YAML
#sed -i 's/IP_REPLACE/'"$0"'/g' cluster.yml
#sed -i 's/USER_REPLACE/'"$1"'/g' cluster.yml

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

tee local-storage.yaml <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-disks
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

kubectl create namespace rabbitmq
kubectl apply -f local-storage.yaml --namespace rabbitmq

tee rabbitmqdef.yaml <<EOF
apiVersion: rabbitmq.com/v1beta1
kind: RabbitmqCluster
metadata:
  name: rabbitmqdef
spec:
  persistence:
    storageClassName: fast-disks
    storage: 40Gi
  replicas: 1 
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 1000m
      memory: 2Gi  
EOF

#APPLY RABBITMQ CLUSTER YAML
kubectl apply -f rabbitmqdef.yaml --namespace rabbitmq

kubectl create namespace cockroachdb
kubectl config set-context $(kubectl config current-context) --namespace=cockroachdb


tee cockroachdb-statefulset.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  # This service is meant to be used by clients of the database. It exposes a ClusterIP that will
  # automatically load balance connections to the different database pods.
  name: cockroachdb-public
  labels:
    app: cockroachdb
spec:
  ports:
  # The main port, served by gRPC, serves Postgres-flavor SQL, internode
  # traffic and the cli.
  - port: 26257
    targetPort: 26257
    name: grpc
  # The secondary port serves the UI as well as health and debug endpoints.
  - port: 8080
    targetPort: 8080
    name: http
  selector:
    app: cockroachdb
---
apiVersion: v1
kind: Service
metadata:
  # This service only exists to create DNS entries for each pod in the stateful
  # set such that they can resolve each other's IP addresses. It does not
  # create a load-balanced ClusterIP and should not be used directly by clients
  # in most circumstances.
  name: cockroachdb
  labels:
    app: cockroachdb
  annotations:
    # Use this annotation in addition to the actual publishNotReadyAddresses
    # field below because the annotation will stop being respected soon but the
    # field is broken in some versions of Kubernetes:
    # https://github.com/kubernetes/kubernetes/issues/58662
    service.alpha.kubernetes.io/tolerate-unready-endpoints: "true"
    # Enable automatic monitoring of all instances when Prometheus is running in the cluster.
    prometheus.io/scrape: "true"
    prometheus.io/path: "_status/vars"
    prometheus.io/port: "8080"
spec:
  ports:
  - port: 26257
    targetPort: 26257
    name: grpc
  - port: 8080
    targetPort: 8080
    name: http
  # We want all pods in the StatefulSet to have their addresses published for
  # the sake of the other CockroachDB pods even before they're ready, since they
  # have to be able to talk to each other in order to become ready.
  publishNotReadyAddresses: true
  clusterIP: None
  selector:
    app: cockroachdb
---
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: cockroachdb-budget
  labels:
    app: cockroachdb
spec:
  selector:
    matchLabels:
      app: cockroachdb
  maxUnavailable: 1
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: cockroachdb
spec:
  serviceName: "cockroachdb"
  replicas: 1
  selector:
    matchLabels:
      app: cockroachdb
  template:
    metadata:
      labels:
        app: cockroachdb
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - cockroachdb
              topologyKey: kubernetes.io/hostname
      containers:
      - name: cockroachdb
        image: cockroachdb/cockroach:v19.2.5
        imagePullPolicy: IfNotPresent
        # TODO: Change these to appropriate values for the hardware that you're running. You can see
        # the amount of allocatable resources on each of your Kubernetes nodes by running:
        #   kubectl describe nodes
        resources:
          requests:
            cpu: "2"
            memory: "2Gi"
        ports:
        - containerPort: 26257
          name: grpc
        - containerPort: 8080
          name: http
        livenessProbe:
          httpGet:
            path: "/health"
            port: http
          initialDelaySeconds: 30
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: "/health?ready=1"
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 2
        volumeMounts:
        - name: datadir
          mountPath: /cockroach/cockroach-data
        env:
        - name: COCKROACH_CHANNEL
          value: kubernetes-insecure
        command:
          - "/bin/bash"
          - "-ecx"
          # The use of qualified `hostname -f` is crucial:
          # Other nodes aren't able to look up the unqualified hostname.
          - "exec /cockroach/cockroach start --logtostderr --insecure --advertise-host $(hostname -f) --http-addr 0.0.0.0 --join cockroachdb-0.cockroachdb,cockroachdb-1.cockroachdb,cockroachdb-2.cockroachdb --cache 25% --max-sql-memory 25%"
      # No pre-stop hook is required, a SIGTERM plus some time is all that's
      # needed for graceful shutdown of a node.
      terminationGracePeriodSeconds: 60
      #volumes:
      #- name: datadir
      #  persistentVolumeClaim:
      #    claimName: datadir
  podManagementPolicy: Parallel
  updateStrategy:
    type: RollingUpdate
  volumeClaimTemplates:
  - metadata:
      name: datadir
    spec:
      storageClassName: fast-disks
      accessModes:
        - "ReadWriteOnce"
      resources:
        requests:
          storage: 40Gi
EOF

tee cluster-init.yaml <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: cluster-init
  labels:
    app: cockroachdb
spec:
  template:
    spec:
      containers:
      - name: cluster-init
        image: cockroachdb/cockroach:v19.2.5
        imagePullPolicy: IfNotPresent
        command:
          - "/cockroach/cockroach"
          - "init"
          - "--insecure"
          - "--host=cockroachdb-0.cockroachdb"
      restartPolicy: OnFailure
EOF

kubectl create -f cockroachdb-statefulset.yaml
kubectl create -f cluster-init.yaml

kubectl config set-context $(kubectl config current-context) --namespace=default


#UPDATE SSH SETTINGS TO ALLOW TCP FORWARDING
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/#AllowTcpForwarding/AllowTcpForwarding/g' /etc/ssh/sshd_config

systemctl restart ssh