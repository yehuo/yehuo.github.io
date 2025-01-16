---
title: Docker Desktop Issue on Windows
date: 2021-06-28
excerpt: "关于Windows下Docker Desktop后台运行出错的一点经验积累"
categories:
    - Virtualization
tags:
    - Docker
---



### 出错现象

打开软件时报错弹窗，运行命令时报错反馈

> error during connect: Get http://%2F%2F.%2Fpipe%2Fdocker_engine/v1.25/version: open //./pipe/docker_engine: The system cannot find the file
> specified. In the default daemon configuration on Windows, the docker client must be run elevated to connect. This error may also indicate that the docker daemon is not running.

### 官方文档

In the default daemon configuration on Windows, the docker client must be run elevated to connect

### 解决方案

You can do this in order to switch Docker daemon, as elevated user:

***With Powershell***:

1. Open Powershell *as administrator*
2. Launch command: `& 'C:\Program Files\Docker\Docker\DockerCli.exe' -SwitchDaemon`

***OR, with cmd***:

1. Open cmd *as administrator*
2. Launch command: `"C:\Program Files\Docker\Docker\DockerCli.exe" -SwitchDaemon`