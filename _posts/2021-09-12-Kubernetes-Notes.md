## Cluster

A Kubernetes cluster consists of two types of resources:

- Control Plane: **The Control Plane is responsible for managing the cluster.**
- Node: **A node is a VM or a physical computer that serves as a worker machine in a Kubernetes cluster.** Each node has a Kubelet, which is an agent for managing the node and communicating with the Kubernetes control plane.

Communicate between Nodes and Control Plane: **The nodes communicate with the control plane using the [Kubernetes API](https://kubernetes.io/docs/concepts/overview/kubernetes-api/)**, which the control plane exposes.

To get started with Kubernetes development, you can use Minikube. Minikube is a lightweight Kubernetes implementation that creates a VM on your local machine and deploys a simple cluster containing only one node.

```shell
minikube version
minikube start # start a new cluster by minikube
# tips: kubectl is now configured to use "minikube" cluster and "default" namespace by default

kubectl version # check version of kubectl
kubectl cluster-info # get info of control plane and dns
kubectl cluster-info dump # get details of cluster
kubectl get nodes # get all nodes info
```

## Deployment

The Deployment instructs Kubernetes how to create and update instances of your application. Once you've created a Deployment, the Kubernetes control plane schedules the application instances included in that Deployment to run on individual Nodes in the cluster.

**[Self-healing]**Once the application instances are created, a Kubernetes Deployment Controller continuously monitors those instances. If the Node hosting an instance goes down or is deleted, the Deployment controller replaces the instance with an instance on another Node in the cluster. **This provides a self-healing mechanism to address machine failure or maintenance.**

get deployment info:

- NAME lists the names of the Deployments in the cluster
- READY shows the ratio of CURRENT/DESIRED replicas
- UP-TO-DATE displays the number of replicas that have been updated to achieve the desired state
- AVAILABLE displays how many replicas of the application are available to your users
- AGE displays the amount of time that the application has been running

```shell
# kube command: kubectl <opeartion> <resource>
kubectl version
# view the nodes in the cluster
kubectl get nodes
# create deployment from existing image
kubectl create deployment kubernetes-bootcamp \
	--image=gcr.io/google-samples/kubernetes-bootcamp:v1
# search all deployment
kubectl get deployments

# Start a proxy of specific cluster(in another terminal tab)
echo -e \
	"\n\n\n\e[92mStarting Proxy. \
	After starting it will not output a response. \
	Please click the first Terminal Tab\n";
kubectl proxy
# Query version though curl API
curl http://localhost:8001/version

# Get Pod name
export POD_NAME=$(kubectl get pods -o go-template --template '{{range .items}}{{.metadata.nae}}{{"\n"}}{{end}}')
echo Name of hte Pod :$POD_NAME
# Query pod info by POD_NAME
curl http://localhost:8001/api/v1/namespaces/default/pods/$POD_NAME/
```

## Pods

Pod 是 Kubernetes 抽象出来的，表示一组一个或多个应用程序容器（如 Docker），以及这些容器的一些共享资源。这些资源包括:

- 共享存储，当作卷
- 网络，作为唯一的集群 IP 地址
- 有关每个容器如何运行的信息，例如容器映像版本或要使用的特定端口

Pod是 Kubernetes 平台上的原子单元。 当我们在 Kubernetes 上创建 Deployment 时，该 Deployment 会在其中创建包含容器的 Pod （而不是直接创建容器）。每个 Pod 都与调度它的工作节点绑定，并保持在那里直到终止（根据重启策略）或删除。 如果工作节点发生故障，则会在群集中的其他可用工作节点上调度相同的 Pod。

一个 pod 总是运行在 **工作节点**。工作节点是 Kubernetes 中的参与计算的机器，可以是虚拟机或物理计算机，具体取决于集群。每个工作节点由主节点管理。工作节点可以有多个 pod ，Kubernetes 主节点会自动处理在群集中的工作节点上调度 pod 。 主节点的自动调度考量了每个工作节点上的可用资源。

每个 Kubernetes 工作节点至少运行:

- Kubelet，负责 Kubernetes 主节点和工作节点之间通信的过程; 它管理 Pod 和机器上运行的容器。
- 容器运行时（如 Docker）负责从仓库中提取容器镜像，解压缩容器以及运行应用程序

### 查看pods信息

```shell
# View all pods
kubectl get pods
# Get details of pods
kubectl describe pods
```

`describe pods`中内容主要包括：

- basic: Name \\ Namespace \\ Priority \\ Node \\ Start Time \\ Labels \\ Annotations \\ Status
- Network: IP \\ IPs
- Container Info: Controlled By \\ Containers
- Others: Conditions \\ Volumes \\ QoS Class \\ Node-Selectors \\ Tolerations \\ Events

### 开启proxy并查看日志

```shell
# Start a proxy of specific cluster(in another terminal tab)
echo -e \
	"\n\n\n\e[92mStarting Proxy. \
	After starting it will not output a response. \
	Please click the first Terminal Tab\n";
kubectl proxy

# Go back to terminal 1
curl http://localhost:8001/version
export POD_NAME=$(kubectl get pods -o go-template --template '{{range .items}}{{.metadata.nae}}{{"\n"}}{{end}}')
echo Name of hte Pod :$POD_NAME

# View logs of pod
kubectl logs $POD_NAME
```

### 运行exec

```shell
# List the environment variables
kubectl exec $POD_NAME -- env

# Exec an ECHO server on target
kubectl exec -ti $POD_NAME -- bash
cat server.js
curl localhost:8080
exit
```

`server.js`内容如下输出当前Pod信息

```javascript
var http = require('http');
var requests=0;
var podname= process.env.HOSTNAME;
var startTime;
var host;
var handleRequest = function(request, response) {
  response.setHeader('Content-Type', 'text/plain');
  response.writeHead(200);
  response.write("Hello Kubernetes bootcamp! | Running on: ");
  response.write(host);
  response.end(" | v=1\n");
  console.log("Running On:" ,host, "| Total Requests:", ++requests,"| App Uptime:", (new Date() - startTime)/1000 , "seconds", "| Log Time:",new Date());
}
var www = http.createServer(handleRequest);
www.listen(8080,function () {
    startTime = new Date();;
    host = process.env.HOSTNAME;
    console.log ("Kubernetes Bootcamp App Started At:",startTime, "| Running On: " ,host, "\n" );
});
```

## Services

Kubernetes 中的服务(Service)是一种抽象概念，它定义了 Pod 的逻辑集和访问 Pod 的协议。Service 使从属 Pod 之间的松耦合成为可能。 和其他 Kubernetes 对象一样, Service 用 YAML [(更推荐)](https://kubernetes.io/zh/docs/concepts/configuration/overview/#general-configuration-tips) 或者 JSON 来定义. Service 下的一组 Pod 通常由 *LabelSelector* (请参阅下面的说明为什么您可能想要一个 spec 中不包含`selector`的服务)来标记

尽管每个 Pod 都有一个唯一的 IP 地址，但是如果没有 Service ，这些 IP 不会暴露在群集外部。Service 允许您的应用程序接收流量。Service 也可以用在 ServiceSpec 标记`type`的方式暴露

- *ClusterIP* (默认) - 在集群的内部 IP 上公开 Service 。这种类型使得 Service 只能从集群内访问。
- *NodePort* - 使用 NAT 在集群中每个选定 Node 的相同端口上公开 Service 。使用`<NodeIP>:<NodePort>` 从集群外部访问 Service。是 ClusterIP 的超集。
- *LoadBalancer* - 在当前云中创建一个外部负载均衡器(如果支持的话)，并为 Service 分配一个固定的外部IP。是 NodePort 的超集。
- *ExternalName* - 通过返回带有该名称的 CNAME 记录，使用任意名称(由 spec 中的`externalName`指定)公开 Service。不使用代理。这种类型需要`kube-dns`的v1.7或更高版本。

```shell
# check pods
kubectl get pods
kubectl get services
# expose port
kubectl expose deployment/kubernetes-bootcamp --type="NodePort" --port 8080
kubectl get services
#  
kubectl describe services/kubernetes-bootcamp
export NODE_PORT=$( \
	kubectl get services/kubernetes-bootcamp \
		-o go-template='{{(index .spec.ports 0).nodePort}}')
curl $(minikube ip):$NODE_PORT
# Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-fb5c67579-5s86v | v=1

# The deployment create automatically a label for Pod
# using labels
kubectl describe deployment
kubectl get pods -l app=kubernetes-bootcamp
kubectl get services -l app=kubernetes-bootcamp

# Store labels in environment variable
export POD_NAME=$(kubectl get pods -o go-template --template '{{range .items}}\
	{{.metadata.name}}{{"\n"}}{{end}}')
echo Name of the Pod: $POD_NAME
# apply new labels on pods
kubectl label pods $POD_NAME version=v1
# check new labels
kubectl describe pods $POD_NAME
# select pods by label
kubectl get pods -l version=v1

# Check current service
kubectl get services
kubectl delete service -l app=kubernetes-bootcamp
kubectl get services
# Check app could not be reachable from outside by curl
curl $(minikube ip):$NODE_PORT
# Get app from inner side of pods(still reachable)
kubectl exec -ti $POD_NAME -- curl localhost:8080

```

## Scaling

**Scaling** is accomplished by changing the number of replicas in a Deployment.

Scaling will increase the number of Pods to the new desired state. Kubernetes also supports [autoscaling](https://kubernetes.io/docs/user-guide/horizontal-pod-autoscaling/) of Pods, but it is outside of the scope of this tutorial. Scaling to zero is also possible, and it will terminate all Pods of the specified Deployment.

```shell
kubectl get deployment
# get replica set
kubectl get rs
kubectl scale deployments/kubernetes-bootcamp --replicas=4
kubectl get deploments
kubectl get pods -o wide
kubectl describe deployments/kubernetes-bootcamp

# view load balancing
kubectl describe services/kubernetes-bootcamp
export NODE_PORT=$(kubectl get services/kubernetes-bootcamp -o go-template='{{(index .spec.ports 0).nodePort}}')
export NODE_PORT=$NODE_PORT
# get different pods everytime
curl $(minikube ip):$NODE_PORT

# Dcale Down
kubectl scale deployments/kubernetes-bootcamp --replicas=2
kubectl get deployments
# show 2 terminated pods
kubectl get pods -o wide
```

## Rolling Update——pod的滚动更新

By default, the maximum number of Pods that can be unavailable during the update and the maximum number of new Pods that can be created, is one.

Both options can be configured to either numbers or percentages (of Pods). In Kubernetes, updates are versioned and any Deployment update can be reverted to a previous (stable) version.

```shell
kubectl get deployments
kubectl get pods
# check images version
kubectl describe pods
kubectl set image deployments/kubernetes-bootcamp \
	kubernetes-bootcamp=jocatalin/kubernetes-bootcamp:v2
kubectl get pods

# verify an update
kubectl describe services/kubernetes-bootcamp
export NODE_PORT=$(kubectl get service/kubernetes-bootcamp -o \
	go-template='{{(index .spec.port 0).nodePort}}')
echo NODE_PORT=$NODE_PORT
# get different pods and its service version
curl $(minikube ip):$NODE_PORT
# check rolling out status
kubectl rollout status deployments/kubernetes-bootcamp
# get pods
kubectl describe pods

# Rolling back 
kubectset image deployments/kubernetes-bootcamp kubernetes-bootcamp=gcr.io/google-samples/kubernetes-bootcamp:v10
kubectl get deployments
kubectl get pods
kubectl describe pods
# Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 out of 4 new replicas have been updated...

kubectl rollout undo deployments/kubernetes-bootcampdeployment.apps/kubernetes-bootcamp rolled back
kubectl get pods
kubectl describe pods
```

