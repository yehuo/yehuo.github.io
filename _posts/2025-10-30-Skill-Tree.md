---
title: "计算机网络基础"
date: 2025-10-30
categories:
  - Network
tags:
  - Basic
excerpt: "一些常见的计算机网络面试问题"
---

# 基础知识

## 计算机网络
### 基础概念：OSI网络模型
### 网络协议：TCP、UDP、HTTP
### 网络调优：抓包、Wireshark使用
### 路由配置：防火墙、SelinuX、四层、七层路由


## 操作系统
### Linux基础概念
- 进程管理：进程的7个状态、进程调度、进程间通信、daemon进程
- 内存管理：虚拟内存、内存分页与交换、内存应谁（mmap）、缓冲与缓存
- 文件系统：FHS、inode&block、文件类型、挂载机制（mount\umount）
- 系统引导：BIOS/UEFI、Bootloader、Kernel、Init、Runlevel、systemd初始化系统
- 内核机制：系统调用（syscall）、中断处理、模块加载与卸载
### shell编写
- 文本处理
    - awk
    - sed
    - grep
- 文件处理
    - 目录处理：ls\cat\find\rm\mv\touch\mkdir
    - 文件比较：diff\cmp
    - 压缩解压：tar\gzip\zip
- 权限管理
    - chmod\chown\chgrp
    - 文件权限（rwx）、特殊权限（suid\sgid\sticky）
    - useradd\groupadd\passwd
- IO处理
    - 管道、重定向、stdin
    - 参数传递：xargs
    - 脚本调试：set\trap
    - 脚本传参：$0、$1、$*、$@
- 网络连接：
    - 基础诊断：telnet/ssh/ping/traceroute
    - 文件传输：scp/rsync/wget/curl
    - 内网穿透：frp/ngrok
    - 防火墙：iptables/firewalld/ufw
    - 网络配置：ifconfig/ip/route
- 系统监控：
    - 进程监控：top/htop/ps/pstree/perf
        - [Linux Perf 性能分析工具及火焰图浅析](https://zhuanlan.zhihu.com/p/54276509)
    - 性能分析：vmstat/iostat/mpstat
    - 内存监控：free/smaps
    - 磁盘监控：df/du/lsblk/lsof
    - 网络监控：netstat/ss/iftop
- 服务管理
    - systemctl：服务启停、状态查看、开机自启
    - journalctl：日志查看与分析
    - cron：定时任务管理
- Package管理
    - Debian/Ubuntu：apt/apt-get/dpkg
    - CentOS/RHEL：yum/dnf/rpm
### 高级内容

#### 容器
- namespace隔离机制
- cgroups资源限制
- 容器运行时原理

#### 性能
- 系统调优参数（sysctl）
- 内存回收机制
- I/O调度算法

#### 安全
- SELinux/AppArmor
- 审计日志（auditd）
- 系统加固原则

## 计算机组成原理（硬件）
### CPU & GPU
- CPU时钟频率计算
- CPU和GPU区别
### Memory
### Disk
- Raid
### Power

## 算法
### 字符串处理
### 动态规划
### 树
### 深搜、广搜
### 图
### 链表
### 栈

# 硬件&系统
## 硬件配置
- ipmi\redfish
- 
## 系统引导+打包
- netboot
##

# 基础架构
## 虚拟化
- Docker
    - 基础概念：cgroup、不可变交付、隔离依赖
    - 基础知识：
        - DOCKER-CE
        - 运行docker容器：`docker run`
        - Dockerfile
        - 镜像管理：构建、推送、版本控制
        - 网络管理：bridge、host、overlay、各级别通信模型
        - 存储管理：储存外挂、文件权限
    - 进阶知识：
        - docker-composer
        - 分阶段
- Kubernetes
    - Pod/Deployment/Service/Ingress资源管理
    - 服务发现与负载均衡
    - 配置管理（ConfigMap/Secret）
    - 存储管理（PV/PVC/StorageClass）
    - HPA/VPA自动扩缩容
    - 网络策略（NetworkPolicy）
    - 集群运维（备份恢复、升级）
    - 本地实践：
        - minikube
        - microk8s
        - k3s
    - Helm/Kuberlizer
- Proxmox
    - 虚拟机生命周期管理
    - 集群管理与高可用
    - 存储配置（LVM、Ceph）
    - 备份与恢复策略
    - 安全隔离设计
- Openstack
    - 核心组件架构（Nova、Neutron、Cinder等）
    - 云资源管理
    - 多租户隔离
    - 计量与计费

## CI/CD
### CI
- Jenkins
- ArgoWorkflow
- Gitea
- GithubAction
### CD
- ArgoCD
- FluxCD
### 技术方案
- Jenkins => Docker => Shell
- Gitea => Python => Shell
- Gitlab CI/CD => Docker|Kubernetes => Shell

## IaC
- Terraform
- Ansible
- CloudFormation

## 监控告警
- Prometheus
- Grafana
- Alertmanager
- APM+Agent探针

# 支持服务

## 可观测性：日志、指标、追踪
- Elasticsearch
    - 集群规划与容量管理
    - 索引生命周期管理
    - 性能调优
    - 安全配置
- 日志收集
    - Fluentd/Fluent Bit：日志采集与转发
    - Logstash：日志处理管道
    - Loki：轻量级日志聚合

- 链路追踪
    - Jaeger：分布式追踪
    - Zipkin：调用链分析
    - OpenTelemetry：可观测性标准

- 指标监控
    - VictoriaMetrics：高性能时序数据库
    - InfluxDB：时间序列数据存储
- Istio
    - https://istio.io/latest/zh/docs/concepts/what-is-istio/
    - 包括服务发现、负载均衡、故障恢复、度量和监控等。服务网格通常还有更复杂的运维需求，比如 A/B 测试、金丝雀发布、速率限制、访问控制和端到端认证。
    - 服务网格
    - API流量管控
    - 多版本API分流


## 数据库
- 数据库基础
    - ACID特性
    - 事务隔离级别
    - 索引原理与优化
    - 查询执行计划
    - 备份恢复策略
    - 高可用方案（主从、集群）
- MySQL
- SQLite
- PostgreSQL
- SQLite
- Redis
- MongoDB

## 消息队列
- Kafka
- RabbitMQ

## 存储服务
### 对象存储
- MinIO
- Ceph
### 文件存储
- NFS服务
- CephFS

## 云服务
### AWS


# 编程语言
## 脚本：Python & Go
## 前端：Javascript & Typescript
## 计算：Cpp
## 后端：Java