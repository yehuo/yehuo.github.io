---
title: "Container Deepdive in Kubernetes"
date: 2024-12-11
excerpt: "k8s常见面试问题"
categories: 
    - Kubernetes
tags: 
    - Node
    - Container
---



# Pause 容器

Kubernetes 的 pod 实现基于 Linux 的 namespace 和 cgroups，为容器提供了良好的隔离环境。在同一个pod中，不同容器犹如在 localhost 中。

但是容器之间会遇到网络无法共享问题，容器内部也会出现“孤儿进程”无法回收问题。

## 资源回收问题

在Unix系统中，PID为`1`的进程为init进程，即所有进程的父进程。它很特殊，维护一张进程表，不断地检查进程状态。例如，一旦某个子进程由于父进程的错误而变成了“孤儿进程”，其便会被init进程进行收养并最终回收资源，从而结束进程。

或者，某子进程已经停止但进程表中仍然存在该进程，因为其父进程未进行wait syscall进行索引，从而该进程变成“僵尸进程”，这种僵尸进程存在时间较短。不过如果父进程只wait，而未syscall的话，僵尸进程便会存在较长时间。

同时，init进程不能处理某个信号逻辑，拥有“信号屏蔽”功能，从而防止init进程被误杀。

**容器中使用PID namespace来对PID进行隔离，从而每个容器中均有其独立的init进程**。例如对于寄主机上可以用个发送`SIGKILL`或者`SIGSTOP`(也就是docker kill 或者docker stop)来强制终止容器的运行，即终止容器内的init进程。一旦init进程被销毁， 同一PID管理的namespace下的进程也随之被销毁，并容器进程被回收相应资源。

Kubernetes中的pause容器便被设计成为每个业务容器提供以下功能：

- 在pod中担任Linux命名空间共享的基础
- 启用pid命名空间，开启init进程

# cAdvisor是什么

 cAdvisor对Node机器上的资源及容器进行实时监控和性能数据采集，包括CPU使用情况、内存使用情况、网络吞吐量及文件系统使用情况，cAdvisor集成在Kubelet中，当kubelet启动时会自动启动cAdvisor，即一个cAdvisor仅对一台Node机器进行监控。kubelet的启动参数 `--cadvisor-port` 可以定义cAdvisor对外提供服务的端口，默认为4194。可以通过浏览器访问。项目主页：[cadvisor]([http://github.com/google/cadvisor)。

在k8s中cAdvisor 负责单节点内部的容器和节点资源使用统计，内置在 Kubelet 内部，并通过 Kubelet `/metrics/cadvisor` 对外提供 API。

从 v1.7 开始，Kubelet metrics API 不再包含 cadvisor metrics，而是提供了一个独立的 API 接口：

- Kubelet metrics: `http://127.0.0.1:8001/api/v1/proxy/nodes/<node-name>/metrics`
- Cadvisor metrics: `http://127.0.0.1:8001/api/v1/proxy/nodes/<node-name>/metrics/cadvisor`

注意：cadvisor 监听的端口将在 v1.12 中删除，建议所有外部工具使用 Kubelet Metrics API 替代。

# 其他k8s监控方案组件

Kubernetes 社区提供了一些列的工具来监控容器和集群的状态，并借助 Prometheus 提供告警的功能。

- [cAdvisor](http://github.com/google/cadvisor) 负责单节点内部的容器和节点资源使用统计，内置在 Kubelet 内部，并通过 Kubelet `/metrics/cadvisor` 对外提供 API
- [InfluxDB](https://www.influxdata.com/time-series-platform/influxdb/) 是一个开源分布式时序、事件和指标数据库；而 [Grafana](http://grafana.org/) 则是 InfluxDB 的 Dashboard，提供了强大的图表展示功能。它们常被组合使用展示图表化的监控数据。
- [metrics-server](https://kubernetes.feisky.xyz/setup/addon-list/metrics) 提供了整个集群的资源监控数据，但要注意
  - Metrics API 只可以查询当前的度量数据，并不保存历史数据
  - Metrics API URI 为 `/apis/metrics.k8s.io/`，在 [k8s.io/metrics](https://github.com/kubernetes/metrics) 维护
  - 必须部署 `metrics-server` 才能使用该 API，metrics-server 通过调用 Kubelet Summary API 获取数据
- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) 提供了 Kubernetes 资源对象（如 DaemonSet、Deployments 等）的度量。
- [Prometheus](https://prometheus.io/) 是另外一个监控和时间序列数据库，还提供了告警的功能。
- [Node Problem Detector](https://github.com/kubernetes/node-problem-detector) 监测 Node 本身的硬件、内核或者运行时等问题。
- [Heapster](https://github.com/kubernetes/heapster) 提供了整个集群的资源监控，并支持持久化数据存储到 InfluxDB 等后端存储中（已弃用）

# kube-proxy的工作模式

Kubernetes里 `kube-proxy` 支持三种模式，在v1.8之前使用的是iptables 以及 userspace两种模式，在kubernetes 1.8之后引入了ipvs模式，并且在v1.11中正式使用，其中iptables和ipvs都是内核态也就是基于netfilter，只有userspace模式是用户态。

## userspace mode

起初，`kube-proxy` 进程是一个真实的TCP/UDP代理，在用户空间运行，监听 Kubernetes API Server 的服务和端点变化，然后创建相应的 iptables 规则。

在 clusterIP 模式下，外部访问某个 Service 的时候，流量会被 pod 所在的本机的 `iptables` 转发到 node 的 kube-proxy 进程，然后将请求转发到后端某个pod上。

具体过程为：

1. kube-proxy为每个service在node上打开一个随机端口作为代理端口
2. 建立iptables规则，将ClusterIP的请求重定向到代理端口（用户空间）
3. 到达代理端口的请求再由kubeproxy转发到后端

ClusterIP 模式中重定向到 kube-proxy 服务的过程存在内核态到用户态的切换，开销很大，因此有了iptables模式，userspace 模式也被废弃了。

## iptables

kubernets从1.2版本开始将iptabels模式作为默认模式，这种模式下kube-proxy不再起到proxy的作用。

其核心功能：**kubeproxy 通过 API Server 的 Watch 接口实时跟踪 Service 和 Endpoint 的变更信息，并更新对应的 iptables 规则。外部请求流量到达时，通过 iptables 的 NAT机制 直接转发到目标Pod，业务流量转发过程不再有kubeproxy的参与。** 

不同于userspace，iptables由kube-proxy动态的管理，kube-proxy不再负责转发，数据包的走向完全由iptables规则决定，这样的过程不存在内核态到用户态的切换，效率明显会高很多。但是随着service的增加，iptables规则会不断增加，导致内核十分繁忙（等于在读一张很大的没建索引的表）。

2个svc，8个pod就有34条iptabels规则了，随着集群中svc和pod大量增加以后，iptables中的规则开会急速膨胀，导致性能下降，某些极端情况下甚至会出现规则丢失的情况，并且这种故障难以重现和排查。

## ipvs

从kubernetes 1.8版本开始引入第三代的IPVS模式，它也是基于netfilter实现的，但定位不同：iptables是为防火墙设计的，IPVS则专门用于高性能。

负载均衡，并使用高效的数据结构Hash表，允许几乎无限的规模扩张。

一句话说明：**ipvs使用ipset存储iptables规则，在查找时类似hash表查找，时间复杂度为O(1)，而iptables时间复杂度则为O(n)。**

假设要禁止上万个IP访问我们的服务器，如果用iptables的话，就需要一条一条的添加规则，会生成大量的iptabels规则；但是用ipset的话，只需要将相关IP地址加入ipset集合中即可，这样只需要设置少量的iptables规则即可实现目标。

**由于ipvs无法提供包过滤、地址伪装、SNAT等功能，所以某些场景下（比如NodePort的实现）还要与iptables搭配使用。**



## Reference

- https://o-my-chenjian.com/2017/10/17/The-Pause-Container-Of-Kubernetes/
- https://sheldon-lu.github.io/sheldon_Gitbook/exporter/use-prometheus-monitor-container.html
- https://www.huweihuang.com/kubernetes-notes/monitor/cadvisor-introduction.html
- https://www.cnblogs.com/yrxing/p/15920398.html
- https://www.ctyun.cn/developer/article/559286309208133