---
title: Ansible Startup
date: 2021-09-01
excerpt: "[马哥系列]中，王晓春关于Ansible的入门课程"
categories: 
    - Notes
tags:
    - Ansible
---



- [Ansible基础及企业应用](https://www.bilibili.com/video/BV1HZ4y1p7Bf)

# 1. 自动化运维应用场景

- 平台架构组建
- 日常运营保障
- 性能、效率优化

## 工具组件

| 任务           | 工具                                                         |
| -------------- | ------------------------------------------------------------ |
| 代码管理SCM    | Github \| GitLab \| SubVersion                               |
| 构建工具       | maven \| gradle                                              |
| 自动部署       | Capistrano \| CodeDeploy                                     |
| 持续集成CI     | Jenkins \| Travis                                            |
| 配置管理       | Ansible \| Saltstack \| Chef \| Puppet                       |
| 容器           | Docker \| Podman \| LXC \| AWS                               |
| 编排           | Kubernetes \| Core \| Mesos                                  |
| 服务注册与发现 | Zookeeper \| etcd \| Consul                                  |
| 日志管理       | ELK \| Logentries                                            |
| 系统监控       | Prometheus \| Zabbix \| Datadog \| Graphite \| Ganglia \| Nagios |
| 性能监控       | Splunk \| New Relic \| AppDynamics                           |
| 压力测试       | JMeter \| Blaze Meter \| loader.io                           |
| 应用服务器     | Tomcat \| JBoss                                              |
| Web服务器      |                                                              |
| 数据库         | ==MySQL== \| Oracle \| PostgreSQL \| mongoDB \| ==redis==    |
| 项目管理       | Jira \| Asana \| Taiga \| Trello \| Basecamp \| Pivotal Tracker |

## 任务路线

> - 基础运维：IT解决
> - 监控运维：外包到机房
> - 系统运维：PXE解决上线问题、Infra接手（例如硬盘满了）
> - 应用运维：Infra主要职责
> - 自动化运维：Infra主要职责
> - 架构师 & CTO

## 上线流程

> 开发：Bug修复、更新数据
>
> 测试：测试用例、性能评测、条件构造
>
> 准备：Review、合并分支、打包
>
> 预上线：配置修复、预发部署、发布验收
>
> 上线：环境准备、上线部署、配置修改、添加监控

## 常用自动化运维工具

Ansible：python，Agentless，适应于几百台

Saltstack：python，agent，专有协议效率高。适用于上千台机器

Puppt：ruby，重型、配置复杂、适合大型环境（tweet、fb使用经验）

# 2. Ansible架构

## Ansible特性

- 模块化
	- Paramiko：Python对SSH的是心啊
	- PyYAML
	- Jinja2：模板生成
- 部署简单、基于python和SSH，agentless，无需代理，不依赖PKI
- 幂等性，执行一遍与多遍，结果相同
- 支持playbook编排任务，多层解决方案Role

## Ansible架构

> Users | CMDB(配置数据库| playbook =》 ansible =》 Hosts \| Networking

- Inventory：Ansible管理主机清单`/etc/ansible/hosts`
- Modules：Ansible执行命令的功能模块，多为内置模块，亦可自定义
- Plugins：模块功能补充，如连接插件，循环插件，变量插件，过滤插件（不常用）
- API：供第三方使用的编程接口

运行Ansible位置一般被称作主控端、中控、master或堡垒机

| Role          | Need                                   |
| ------------- | -------------------------------------- |
| Master Server | Python>2.6                             |
|               | Windows无法作为master server使用       |
| Slave Server  | Python<2.4时需要python-simplejson      |
|               | 开启SELinux时，需要`libselinux-python` |

