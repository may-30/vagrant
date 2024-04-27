#!/bin/bash

set -x

echo "============== worker.sh =============="

############################################################
# 1. 쿠버네티스 조인                                           #
############################################################
echo "========== 1. 쿠버네티스 조인 =========="

# 1-1. kubeadm 조인 변수 설정
echo "========== 1-1. kubeadm 조인 변수 설정 =========="
IP=$(awk -F ': ' '/IP:/ {print $2}' /vagrant/$IDX.txt)
TOKEN=$(awk -F ': ' '/TOKEN:/ {print $2}' /vagrant/$IDX.txt)
HASH=$(awk -F ': ' '/HASH:/ {print $2}' /vagrant/$IDX.txt)

# 1-2. kubeadm 조인
echo "========== # 1-2. kubeadm 조인 =========="
kubeadm join $IP:6443 \
--token $TOKEN \
--discovery-token-ca-cert-hash sha256:$HASH