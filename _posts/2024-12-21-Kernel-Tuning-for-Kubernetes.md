---
title: "Kernel Tuning for Kubernetes"
date: 2024-12-21
excerpt: "如何优化Linux内核参数来调优Kubernetes性能"
categories: 
    - Kubernetes
tags: 
    - Node
    - System
---



要通过调整内核参数来优化 Kubernetes 节点的性能，可以从以下四个关键领域进行优化：网络 (Network)、内存 (Memory)、文件系统 (File System) 和 进程调度 (Process Scheduling)。下面逐一讨论每个方面的具体调整及其所需的内核参数。

# 1. 网络优化 Networking

网络性能对于 Kubernetes 的正常运行至关重要，尤其是在分布式容器环境中。为了确保高效的数据传输和低延迟，必须对网络参数进行调优

## 措施

- `net.nf_conntrack_max`：调整最大连接跟踪条目数（默认值通常是 262144），这是 Kubernetes 环境中为了支持大规模容器通信所必需的。根据网络负载，可以将其设置为更高的值，如 1024288，以避免连接跟踪溢出。
- `net.netfilter.nf_conntrack_tcp_timeout_established`：调整已建立 TCP 连接的超时时间（通常为 86400 秒，即 1 天），这是默认值，但如果在长时间活跃的连接中工作，可能需要保留更长的连接时间。
- `net.bridge.bridge-nf-call-iptables` 和 `net.bridge.bridge-nf-call-ip6tables`：启用 iptables 和 ip6tables 的处理，确保 Kubernetes 中的容器与外部网络进行适当的流量管理。
- `net.ipv4.tcp_max_syn_backlog`：调整 TCP SYN 队列的大小，以便在网络负载较重时能处理更多的连接请求。一般将其设置为 100000 以支持大量的并发连接。
- `net.core.netdev_max_backlog` 和 `net.core.somaxconn`：调整网络设备的最大背压队列大小，以及最大 TCP 连接数，避免在高流量情况下丢失请求。
- `tcp_rmem` 和 `tcp_wmem`：对于长延迟和大带宽的网络环境，需要增加 TCP 的接收和发送缓冲区，以避免丢包。调整 tcp_rmem 和 tcp_wmem 参数，可以通过增大缓冲区来提高网络吞吐量。

## 方案

```yaml
  net.nf_conntrack_max: 1024288  # 增加连接跟踪表的大小
  net.netfilter.nf_conntrack_tcp_timeout_established: 86400  # 已建立连接的超时设置
  net.bridge.bridge-nf-call-iptables: 1
  net.bridge.bridge-nf-call-ip6tables: 1
  net.ipv4.tcp_max_syn_backlog: 100000  # 增加 TCP SYN 队列大小
  net.core.netdev_max_backlog: 100000
  net.core.somaxconn: 65535
  net.ipv4.tcp_rmem: 4096 87380 8388608
  net.ipv4.tcp_wmem: 4096 87380 8388608
```

# 2.内存优化 Memory Management

在 Kubernetes 环境中，内存的分配和管理直接影响节点的稳定性和性能。对内存参数的优化可以有效避免内存不足或内存泄漏的问题。

## 措施

- `vm.overcommit_memory`：控制内存过度分配策略。当设置为 `1` 时，内核允许内存过度分配，适用于内存消耗较高的应用。对于 Kubernetes，通常会选择允许内存过度分配，但需要谨慎使用，避免导致 OOM（内存溢出）问题。
- `vm.swappiness`：禁用或减少 Swap 的使用，避免将内存交换到磁盘，导致 I/O 瓶颈。设置为 `0` 可以完全禁用 swap 的使用。
- `vm.watermark_scale_factor` 和 `vm.min_free_kbytes`：通过调整内存回收的水位线来提高内存回收的效率，减少内存紧张时的延迟。通过调整 `min_free_kbytes`，可以增加内存压力时的预警阈值，防止过早地触发交换。

## 方案

```yaml
  vm.overcommit_memory: 1  # 允许过度分配内存
  vm.swappiness: 0  # 禁用 swap
  vm.watermark_scale_factor: 200
  vm.min_free_kbytes: 1048576  # 设定为总内存的 1%
```

# 3. 存储优化（文件系统优化）File Systems

文件系统的性能对 Kubernetes 节点的 I/O 操作和存储密集型应用有很大影响。优化文件系统可以提升磁盘访问速度，减少磁盘瓶颈。

## 措施

- `fs.file-max`：调整系统最大可打开文件描述符的数量。对于 Kubernetes 节点和容器，可能会有大量的文件描述符需要管理，增加这个值可以避免达到文件描述符的上限，防止应用崩溃。
- `fs.inotify.max_user_watches`：调整 inotify 的监视限制，增加容器对文件的监控能力，避免容器在文件系统事件较多的情况下出现问题。

## 方案

```yaml
  fs.file-max: 2097152  # 增加最大可打开文件描述符数
  fs.inotify.max_user_watches: 524288  # 增加 inotify 监视限制
```


- fs.file-max
- fs.inotify.max_user_watches


# 4. 进程调度优化 Process Scheduling

进程调度是确保 Kubernetes 中的各个容器和 Pod 能够高效地共享 CPU 资源的关键。调整调度器参数可以确保系统在高负载下依然保持良好的响应时间和吞吐量。

## 措施

- `kernel.sched_child_runs_first`：调度策略参数，用于决定子进程是否应该优先运行。对于 Kubernetes 中的短生命周期进程，设置该参数为 1 可以提高其调度优先级。
- `kernel.sched_latency_ns` 和 `kernel.sched_min_granularity_ns`：这两个参数控制进程调度的延迟和最小粒度时间。如果你需要确保任务得到及时响应，可以适当减少这些参数的值，调整任务调度的精度。
- `kernel.sched_rr_timeslice_ms`：为实时进程配置时间片长度，确保高优先级任务能够及时获得 CPU 资源。

## 方案

```yaml
kernel.sched_latency_ns: 10000000  # 调整调度延迟
kernel.sched_min_granularity_ns: 4000000  # 最小调度粒度
kernel.sched_rr_timeslice_ms: 10  # 设置实时进程的时间片长度
```

# 使用Ansible部署上述优化

```yaml
---
- name: Network Tuning
  sysctl:
    name: '{{ item.key }}'
    value: '{{ item.value }}'
  with_dict:
    net.nf_conntrack_max: 1024288  # default is 262144
    net.netfilter.nf_conntrack_tcp_timeout_established: 86400  # default is 86400 seconds, 1 day
    net.bridge.bridge-nf-call-iptables: 1
    net.bridge.bridge-nf-call-ip6tables: 1
    net.ipv4.tcp_max_syn_backlog: 100000
    net.core.netdev_max_backlog: 100000
    net.core.somaxconn: 65535
    net.ipv4.tcp_rmem: 4096 87380 8388608
    net.ipv4.tcp_wmem: 4096 87380 8388608

- block:
    - name: Collect memory size
      shell: "cat /proc/meminfo  | grep MemTotal | tr -s ' ' | cut -d' ' -f 2"
      register: raw_total_memory_output_in_kb

    - set_fact:
        min_free_kbytes_ratio_of_total_memory: 0.01

    - name: Memory Tuning
      sysctl:
        name: '{{ item.key }}'
        value: '{{ item.value }}'
      with_dict:
        vm.watermark_scale_factor: 200
        vm.min_free_kbytes: "{{ (raw_total_memory_output_in_kb.stdout | int * min_free_kbytes_ratio_of_total_memory) | int }}"  # default is 90MB
        vm.swappiness: 0
  when: enable_k8s_disk_optimization | default(False) | bool
```

## Reference

- [5.5. Tuning Virtual Memory](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/6/html/performance_tuning_guide/s-memory-tunables)
- [Anticipating Your Memory Needs](https://blogs.oracle.com/linux/post/anticipating-your-memory-needs)
- [Kernel Tuning and Optimization for Kubernetes: A Guide](https://overcast.blog/kernel-tuning-and-optimization-for-kubernetes-a-guide-a3bdc8f7d255)