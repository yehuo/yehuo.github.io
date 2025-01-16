---
title: Core Addons in Kubernetes
date: 2023-07-02
excerpt: "Some details about three core addons(CNI, CoreDNS, KubePorxy) work for control plane of Kuberenetes."
categories: 
    - Kubernetes
tags: 
    - Addons
---



# 0x01 Background

Kubernetes 升级过程中，往往需要为三个核心组件进行升级，这篇文章简单分析下。

- **CNI**，Container Network Interface，容器接口插件，负责pod对外的通信
- **KubeProxy**，在 Node 上以 DeamonSet 方式存在，监听 APIServer 对 Service 的变更，支持通过 Service 对 Pod 的直接访问，在 Node 中实现 Service 负载均衡和服务发现
- **CoreDNS**，负责在集群内部内部，支持对Service/Pod别名进行DNS查询

# 0x02 CNI，Container Network Interface

## 1. 介绍及安装

Kubernetes Pod 调用底层网络进行通信的一个通用接口标准，包括常见的 CNI 插件包括 Calico、flannel、Terway、Weave Net 以及 Contiv。具体使用方法就是**配置**+**下载**+**kubelet调用**：

1. 首先在每个结点上配置 CNI 配置文件`/etc/cni/net.d/xx-net.conf`，其中 `xx-net.conf` 是指定CNI配置文件
2. 安装 CNI 配置文件中所对应的二进制插件`/opt/cni/bin`
3. 在这个节点上创建 Pod 之后，Kubelet 就会根据 CNI 配置文件执行所安装的 CNI 插件
4. 之后kubelet会自动完成Pod 的网络配置

> 在集群里面创建一个 Pod 的时候，首先会通过 apiserver 将 Pod 的配置写入。
>
> apiserver 的一些管控组件（比如 Scheduler）会调度Pod到某个具体的节点上去。
>
> 节点上Kubelet 监听到这个 Pod 的创建之后，会在本地进行一些创建的操作。
>
> 当执行到创建Pod网络这一步骤时，Kubelet首先会读取刚才我们所说的配置目录中的配置文件，配置文件里面会声明所使用的是哪一个插件，然后去执行具体的 CNI 插件的二进制文件，再由 CNI 插件进入 Pod 的网络空间去配置 Pod 的网络。
>
> 配置完成之后，Kuberlet 也就完成了整个 Pod 的创建过程，这个 Pod 就在线了。

实际过程中，在k8s集群中，只要在client端使用kubectl，一条命令就可以完成二进制包从master到worker的分发、配置、安装（以flannel为例）：`kubectl apply -f kube-flannel.yml`

## 2. 选型及性能分析

根据Pod网络构建方式，CNI通常分为三种模式：

- **Overlay 模式**的典型特征是容器独立于主机的 IP 段，这个 IP 段进行跨主机网络通信时是通过在主机之间创建隧道的方式，将整个容器网段的包全都封装成底层的物理网络中主机之间的包。该方式的好处在于它不依赖于三层以下的底层网络支持互访，创建过程中只需要调用内核接口，而无需创建更为底层的网络资源。**通常也是大部分云主机厂选用的方式。**
- **路由模式**中主机和容器也分属不同的网段，它与 Overlay 模式的主要区别在于它的跨主机通信是通过路由打通，无需在不同主机之间做一个隧道封包。但路由打通就需要部分依赖于底层网络，比如说要求底层网络有二层可达的一个能力。**可以理解成维护一个构建在节点上的转发规则库。**
- **Underlay 模式**中容器和宿主机位于同一层网络，两者拥有相同的地位。容器之间网络的打通主要依靠于底层网络。因此该模式是强依赖于底层能力的。

而关于选型通常从环境、功能、需求三个方面去考量。

- 环境：部署环境分为虚拟化、主机、公有云，虚拟化条件下由于网络限制较多，优先使用Overlay会更容易配置，例如flannel-vxlan，calico-ipip，Weave等。主机条件下，Underlay和路由插件会更便于布置，例如calico-bgp，flannel-hostgw，sriov等。虚拟化条件则需要优先考虑云厂商自身的方案，例如aliyun的Terway。
- 功能：功能主要点在支持定制安全规则，支持对集群外资源访问，支持服务发现与负载均衡。特别应当注意，例如对pod的访问策略支持，Underlay更适合支持对集群外资源的访问，但大部分Underlay不支持k8s的服务发现与负载均衡。
- 性能：Pod创建速度与网络性能，Overlay通常创建速度较快，但是Underlay网络性能较好。

如果我们自己的环境比较特殊，在社区里面又找不到合适的网络插件，此时可以开发一个自己的 CNI 插件。CNI 插件的实现通常包含两个部分：

- 一个二进制的 CNI 插件去配置 Pod 网卡和 IP 地址：这一步配置完成之后相当于给 Pod 上插上了一条网线，就是说它已经有自己的 IP、有自己的网卡了；
- 一个 Daemon 进程去管理 Pod 之间的网络打通：在给Pod配了 IP 地址以及路由表后，打通 Pod 之间的通信需要让每一个 Pod 的 IP 地址在集群里面都能被访问到。一般我们是在 CNI Daemon 进程中去做这些网络打通的事情。

具体实现逻辑如下：

1. 构建Pod上网络设施
   1. 给Pod添加网卡：通常我们会用一个 “veth” 这种虚拟网卡，一端放到 Pod 的网络空间，一端放到主机的网络空间，这样就实现了 Pod 与主机这两个命名空间的打通
   2. 给Pod分配地址：**这个 IP 地址有一个要求，我们在之前介绍网络的时候也有提到，就是说这个 IP 地址在集群里需要是唯一的。**如何保障集群里面给 Pod 分配的是个唯一的 IP 地址呢？一般来说我们在创建整个集群的时候会指定 Pod 的一个大网段，按照每个节点去分配一个 Node 网段。比如说上图右侧创建的是一个 172.16 的网段，我们再按照每个节点去分配一个 /24 的段，这样就能保障每个节点上的地址是互不冲突的。然后每个 Pod 再从一个具体的节点上的网段中再去顺序分配具体的 IP 地址，比如 Pod1 分配到了 172.16.0.1，Pod2 分配到了 172.16.0.2，这样就实现了在节点里面 IP 地址分配的不冲突，并且不同的 Node 又分属不同的网段，因此不会冲突。这样就给 Pod 分配了集群里面一个唯一的 IP 地址
   3. 配置 Pod 的 IP 和路由：第一步，将分配到的 IP 地址配置给 Pod 的虚拟网卡；第二步，在 Pod 的网卡上配置集群网段的路由，令访问的流量都走到对应的 Pod 网卡上去，并且也会配置默认路由的网段到这个网卡上，也就是说走公网的流量也会走到这个网卡上进行路由；最后在宿主机上配置到 Pod 的 IP 地址的路由，指向到宿主机对端 veth1 这个虚拟网卡上。这样实现的是从 Pod 能够到宿主机上进行路由出去的，同时也实现了在宿主机上访问到 Pod 的 IP 地址也能路由到对应的 Pod 的网卡所对应的对端上去
2. 构建Pod之间的网络
   1. 首先 CNI 在每个节点上运行的 Daemon 进程会学习到集群所有 Pod 的 IP 地址及其所在节点信息。学习的方式通常是通过监听 K8s APIServer，拿到现有 Pod 的 IP 地址以及节点，并且新的节点和新的 Pod 的创建的时候也能通知到每个 Daemon
   2. 拿到 Pod 以及 Node 的相关信息之后，还需通过配置网络进行打通。**第一步是创建集群内的通道**，Daemon 会创建到整个集群所有节点的通道。这里的通道是个抽象概念，具体实现一般是通过 Overlay 隧道、阿里云上的 VPC 路由表、或者是自己机房里的 BGP 路由完成的；**第二步是将Pod内的IP地址和上一步的通道关联起来**，具体的实现通常是通过 **Linux 路由、fdb 转发表或者OVS 流表**等完成的。Linux 路由可以设定某一个 IP 地址路由到哪个节点上去。fdb 转发表是 forwarding database 的缩写，就是把某个 Pod 的 IP 转发到某一个节点的隧道端点上去（Overlay 网络）。OVS 流表是由 Open vSwitch 实现的，它可以把 Pod 的 IP 转发到对应的节点上。

# 0x02 KubeProxy

KubeProxy 本质是 Service 和 Pod 间的负载均衡器。

虽然 Service 是本身是个虚拟的概念，但 Service 在集群中会有独立的 IP（ClusterIP），Service 实际上就是其独立IP 映射的一个 Pod 资源列表，每个 Pod 资源的信息都使用 endpoint 对象来存储在 etcd 中。

任何对于 Service 的请求需要通过这个 endpoint 列表来对应到所有的 Pod。这个对应关系，存储在 etcd 中，但是实际负责流量分发的，是在 Node 上运行的 KubeProxy 组件。

## 1. Service 资源的概念与实现

当 Kubernetes 创建一个新的 Service 时，有两个组件需要参与，分别是**KubeController** 和 **KubeProxy**。

KubeController 需要生成用于暴露一组 Pod 的 endpoint 对象。其内部又有两个组件来分别监听 Service 创建事件，一个是 ServiceController，另一个是EndpointController，二者需要监听不同的资源变化。

- **ServiceController** 监控 Service 和 Node 两种对象的变化，针对任何新创建或者更新的服务时，Informer 都会通知 ServiceController，它会将这些任务投入工作队列中。其中处理 Node 对象的方法 nodeSyncLoop，主要工作是对比最新节点和原有节点，若有变化则更新对应的 Service。不过 ServiceController 其实只处理了 LoadBalancer 类型的 Service 对象，它会调用云服务商的 API 接口，而不同的云服务商会实现不同的适配器来创建 LoadBalancer 类型的资源。
- **EndpointController** 监控 Service 和 Pod 两种对象的变化，EndpointController 通过 syncService 方法同时订阅 Service 和 Pod 资源的增删事件，并且该方法会根据 Service 对象中的选择器 Selector 获取集群中存在的所有 Pod，最后根据当前集群中的对象生成 endpoint 对象并将两者进行关联。

在集群中另一个订阅 Service 对象变动的组件就是 KubeProxy 了，每个新节点启动时都会初始化一个 ServiceConfig 对象，这个对象用于接受 Service 的变更事件，这些变更事件都会被订阅了集群中对象变动的 ServiceConfig 和 EndpointConfig 对象推送给启动的 Proxier 实例，收到事件变动的 Proxier 实例随后会根据启动时的配置更新 iptables 或者 ipvs 中的规则，这些应用最终会负责对进出的流量进行转发并完成一些负载均衡相关的任务。

Service 资源根据访问方式的不同又分为下面四种

### ClusterIP

默认 Service 类型，自动分配一个仅 Cluster 内部可以访问的虚拟 IP。Service创建一个仅集群内部可访问的ip，集群内部其他的pod可以通过该服务访问到其监控下的 Pod。

### NodePort

在 ClusterIP 基础上为 Service 在每个 Node 上绑定一个端口，这样就可以通过 Node 上不同的端口来访问该服务。在 Service 及各个node节点上开启端口，外部的应用程序或客户端访问node的端口将会转发到service的端口，而service将会依据负载均衡随机将请求转发到某一个pod的端口上。一般暴露服务常用的端口。

### LoadBalancer

在 NodePort 的基础上，借助 cloud provider 创建一个外部负载均衡器，并将请求转发到NodePort类型的Service上。在 NodePort 基础之上，即各个节点前加入了负载均衡器实现了真正的高可用，云供应商提供的 Kubernetes 集群就是这种。

### ExternalName

把集群外部的服务暴露到集群内部来，在集群内部直接使用。没有任何类型代理被创建，当集群内的服务需要访问外部集群的服务时，可以选择这种类型。ExternalName 类型的 Service 会把外部服务的 IP 及端口写入到当前集群中，Kubernetes 的代理将会帮助内部节点访问到外部的集群服务。


##  2. KubeProxy 代理模式

在 Kubernetes 集群中，每个 Node 运行一个 kube-proxy 进程。kube-proxy 负责为 Service 实现了一种 VIP（虚拟IP）的形式。可以在集群内部直接访问，而不是ExternalName 中**返回集群外部的地址信息**的形式。

在 Kubernetes v1.0 版本，Pod 与 Service 间的代理完通过在Linux系统的 userspace 中实现一个 Proxy 来完成。

到了 Kubernetes v1.1 版本，新增了 iptables 类型代理，但并不是默认的运行模式。从 Kubernetes v1.2 起，iptables 才被确定为默认代理。在 Kubernetes v1.8 中，kube-proxy 又新添加了 ipvs 模式。在 Kubernetes 1.14中，ipvs 模式称为 kube-proxy 默认的代理模式。

> 有意思的是，在 Kubernetes v1.0 中，Service 只是一个 **4层 (TCP/UDP over IP)** 代理概念。在 Kubernetes v1.1 中，新增了 Ingress API，用于在 **7层（HTTP）**实现服务代理，并完成 7层 的负载均衡功能。

### userspace

运行在用户空间的代理功能，所有的流量最终都会通过 kube-proxy 本身转发给其他的服务。

每当有新的 Service 被创建时，kube-proxy 就会增加一条 iptables 记录并启动一个 go routine，前者用于将节点中服务对外发出的流量转发给 kube-proxy，再由后者持有的一系列 go routine 将流量转发到目标的 Pod 上。

userspace 代理模式有明显的性能问题，外部请求到达 Node 节点后，会先进入内核的 iptables，然后回到用户空间的 kube-proxy，这个过程很明显性能消耗。

### iptables

iptables 是 KubeProxy 默认的代理模式，其通过直接配置 iptable rule 来转发 Node 上的全部流量，这种模式解决了用户空间到内核空间实现转发的方式能够极大地提高 KubeProxy 的效率，增加节点的吞吐量。

**对于 ClusterIP 类型的 Service**，如果是非当前 Node 的访问，那么所有的流量都会先经过 PREROUTING，随后进入 Kubernetes 自定义的链入口 KUBE-SERVICES、单个 Service 对应的链 KUBE-SVC-XXXX 以及每个 Pod 对应的链 KUBE-SEP-XXXX，经过这些链的处理，最终才能够访问到一个服务的真实 IP 地址。

如果是当前 Node 访问，那么所有的流量都会先经过 OUTPUT，随后进入 Kubernetes 自定义的链入口 KUBE-SERVICES、单个 Service 对应的链 KUBE-SVC-XXXX 以及每个 Pod 对应的链 KUBE-SEP-XXXX。其整个过程可以简单描述为以下过程


> PREROUTING --> KUBE-SERVICES --> KUBE-SVC-XXX --> KUBE-SEP-XXX
 
> OUTPUT --> KUBE-SERVICES --> KUBE-SVC-XXX --> KUBE-SEP-XXX

**对于 NodePort 类型的 Service**，会增加一个 KUBE-NODEPORTS 规则链，其他同上。流量进出过程如下

> PREROUTING --> KUBE-SERVICES --> KUBE-NODEPORTS --> KUBE-SVC-XXX --> KUBE-SEP-XXX

> OUTPUT --> KUBE-SERVICES --> KUBE-NODEPORTS --> KUBE-SVC-XXX --> KUBE-SEP-XXX

### ipvs

在 Service 数目和 Pod 数目逐渐增多时，iptables 规则数目会阶乘级别增加，Node资源往往被大量消耗。

我们都知道 ipvs 是 LVS 的负载均衡模块，与 iptables 比较像的是，ipvs 的实现虽然也基于 netfilter 的 Hook 函数，但是它使用的是Hash Table作为底层的数据结构并且工作在内核态，所以理论上他支持无限数量的 Service。

由于 ipvs 支持三种负载均衡模式：DR、NAT、Tunneling。三种模式中只有 NAT 支持端口映射，所以 ipvs 使用 NAT 模式（DNAT）。而在 SNAT 和 NodePort 类型的服务这几个场景中 Kubernetes 依然还是使用 iptables 来完成。

当然除了提升性能之外，ipvs 额外提供了多种类型的负载均衡算法，除了最常见的 Round-Robin 之外，还支持最小连接、目标哈希、最小延迟等。

## 3. Ingress：Service的Service

当我们向向外部暴露 Service 时，虽然 我们可以使用 **LoadBalancer** 类型的 Service，通过使用 Cloud Provider（比如：TKE 或者 OpenStack）创建一个与该 Service 对应的负载均衡服务。

但是，由于每个 Service 都要创建一个负载均衡，所以这个做法实际上既浪费成本又高。我们其实更希望看到是一个 Kubernetes 集群级别的负载均衡器，通过指定不同的URL，把请求转发给不同的后端 Service。

这种全局的、为了代理不同后端 Service 而设置的负载均衡服务，就是 Kubernetes 里的 Ingress 资源。Ingress 不是 Service 的一个类型，而是在应用层向外代理集群内的多个 Service，通常被称为 Service 的 Service，作为集群内部服务的入口。

# 0x03 CoreDNS

---

## Reference

- [从零开始入门K8s](https://zhuanlan.zhihu.com/p/466113622)
- [深入解析Kubernetes Services](https://zhuanlan.zhihu.com/p/376863759)
- [k8s的svc所有概念和实操详细说明](
