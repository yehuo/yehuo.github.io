---
title: "Learn Kubernetes the Hard Way Session 01"
date: 2023-02-01
excerpt: "如何构建k8s集群Master nodes以及Control Plant"
categories: 
    - Kubernetes
tags: 
    - Tutorial
---



## 准备工作

### Google Cloud Platform

#### Install Google Cloud SDK

参考Google Cloud下载和文档地址https://cloud.google.com/sdk/，安装gcloud命令工具，确认Google Cloud SDK版本大于338.0.0

```shell
gcloud version
```

#### 设置Compute Region和Compute Zone

```shell
# First time to use gcloud cli
gcloud init
# To access Cloud Platform with Google user credentials
gcloud auth login
# Set default compute region and compute zone
gcloud config set compute/region us-west1
gcloud config set compute/zone us-west1-c
# View addition regions and zones
gcloud compute zones list
```

### 使用tmux来并行操作shell

[Tmux](https://github.com/tmux/tmux/wiki)是一种命令行工具，可以同时在多个终端中并行执行命令。通过`ctrl+b`加上`shift+:`，之后输入`set synchronize-panes on`即可开启多终端并行操作模式，通过`set synchronize-panes off`即可关闭多终端操作

## Installing the Client Tools

终端中操作k8s集群需要用到以下组件：

- [cfssl](https://github.com/cloudflare/cfssl)：用于提供PKI服务和生成TLS证书
- [cfssljson](https://github.com/cloudflare/cfssl)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

### 安装CFSSL

```shell
wget -q --show-progress --https-only --timestamping \
	https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssl \
	https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssljson
chmod +x cfssl cfssljson
sudo mv cfssl cfssljson /usr/local/bin/
# Verification, Version should be equal to or higher than v1.4.1
cfssl version
cfssljson --version
```

### 安装kubectl

```shell
wget https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
# Verification, Version should be equal to or higher than v1.21.0
kubectl version --client
```

## Provisioning Compute Resources

K8s集群需要控制平面和一些工作节点，这里将要在一个Compute Zone里构建一个高可用K8s集群。

### Networking

K8s[网络模型](https://kubernetes.io/docs/concepts/cluster-administration/networking/#kubernetes-model)会构建一个平面网络，保证容器和节点之间可以任意通信，而如果需要限制一些网络流量，则可以通过[网络策略](https://kubernetes.io/docs/concepts/services-networking/network-policies/)来限制集群节点之间或对外的流量。

### Virtual Private Cloud Network

这里会构建一个[VPC](https://cloud.google.com/vpc/docs/vpc#networks)网络来管理K8s集群，然后在其中创建子网来部署K8s节点的私有IP，之后通过firewall来取包所有节点间可以通过任意协议通信

```shell
# Create VPC
gcloud compute networks create kubernetes-the-hard-way --subnet-mode custom
# Setup subnet
gcloud compute networks subnets create kubernetes \
	--network kubernetes-the-hard-way \
	--range 10.240.0.0/24
# Create Firewall to allow internal communication across all protocols
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-internal \
	--allow tcp,udp,icmp \
	--network kubernetes-the-hard-way \
	--source-ranges 10.240.0.0/24,10.200.0.0/16
# Create Firewall to allow external SSH, ICMP, and HTTPS
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-external \
	--allow tcp:22,tcp:6443,icmp \
	--network kubernetes-the-hard-way \
	--source-ranges 0.0.0.0/0
# List the firewall rules
gcloud compute firewall-rules list --filter="network:kubernetes-the-hard-way"
```

### K8s Public IP Access

分配一个静态IP地址，从而允许外部负载均衡流量导向K8s API Server

```shell
gcloud compute addresses create kubernetes-the-hard-way \
	--region $(gcloud config get-value compute/region)
# Verify static IP Address
gcloud compute addresses list --filter="name=('kubernetes-the-hard-way')"
```

### Compute Instances

使用Ubuntu  20.04作为计算节点操作系统，可以支持[containerd运行时](https://github.com/containerd/containerd)工具，每个计算节点都会使用固定的私有IP来简化K8s启动流程。创建Worker时，每个实例需要一个从子网中获取一个K8s集群CIDR段，这个pod子网，会被用做容器网络，`pod-cidr`实例的元数据会显示运行过程中，子网的具体分配情况

> The Kubernetes cluster CIDR range is defined by the Controller Manager's `--cluster-cidr` flag. In this tutorial the cluster CIDR range will be set to `10.200.0.0/16`, which supports 254 subnets.

```shell
# Create three K8s Controllers
for i in 0 1 2; do
  gcloud compute instances create controller-${i} \
	--async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-2004-lts \
    --image-project ubuntu-os-cloud \
    --machine-type e2-standard-2 \
    --private-network-ip 10.240.0.1${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,controller
done
# Create three K8s Workers
for i in 0 1 2; do
  gcloud compute instances create worker-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-2004-lts \
    --image-project ubuntu-os-cloud \
    --machine-type e2-standard-2 \
    --metadata pod-cidr=10.200.${i}.0/24 \
    --private-network-ip 10.240.0.2${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,worker
done
# Verification
gcloud compute instances list --filter="tags.items=kubernetes-the-hard-way"
```

### Configuring SSH Access

在链接Controller和工作节点时，需要使用SSH连接，当第一次连接计算节点时，会自动生成一个SSH key，并存储在gcloud的Project和云实例的元数据里，参见GCP的[连接实例](https://cloud.google.com/compute/docs/instances/connecting-to-instance)

```shell
# To test ssh access to contorller-0 instace
gcloud compute ssh controller-0
```

## Provisioning CA & Generating TLS Certificates

这部分里，会使用CloudFlare的PKI工具包构建一个PKI服务，然后用它来启动一个`Certificate Authority`，并生成TLS证书，来完成etcd, kube-apiserver ,kube-controller-maager, scheduler, kubelet, kube-proxy的认证。

### 编写CA配置文件、认证配置和私钥

```shell
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

### 为admin用户完成认证

这里将会为每个K8s组件以及K8s `admin`用户创建对应的Client and Server Certificates，首先为admin用户创建客户端证书和私钥

```shell
# Create admin Client Certificate
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin
```

### 为组件完成认证

为kubelet，Control Manager，Kube Proxy，Scheduler ， API Server创建客户端证书，其中kubelet需需要为每个worker节点逐个分发，`kube-controller-manager`，`kube-proxy`，`kube-scheduler`，`kubernetes-the-hard-way`则是单独创建，并存储在controller节点上

```shell
# kubelet
for instance in worker-0 worker-1 worker-2; do
  EXTERNAL_IP=$(gcloud compute instances describe ${instance} \
    --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')

  INTERNAL_IP=$(gcloud compute instances describe ${instance} \
    --format 'value(networkInterfaces[0].networkIP)')
    
  cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json \
    -hostname=${instance},${EXTERNAL_IP},${INTERNAL_IP} \
    -profile=kubernetes ${instance}-csr.json | cfssljson -bare ${instance}
done

# kube-controller-manager
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

# kube-proxy
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

# kube-scheduler
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler
  
# Kubernetes API Server
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json \
  -hostname= 10.32.0.1, 10.240.0.10, 10.240.0.11, 10.240.0.12, \
  ${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,${KUBERNETES_HOSTNAMES} \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

# Service Account Key Pair
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account
```

### 分发客户端及服务端证书

将本地生成的各类证书，分发到各个服务器节点上

> The `kube-proxy`, `kube-controller-manager`, `kube-scheduler`, and `kubelet` client certificates will be used to generate client authentication configuration files in the next lab.

```shell
for instance in worker-0 worker-1 worker-2; do
  gcloud compute scp ca.pem ${instance}-key.pem ${instance}.pem ${instance}:~/
done
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem ${instance}:~/
done
```

## Generating K8s Configuration Files for Authentication

本章需要完成一个K8s [Configuration Files](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)，通常也被写作kubeconfig，用于K8s Client的定位和K8s API Servers的验证

### Client Authentication Configs

本章需要为controller manager、kubelet、kube-proxy和scheduler客户端以及admin编写kubeconfig

#### 设定Kubernetes公有IP

每个kubeconfig都需要一个API Server来连接，为了支持高可用，这里会使用外部负载均衡IP来代理Kubernetes API Server。

首先获取终端的静态IP地址

```shell
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')
```

### kubelet配置文件

如果要为Kubelets生成kubeconfig文件，必须要使用正确的node名称，从而确保Kubelets可以被K8s Node Authorizer正确认证。下面的命令必须和之前生成SSL证书的位置放到同一个目录下运行

```shell
for instance in worker-0 worker-1 worker-2; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=${instance}.pem \
    --client-key=${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done
```

### kube-proxy配置文件

```shell
kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.pem \
    --client-key=kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
```

### kube-controller-manager配置文件

```shell
kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.pem \
    --client-key=kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
```

### kube-scheduler配置文件

```shell
kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.pem \
    --client-key=kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
```

### admin配置文件

```shell
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=admin \
  --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig
```

### 分发配置文件

分发kubelet和kube-proxy文件

```shell
for instance in worker-0 worker-1 worker-2; do
  gcloud compute scp ${instance}.kubeconfig kube-proxy.kubeconfig ${instance}:~/
done
```

向controller实例分发`controller-manager`和`kube-scheduler`文件

```shell
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
done
```

## Generating the Data Encryption Config and Key

K8s存储集群状态，app配置和密数据，并支持闲时加密集群数据，本章会生成个一个机密秘钥，和一份加密方案配置。

### 生产加密密钥

```shell
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
```

### 编写加密方案的配置文件

```shell
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp encryption-config.yaml ${instance}:~/
done
```

## Bootstrapping the etcd Cluster

k8s组件都是无状态的，并且会将集群状态存储在etcd中，本章会搭建一个三节点构成的etcd集群，并且支持高可用和安全远程访问。

### 准备工作

下面命令需要到control-0,1,2上逐个执行，这里可以使用tmux来批量执行，参考[如何使用tmux并行运行命令](https://github.com/yehuo/kubernetes-the-hard-way/blob/master/docs/01-prerequisites.md#running-commands-in-parallel-with-tmux)

### 启动一个etcd集群成员

```shell
# Download Binary File
wget -q --show-progress --https-only --timestamping \
  "https://github.com/etcd-io/etcd/releases/download/v3.4.15/etcd-v3.4.15-linux-amd64.tar.gz"

# Extract and Install
tar -xvf etcd-v3.4.15-linux-amd64.tar.gz
sudo mv etcd-v3.4.15-linux-amd64/etcd* /usr/local/bin/

# Configure the etcd Server
sudo mkdir -p /etc/etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd
sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
```

实例的内部IP会被用作服务客户端请求以及和etcd peers的连接

```shell
# Retrieve the Internal IP
INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

# Set the unique name for each instance
ETCD_NAME=$(hostname -s)

# Create systemd unit file
cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller-0=https://10.240.0.10:2380,controller-1=https://10.240.0.11:2380,controller-2=https://10.240.0.12:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start the etcd Server
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd

# Verification
# List etcd cluster memebers
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem
```

## Bootstrapping the Kubernetes Control Plane

本章任务：

- 在三个计算实例中启动Kubernetes控制平面
- 配置高可用
- 创建一个外部负载均衡，来向远程Client暴露Kubernetes API

每个节点上安装下述组件：

- Kubernetes API Server
- Scheduler
- Controller Manager

### 准备工作

使用下述命令登入三个controller节点，并使用tmux开始并行输入命令

```shell
gcloud compute ssh controller-0
```

### 生成控制平面

```shell
# Create configuration directory
sudo mkdir -p /etc/kubernetes/config

# Download and Install Controller Binaries
wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl"

chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin

# Configure k8s API Server
sudo mkdir -p /var/lib/kubernetes/
sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
  service-account-key.pem service-account.pem \
  encryption-config.yaml /var/lib/kubernetes/

# Retrieve the Internal IP and Public IP
INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
REGION=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/project/attributes/google-compute-default-region)
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $REGION \
  --format 'value(address)')
  
# Create apiserver systemd unit file
cp ./SystemdUnitFile/kube-apiserver.service /etc/systemd/system/kube-apiserver.service

# Configure k8s Controller Manager
sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
cp ./SystemdUnitFile/kube-controller-manager.service /etc/systemd/system/kube-controller-manager.service

# Configure k8s Scheduler
sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/
cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
  apiVersion: kubescheduler.config.k8s.io/v1beta1
  kind: KubeSchedulerConfiguration
  clientConnection:
    kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
  leaderElection:
    leaderElect: true
EOF
cp ./SystemdUnitFile/kube-scheduler.service /etc/systemd/system/kube-scheduler.service
```

### 启动Controller Service

启动过程预计需要超过10s左右来完全初始化

```shell
sudo systemctl daemon-reload
sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
```

### 启动HTTP健康检测

[Google Network Load Balancer](https://cloud.google.com/load-balancing/docs/network)会被用作向三个API server分发流量，并且支持任何Server关闭TLS连接以及验证客户端证书。但是GNLB仅支持HTTP的健康检测，API Server的HTTPS端点是无法使用的。而Nginx webserver可以通过代理HTTP健康检测来解决这个问题。

- 安装Nginx
- Configure 80 port as HTTP health check
- 把与API server的连接代理到`https://127.0.0.1:6443/healthz`

因为API Server的`/healthz`是默认不需要验证的，下面的命令同样需要在三个Controller Node中使用

```shell
curl -H "Host: kubernetes.default.svc.cluster.local" -i http://127.0.0.1/healthz# Install web server to handle HTTP health checks
sudo apt-get update
sudo apt-get install -y nginx

# Configure Nginx
cat > kubernetes.default.svc.cluster.local <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
EOF

sudo mv kubernetes.default.svc.cluster.local \
  /etc/nginx/sites-available/kubernetes.default.svc.cluster.local
sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local \
  /etc/nginx/sites-enabled/


# Verification
# Expecting: "Kubernetes control plane is running at https://127.0.0.1:6443"
kubectl cluster-info --kubeconfig admin.kubeconfig

# Test nginx HTTP health check proxy
curl -H "Host: kubernetes.default.svc.cluster.local" -i http://127.0.0.1/healthz
```

### 配置Kubelet的RBAC (Role-based Access Control)

在k8s API Server和worker node上Kubelet API连接时，需要使用RBAC权限，从而获取metrics，logs以及在pod上执行命令。因为前期在Kubelet上设定的`--authorization-mode`是`Webhook`，因而Kubelet会使用`SubjectAccessReview`API来获取认证，类似于`kubeclt auth can-i`中的`SelfSubjectAccessReview`API。

因为这套认证会影响整个cluster，所以仅需要在任意controller节点上运行，需要创建`system:kube-apiserver-to-kubelet`的ClusterRole，并确保有权限联通Kubelet API，以及运行一些common tasks来管理pods：

```shell
gcloud compute ssh controller-0

# Create ClusterRole
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF
```

鉴于k8s API Server会使用`kubernetes`用户去Kebelet上做认证，认证过程会使用`--kubelet-client-cerificate`中指定的证书来完成。

下面需要将`kubernetes`用户和`system:kube-apiserver-to-kubelet`ClusterRole来绑定。

```shell
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
```

### 搭建Kubernetes前端负载均衡

这里会构建一个外部负载均衡，来代理Kubernetes API Servers的流量。访问`kubernetes-the-hard-way`的静态IP地址的流量，会被发送到负载均衡器上。鉴于计算实例是无权设定相关配置的，下面的指令需要在创建计算实例的机器上进行。

#### 构建一个gcloud负载均衡器

```shell
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
--region $(gcloud config get-value compute/region) \
--format 'value(address)')

gcloud compute http-health-checks create kubernetes \
--description "Kubernetes Health Check" \
--host "kubernetes.default.svc.cluster.local" \
--request-path "/healthz"

gcloud compute firewall-rules create kubernetes-the-hard-way-allow-health-check \
--network kubernetes-the-hard-way \
--source-ranges 209.85.152.0/22,209.85.204.0/22,35.191.0.0/16 \
--allow tcp

gcloud compute target-pools create kubernetes-target-pool \
--http-health-check kubernetes

gcloud compute target-pools add-instances kubernetes-target-pool \
--instances controller-0,controller-1,controller-2

gcloud compute forwarding-rules create kubernetes-forwarding-rule \
--address ${KUBERNETES_PUBLIC_ADDRESS} \
--ports 6443 \
--region $(gcloud config get-value compute/region) \
--target-pool kubernetes-target-pool
```

#### Verification

```shell
# Retrieve static IP Address
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')

# Make a HTTP request for version info
curl --cacert ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}:6443/version
```

