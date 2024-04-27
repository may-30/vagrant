#!/bin/bash

set -x

echo "============== master.sh =============="

############################################################
# 1. 기본 설정                                               #
############################################################
echo "============== 1. 기본 설정 =============="

# 1-1. 패키지 업데이트
echo "============== 1-1. 패키지 업데이트 =============="
apt-get update -y

# 1-2. 타임존 설정
echo "============== 1-2. 타임존 설정 =============="
timedatectl set-timezone Asia/Seoul

# 1-3. 패키지 설치
echo "============== 1-3. 패키지 설치 =============="
apt-get install -y curl net-tools apt-transport-https ca-certificates gpg

############################################################
# 2. 쿠버네티스 설치 사전 조건                                   #
############################################################
echo "============== 2. 쿠버네티스 설치 사전 조건 =============="

# 2-1. 방화벽 비활성화
echo "============== 2-1. 방화벽 비활성화 =============="
ufw disable

# 2-2. 스왑 비활성화
echo "============== 2-2. 스왑 비활성화 =============="
swapoff -a && sed -i '/swap/ s/^/#/' /etc/fstab

# 2-3. 컨테이너 런타임 설치
echo "============== 2-3. 컨테이너 런타임 설치 =============="
# 2-3-1. iptables 설정
echo "============== 2-3-1. iptables 설정 =============="
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# 2-3-2. docker 저장소 설정
echo "============== 2-3-2. docker 저장소 설정 =============="
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# 2-3-2. containerd.io 1.6.21-1 설치
echo "============== 2-3-2. containerd.io 1.6.21-1 설치 =============="
apt-get update -y
apt-get install -y containerd.io=1.6.21-1

# 2-3-3. cri 활성화
echo "============== 2-3-3. cri 활성화 =============="
containerd config default > /etc/containerd/config.toml
sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd

############################################################
# 3. 쿠버네티스 설치                                           #
############################################################
echo "============== 3. 쿠버네티스 설치 =============="

# 3-1. 쿠버네티스 저장소 설정
echo "============== 3-1. 쿠버네티스 저장소 설정 =============="
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

# 3-2. kubelet, kubeadm, kubectl 설치
echo "============== 3-2. kubelet, kubeadm, kubectl 설치 =============="
apt-get update -y
apt-get install -y kubelet=1.27.2-1.1 kubeadm=1.27.2-1.1 kubectl=1.27.2-1.1

systemctl daemon-reload
systemctl restart kubelet
systemctl enable --now kubelet

############################################################
# 4. 쿠버네티스 생성                                           #
############################################################
echo "============== 4. 쿠버네티스 생성 =============="

# 4-1. ip 변수 설정
echo "============== 4-1. ip 변수 설정 =============="
IP=$(ifconfig eth1 | grep inet | awk '{ print $2 }' | head -1)
POD_NETWORK="172.2$IDX.0.0/16"

# 4-2. 쿠버네티스 클러스터 선언
echo "============== 4-2. 쿠버네티스 클러스터 선언 =============="
kubeadm init \
--apiserver-advertise-address=$IP \
--pod-network-cidr=$POD_NETWORK

# 4-3. kubectl 사용 설정
echo "============== 4-3. kubectl 사용 설정 =============="
install -m 0755 -d $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

############################################################
# 5. 쿠버네티스 Addon 설치                                     #
############################################################
echo "============== 5. 쿠버네티스 Addon 설치 =============="

# 5-1. 쿠버네티스 Master Node에 Pod 생성할 수 있도록 설정
echo "============== 5-1. 쿠버네티스 Master Node에 Pod 생성할 수 있도록 설정 =============="
HOSTNAME=$(hostname)
kubectl taint nodes $HOSTNAME node-role.kubernetes.io/control-plane-

# 5-2. calico 설치
echo "============== 5-2. calico 설치 =============="
# 5-2-1. calico 설치
echo "========== 5-2-1. calico 3.26.4 설치 =========="
kubectl create -f https://raw.githubusercontent.com/may-30/vagrant/main/k8s/addon/calico_3.26.4/calico.yaml

# 5-2-1. calico custom 설치
echo "========== 5-2-1. calico custom 3.26.4 설치 =========="
curl -LO https://raw.githubusercontent.com/may-30/vagrant/main/k8s/addon/calico_3.26.4/calico-custom.yaml
sed -i "s|cidr: 20.96.0.0/12|cidr: $POD_NETWORK|" calico-custom.yaml
kubectl create -f calico-custom.yaml
rm -rf calico-custom.yaml

# 5-3. metrics-server 설치
echo "========== # 5-3. metrics-server 0.6.3 설치 =========="
kubectl create -f https://raw.githubusercontent.com/may-30/vagrant/main/k8s/addon/metrics-server_0.6.3/metrics-server.yaml

# 5-4. dashboard 설치
echo "========== # 5-4. dashboard 2.7.0 설치 =========="
kubectl create -f https://raw.githubusercontent.com/may-30/vagrant/main/k8s/addon/dashboard_2.7.0/dashboard.yaml

############################################################
# 6. kubectl 편의 기능                                       #
############################################################
echo "============== 6. kubectl 편의 기능 =============="

# 6-1. alias 설정
echo "============== 6-1. alias 설정 =============="
echo 'alias k=kubectl' >>~/.bashrc
source ~/.bashrc