---
title: "计算机网络基础"
date: 2025-06-17
categories:
  - Network
tags:
  - Basic
excerpt: "一些常见的计算机网络面试问题"
---



# 计算机网络基础

## 网络基础

- TCP 三次握手与四次挥手
- TCP vs UDP 特点和适用场景
- MTU, MSS, Window Scaling, Nagle's algorithm
- DNS 原理，递归 vs 迭代查询
- ARP, DHCP, NAT, VLAN, 子网划分

## 网络性能与调优

- Linux 下如何查看网络连接和延迟（如 `ss`, `netstat`, `ping`, `traceroute`, `iperf`, `tcpdump`）
- 如何排查高 RTT、丢包、网络拥塞
- TCP 拥塞控制四阶段（慢启动、拥塞避免、快重传、快恢复）

## 高频下的网络优化思路

- busy-polling、DPDK 简介
- 网络延迟的精细拆解（用户空间 → 内核 → 网卡 → 光纤延迟）