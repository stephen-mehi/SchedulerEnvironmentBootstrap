apt-get update

#PULL AND INSTALL KUBECTL 
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.17.0/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl
kubectl version –client

#PULL AND INSTALL RANCHER RKE
curl -s https://api.github.com/repos/rancher/rke/releases/v1.1.6 | grep download_url | grep amd64 | cut -d '"' -f 4 | wget -qi -
chmod +x rke_linux-amd64
mv rke_linux-amd64 /usr/local/bin/rke
rke –version

#PULL AND INSTALL HELM
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/v3.3.1/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm version

#REPLACE IP AND USER IN RKE CLUSTER YAML
sed -i 's/IP_REPLACE/'"$0"'/g' cluster.yml
sed -i 's/USER_REPLACE/'"$1"'/g' cluster.yml

#SET KUBCTL CONFIG ENV VAR
export KUBECONFIG=~/kube_config_cluster.yml

#PULL RABBITMQ CLUSTER OPERATOR AND INSTALL 
git clone https://github.com/rabbitmq/cluster-operator.git
cd /home/smehi/cluster-operator
kubectl create -f config/namespace/base/namespace.yaml
kubectl create -f config/crd/bases/rabbitmq.com_rabbitmqclusters.yaml
kubectl -n rabbitmq-system create --kustomize config/rbac/
kubectl -n rabbitmq-system create --kustomize config/manager/
cd

#PULL AND INSTALL LOCAL VOLUME PROVISIONER
git clone --depth=1 https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner.git
cd sig-storage-local-static-provisioner
helm template ./helm/provisioner > deployment/kubernetes/provisioner_generated.yaml

#REPLACE PLACEHOLDER TEXT IN PROVISIONER YAML
sed  -i 's/MY_RELEASE_VERSION/rke-local-pv/g' ./deployment/kubernetes/provisioner_generated.yaml

#ENABLE FEATURE GATES FOR PROVISIONER
export KUBE_FEATURE_GATES="PersistentLocalVolumes=true,VolumeScheduling=true,MountPropagation=true"

#APPLY RABBITMQ CLUSTER YAML
kubectl apply -f rabbitmqdef.yaml

#PULL AND INSTALL MONGO CLUSTER OPERATOR
cd
git clone https://github.com/mongodb/mongodb-kubernetes-operator.git
cd mongodb-kubernetes-operator
kubectl create -f deploy/crds/mongodb.com_mongodb_crd.yaml
kubectl get crd/mongodb.mongodb.com
kubectl create namespace mongodb
kubectl create -f deploy/ --namespace mongodb
kubectl apply -f deploy/crds/mongodb.com_v1_mongodb_cr.yaml --namespace mongodb
kubectl get mongodb --namespace mongodb

