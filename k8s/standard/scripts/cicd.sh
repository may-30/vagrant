#!/bin/bash

set -x

echo "============== cicd.sh =============="

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
apt-get install -y curl net-tools apt-transport-https ca-certificates gpg wget unzip

# 1-4. 방화벽 비활성화
echo "============== 1-4. 방화벽 비활성화 =============="
ufw disable

############################################################
# 2. docker 설치                                            #
############################################################
echo "============== 2. docker 설치 =============="

# 2-1. docker 저장소 설정
echo "============== 2-1. docker 저장소 설정 =============="
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# 2-2. docker-ce 5:24.0.0-1~ubuntu.22.04~jammy, docker-ce-cli 5:24.0.0-1~ubuntu.22.04~jammy, containerd 1.6.12-0 설치
echo "============== 2-2. docker-ce 5:24.0.0-1~ubuntu.22.04~jammy, docker-ce-cli 5:24.0.0-1~ubuntu.22.04~jammy, containerd 1.6.12-0 설치 =============="
apt-get update -y
apt-get install -y docker-ce=5:24.0.0-1~ubuntu.22.04~jammy docker-ce-cli=5:24.0.0-1~ubuntu.22.04~jammy containerd.io=1.6.21-1

systemctl daemon-reload
systemctl enable docker

############################################################
# 3. kubectl 설치                                           #
############################################################
echo "============== 3. kubectl 설치 =============="

# 3-1. 쿠버네티스 저장소 설정
echo "============== 3-1. 쿠버네티스 저장소 설정 =============="
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

# 3-2. kubectl 1.27.2-1.1 설치
echo "============== 3-2. kubectl 설치 =============="
apt-get update -y
apt-get install -y kubectl=1.27.2-1.1

systemctl daemon-reload

############################################################
# 4. openjdk 설치                                           #
############################################################
echo "============== 4. openjdk 17 설치 =============="
apt-get install -y openjdk-17-jdk

############################################################
# 5. gradle 설치                                            #
############################################################
echo "============== 5. gradle 7.6.1 설치 =============="
wget https://services.gradle.org/distributions/gradle-7.6.1-bin.zip -P ~/
unzip -d /opt/gradle ~/gradle-*.zip

cat <<EOF |tee /etc/profile.d/gradle.sh
export GRADLE_HOME=/opt/gradle/gradle-7.6.1
export PATH=/opt/gradle/gradle-7.6.1/bin:${PATH}
EOF

chmod +x /etc/profile.d/gradle.sh
source /etc/profile.d/gradle.sh

############################################################
# 6. git 설치                                               #
############################################################
echo "============== 6. git 1:2.34.1-1ubuntu1.10 설치 =============="
apt-get install -y git=1:2.34.1-1ubuntu1.10

############################################################
# 7. jenkins 설치                                           #
############################################################
echo "============== 7. jenkins 설치 =============="

# 7-1. jenkins 저장소 설정
wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# 7-2. jenkins 2.46.2 설치
apt-get update -y
apt-get install -y jenkins=2.414.2

systemctl enable jenkins