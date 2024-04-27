#!/bin/bash

set -x

echo "============== master.sh =============="

############################################################
# 1. 쿠버네티스 생성                                           #
############################################################
echo "============== 1. 쿠버네티스 생성 =============="

# 1-1. ip 변수 설정
echo "============== 1-1. ip 변수 설정 =============="
IP=$(ifconfig eth1 | grep inet | awk '{ print $2 }' | head -1)
POD_NETWORK="172.2$IDX.0.0/16"

# 1-2. 쿠버네티스 클러스터 선언
echo "============== 1-2. 쿠버네티스 클러스터 선언 =============="
kubeadm init \
--apiserver-advertise-address=$IP \
--pod-network-cidr=$POD_NETWORK

# 1-3. kubectl 사용 설정
echo "============== 1-3. kubectl 사용 설정 =============="
install -m 0755 -d $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

############################################################
# 2. 쿠버네티스 Addon 설치                                     #
############################################################
echo "============== 2. 쿠버네티스 Addon 설치 =============="

# 2-1. calico 설치
echo "============== 2-1. calico 설치 =============="
# 2-1-1. calico 설치
echo "========== 2-1-1. calico 3.26.4 설치 =========="
kubectl create -f https://raw.githubusercontent.com/may-30/vagrant/main/k8s/addon/calico_3.26.4/calico.yaml

# 2-1-2. calico custom 설치
echo "========== 2-1-2. calico custom 3.26.4 설치 =========="
curl -LO https://raw.githubusercontent.com/may-30/vagrant/main/k8s/addon/calico_3.26.4/calico-custom.yaml
sed -i "s|cidr: 20.96.0.0/12|cidr: $POD_NETWORK|" calico-custom.yaml
kubectl create -f calico-custom.yaml
rm -rf calico-custom.yaml

# 2-2. metrics-server 설치
echo "========== # 2-2. metrics-server 0.6.3 설치 =========="
kubectl create -f https://raw.githubusercontent.com/may-30/vagrant/main/k8s/addon/metrics-server_0.6.3/metrics-server.yaml

# 2-3. dashboard 설치
echo "========== # 2-3. dashboard 2.7.0 설치 =========="
kubectl create -f https://raw.githubusercontent.com/may-30/vagrant/main/k8s/addon/dashboard_2.7.0/dashboard.yaml

############################################################
# 3. kubectl 편의 기능                                       #
############################################################
echo "============== 3. kubectl 편의 기능 =============="

# 3-1. alias 설정
echo "============== 3-1. alias 설정 =============="
echo 'alias k=kubectl' >>~/.bashrc
source ~/.bashrc

############################################################
# 4. 쿠버네티스 조인 정보 생성                                   #
############################################################
echo "============== 4. 쿠버네티스 조인 정보 생성 =============="

# 4-1. 쿠버네티스 조인 정보 추출
echo "============== 4-1. 쿠버네티스 조인 정보 추출 =============="
TOKEN=$(kubeadm token list | awk '{ print $1 }' | tail -1)
HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')

# 4-2. 쿠버네티스 조인 정보 텍스트 파일 생성
echo "============== 4-2. 쿠버네티스 조인 정보 텍스트 파일 생성 =============="
rm -rf /vagrant/$IDX.txt

echo "IP: $IP" >> /vagrant/$IDX.txt
echo "TOKEN: $TOKEN" >> /vagrant/$IDX.txt
echo "HASH: $HASH" >> /vagrant/$IDX.txt