---
title: "DDIA Chapter 05 Replication"
date: 2025-01-28
categories:
  - Architect Desgin
tags:
  - DDIA
excerpt: The blog excerpt discusses the evolution of data models, comparing relational and document models, highlighting the limitations of each, and exploring the rise of NoSQL and graph data models for handling complex relationships like many-to-many.
---



**Why you want to replicate data?**

- 保持数据在地理上更接近用户来降低延迟
- 使系统在一部分节点崩溃时，依然可以继续使用，提高系统可用性
- 增加可以用于读操作的节点，提高数据吞吐量

**Three popular algorithms for replicating changes between nodes**

- single leader
- multi-leader
- leaderless

# Leaders and Followers

## Synchronous vs Asynchronous

`innobackupex` MySQL设置快照工具

`binlog coordinates` snapshot在MySQL日志中的位置

## Implementation of Replication Logs

- Statement-based replication
- Write-ahead log(WAL) skipping
- Logical(row-based) log replication
- Trigger-based replication

## Problems with Replication Lag

因为同步延迟造成的数据不一致性，往往会因为集群规模的扩大而愈发凸显（集群越大，网络情况也越发复杂）。