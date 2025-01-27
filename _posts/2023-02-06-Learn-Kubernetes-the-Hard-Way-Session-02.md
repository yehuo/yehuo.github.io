---
title: Learn Kubernetes the Hard Way Session 02
date: 2023-02-06
excerpt: "这部分主要介绍如何构建 Kubernetes 集群 Worker Nodes"
categories: 
    - Kubernetes
tags: 
    - Tutorial
---



# 0x01 Bootstrapping the Kubernetes Worker Nodes

需要启动三个 worker nodes，然后运行下面几个组件。

1. runc
2. container networking plugins
3. contrainerd
4. kubelet
5. kube-proxy

## 1. 测试链接

通过 SSH 登录 Google Cloud 上的 ec2

```shell
gcloud compute ssh worker-0
```

## 2. 部署 Kubernetes 工作节点上各项服务

### 使用二进制文件安装 kubelet

kubelet 在启动 swap 的情况下会无法运行，这里需要关闭 swap分 区

```shell
# Install the OS dependencies
sudo apt-get update
sudo apt-get -y install socat conntrack ipset

# Verify if swap is enabled
sudo swapon --show
# disable swap if swap is run
sudo swapoff -a

# Download and install worker 1.21 version Binaries
wget -q --show-progress --https-only --timestamping \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.21.0/crictl-v1.21.0-linux-amd64.tar.gz \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc93/runc.amd64 \
  https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-linux-amd64-v0.9.1.tgz \
  https://github.com/containerd/containerd/releases/download/v1.4.4/containerd-1.4.4-linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubelet
  
# Create directory
sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes

# Install worker binaries
mkdir containerd
tar -xvf crictl-v1.21.0-linux-amd64.tar.gz
tar -xvf containerd-1.4.4-linux-amd64.tar.gz -C containerd
sudo tar -xvf cni-plugins-linux-amd64-v0.9.1.tgz -C /opt/cni/bin/
sudo mv runc.amd64 runc
chmod +x crictl kubectl kube-proxy kubelet runc 
sudo mv crictl kubectl kube-proxy kubelet runc /usr/local/bin/
sudo mv containerd/bin/* /bin/
```

### 配置 Worker Node 网络

```shell
# Retrieve Pod CIDR range
POD_CIDR=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/pod-cidr)

# Create bridge configuration
cat <<EOF | sudo tee /etc/cni/net.d/10-bridge.conf
{
    "cniVersion": "0.4.0",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF

# Create the loopback configuration
cat <<EOF | sudo tee /etc/cni/net.d/99-loopback.conf
{
    "cniVersion": "0.4.0",
    "name": "lo",
    "type": "loopback"
}
EOF
```

### 配置容器运行时 containerd

```shell
# Create the container configuration file
sudo mkdir -p /etc/containerd/
cat << EOF | sudo tee /etc/containerd/config.toml
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
EOF

cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
```

### 变更 kubelet 配置

```shell
sudo mv ${HOSTNAME}-key.pem ${HOSTNAME}.pem /var/lib/kubelet/
sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
sudo mv ca.pem /var/lib/kubernetes/

# Create the config
cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
podCIDR: "${POD_CIDR}"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
EOF

# Create kubelet service unit file
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### 配置 kube-proxy

```shell
sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig

# Create config
cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.200.0.0/16"
EOF

# Create service unit file
cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### 启动和验证

```shell
# Start the worker service
sudo systemctl daemon-reload
sudo systemctl enable containerd kubelet kube-proxy
sudo systemctl start containerd kubelet kube-proxy

# Verification
gcloud compute ssh controller-0 \
  --command "kubectl get nodes --kubeconfig admin.kubeconfig"
```

# 0x02 Configuring kubectl for Remote Access

使用`admin`用户凭证来生成一个`kubeconfig`

每个`kubeconfig`都需要一个Kubernetes API服务器来连接，本实验里将会用之前分配给Kubernetes API的负载均衡器IP

```shell
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem

kubectl config set-context kubernetes-the-hard-way \
  --cluster=kubernetes-the-hard-way \
  --user=admin

kubectl config use-context kubernetes-the-hard-way
```

### Verification

```shell
kubectl version
kubectl get nodes
```

# Provisioning Pod Network Routes

创建一个路由，将节点的Pod CIDR范围映射到节点的内部IP地址

```shell
# Gather the information required to create routes in the kubernetes-the-hard-way VPC
for instance in worker-0 worker-1 worker-2; do
  gcloud compute instances describe ${instance} \
    --format 'value[separator=" "](networkInterfaces[0].networkIP,metadata.items[0].value)'
done

# Create network routes
for i in 0 1 2; do
  gcloud compute routes create kubernetes-route-10-200-${i}-0-24 \
    --network kubernetes-the-hard-way \
    --next-hop-address 10.240.0.2${i} \
    --destination-range 10.200.${i}.0/24
done

# List the routes in VPC
gcloud compute routes list --filter "network: kubernetes-the-hard-way"
```

## Deploying the DNS Cluster Add-on

[DNS for Services and Pods](https://kubernetes-io.translate.goog/docs/concepts/services-networking/dns-pod-service/?_x_tr_sl=auto&_x_tr_tl=zh-CN&_x_tr_hl=zh-CN) 提供基于DNS的服务发现，由[CoreDNS](https://translate.google.com/website?sl=auto&tl=zh-CN&hl=zh-CN&u=https://coredns.io/)支持

```shell
# Deploy coredns add-on
kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.8.yaml

# Get pods created by kube-dns
kubectl get pods -l k8s-app=kube-dns -n kube-system

# Verification
kubectl run busybox --image=busybox:1.28 --command -- sleep 3600
kubectl get pods -l run=busybox
POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")
kubectl exec -ti $POD_NAME -- nslookup kubernetes
```

## Stress Test

### Create Encrypted Data

这里会对[加密静态数据](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/%23verifying-that-data-is-encrypted)的功能做测试，先创建通用密数据，然后查看etcd key。etcd key通常是`k8s:encLaescbc:v1:key1`开头，并使用`aescbc`加密的。

```shell
# Create a generic secret
kubectl create secret generic kubernetes-the-hard-way \
  --from-literal="mykey=mydata"

# Print a hexdump of the kubernetes-the-hard-way secret stored in etcd
gcloud compute ssh controller-0 \
  --command "sudo ETCDCTL_API=3 etcdctl get \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem\
  /registry/secrets/default/kubernetes-the-hard-way | hexdump -C"
```

### Deployment

这里通过创建一个nginx的deployment来验证k8s的可用性，并使用下面的功能

- 查看[Log](https://kubernetes.io/docs/concepts/cluster-administration/logging/)
- 在pod中[exec](https://kubernetes.io/docs/tasks/debug/debug-application/get-shell-running-container/)命令
- 使用[Service](https://kubernetes.io/docs/concepts/services-networking/service/)暴露端口

```shell
# Create Deployment for nginx web server
kubectl create deployment nginx --image=nginx

# List pod created by nginx
kubectl get pods -l app=nginx

# Retrieve the full name of nginx pod
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")

# Forward port 8080 of local machine to port 80 of nginx pod
kubectl port-forward $POD_NAME 8080:80

# Make an HTTP request using the forwarding IP
curl --head http://127.0.0.1:8080

# Log
kubectl logs $POD_NAME

# Exec
kubectl exec -ti $POD_NAME -- nginx -v

# Service
kubectl expose deployment nginx --port 80 --type NodePort
# Create firewall rule allow remote access
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-nginx-service \
  --allow=tcp:${NODE_PORT} \
  --network kubernetes-the-hard-way
# Retieve external IP of worker instance
EXTERNAL_IP=$(gcloud compute instances describe worker-0 \
  --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')
# Make HTTP request using external IP
curl -I http://${EXTERNAL_IP}:${NODE_PORT}
```

## CleanUp

```shell
# Delete Compute Instances
gcloud -q compute instances delete \
  controller-0 controller-1 controller-2 \
  worker-0 worker-1 worker-2 \
  --zone $(gcloud config get-value compute/zone)

# Delete Networking

# Delete External Load balancer
gcloud -q compute forwarding-rules delete kubernetes-forwarding-rule \
    --region $(gcloud config get-value compute/region)
gcloud -q compute target-pools delete kubernetes-target-pool
gcloud -q compute http-health-checks delete kubernetes
gcloud -q compute addresses delete kubernetes-the-hard-way

# Delete Firewall
gcloud -q compute firewall-rules delete \
  kubernetes-the-hard-way-allow-nginx-service \
  kubernetes-the-hard-way-allow-internal \
  kubernetes-the-hard-way-allow-external \
  kubernetes-the-hard-way-allow-health-check

# Deletet VPC
gcloud -q compute routes delete \
    kubernetes-route-10-200-0-0-24 \
    kubernetes-route-10-200-1-0-24 \
    kubernetes-route-10-200-2-0-24
gcloud -q compute networks subnets delete kubernetes
gcloud -q compute networks delete kubernetes-the-hard-way
  
# Delete address
gcloud -q compute addresses delete kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region)
```
