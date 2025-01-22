---
title: Graceful Shutdonw of Pod in Kubernetes
date: 2025-01-07
excerpt: "如何在kubernetes中完成pod的优雅关闭"
categories: 
    - Kubernetes
tags: 
    - Pod
    - System
---

Pod优雅关闭是指当Pod因为某种原因（如版本更新、资源不足、故障等）被终止时，Kubernetes不会立即强制关闭Pod，而是首先尝试不影响当前连接的方式关闭Pod。这个过程允许Pod中的容器有足够的时间来响应终止信号`SIGTERM`，并在终止前完成必要的清理工作，如保存数据、关闭连接等。


Pod优雅关闭是指在Kubernetes中，当Pod因为某种原因（如版本更新、资源不足、故障等）需要被终止时，Kubernetes不会立即强制关闭Pod，而是首先尝试以一种“优雅”的方式关闭Pod。这个过程允许Pod中的容器有足够的时间来响应终止信号（默认为SIGTERM），并在终止前完成必要的清理工作，如保存数据、关闭连接等。

