---
title: "Monitoring in Kubernetes"
date: 2024-01-02
excerpt: "在Node级别监控Kubernetes的监控"
categories: 
    - Kubernetes
tags: 
    - Node
    - Cluster
    - Addons
---



# 使用

# 使用cAdvisor在内核级别进行监控

cAdvisor对Node机器上的资源及容器进行实时监控和性能数据采集，包括CPU使用情况、内存使用情况、网络吞吐量及文件系统使用情况，cAdvisor集成在Kubelet中，当kubelet启动时会自动启动cAdvisor，即一个cAdvisor仅对一台Node机器进行监控。kubelet的启动参数 `--cadvisor-port` 可以定义cAdvisor对外提供服务的端口，默认为4194。可以通过浏览器访问。项目主页：[cadvisor]([http://github.com/google/cadvisor)。

在k8s中cAdvisor 负责单节点内部的容器和节点资源使用统计，内置在 Kubelet 内部，并通过 Kubelet `/metrics/cadvisor` 对外提供 API。

从 v1.7 开始，Kubelet metrics API 不再包含 cadvisor metrics，而是提供了一个独立的 API 接口：

- Kubelet metrics: `http://127.0.0.1:8001/api/v1/proxy/nodes/<node-name>/metrics`
- Cadvisor metrics: `http://127.0.0.1:8001/api/v1/proxy/nodes/<node-name>/metrics/cadvisor`

注意：cadvisor 监听的端口将在 v1.12 中删除，建议所有外部工具使用 Kubelet Metrics API 替代。

# 使用Exporter在Node级别部署监控

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