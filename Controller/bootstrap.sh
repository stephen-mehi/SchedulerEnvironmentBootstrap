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