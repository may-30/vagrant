# k8s

넘쳐나는 Windows 속 Mac 사용자들을 위한 Vagrantfile을 사용해서 K8s를 설치하는 문서입니다.

## 1. 공통 사항

### 1-1. About Host OS

- Host OS는 Mac M series(arm)을 기준으로 생성되었습니다.
- 가상 머신 플랫폼의 경우 VMware Fusion을 사용했으며 계정을 만드시고 라이선스를 발급 받으시길 바랍니다.

### 1-2. About Guest OS

- Ubuntu 20.04 LTS를 사용합니다.
- 24.04.29 시점에서 Vagrant + Rocky의 이슈가 있습니다.

### 1-3. About K8s

|Name|Version|
|:--:|:--:|
|K8s|1.27|
|containerd|1.6.21-1|
|kubelet|1.27.2-1.1|
|kubeadm|1.27.2-1.1|
|kubectl|1.27.2-1.1|

### 1-4. About CI/CD

|Name|Version|
|:--:|:--:|
|docker-ce|5:24.0.0-1~ubuntu.20.04~focal|
|docker-ce-cli|5:24.0.0-1~ubuntu.20.04~focal|
|openjdk|openjdk-17-jdk|
|gradle|7.6.1|
|git|1:2.25.1-1ubuntu3.11|
|jenkins|2.414.2|

---

## 2. minimal

- K8s 1대
- CI/CD 전용 서버 1대

- ⚠️ K8s 1대는 master node이며 taint는 자동으로 해제됩니다.

|HostName|IP Range|
|:--:|:--:|
|k8s-master|10.0.0.10|
|k8s-cicd|10.0.0.50|

---

## 3. standard

- K8s master node 1대
- K8s worker node 1대
- CI/CD 전용 서버 1대

|HostName|IP Range|
|:--:|:--:|
|k8s-master|10.0.0.10|
|k8s-worker|10.0.0.100|
|k8s-cicd|10.0.0.50|

---