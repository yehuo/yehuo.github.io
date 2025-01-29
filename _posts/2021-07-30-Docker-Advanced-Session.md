---
title: Docker Advanced Session
date: 2021-07-30
excerpt: "[狂神说JAVA系列]中，秦疆关于Docker系列的进阶课程"
categories:
    - Notes
tags: 
    - Docker
---



# [Docker Compose](https://docs.docker.com/compose/)

## Compose介绍

Docker Compose运行步骤

> Using Compose is basically a three-step process:
>
> 1. Define your app’s environment with a `Dockerfile` so it can be reproduced anywhere.
> 2. Define the services that make up your app in `docker-compose.yml` so they can be run together in an isolated environment.
> 3. Run `docker compose up` and the [Docker compose command](https://docs.docker.com/compose/cli-command/) starts and runs your entire app. You can alternatively run `docker-compose up` using the docker-compose binary.

Compose是Docker官方的开源项目，所以需要安装。Compose要运行的不是一个Services，而是包含多个Services的一个Project。

```yaml
version: "3.9" # optional since v1.27.0
services:
    web:
        build: .
        ports:
            - "5000:5000"
        volumes:
            - .:/code
            - logvolume01:/var/log
        links:
            - redis
    redis:
        image: redis
volumes:
    logvolume01: {}
```

## 安装Compose

```shell
# 官方获取Compose安装地址
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# 推荐下载方式
curl -L https://get.daocloud.io/docker/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m) > /usr/local/bin/docker-compose

# 配置可执行权限
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version

# 配置软链接
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

## 运行[Compose Quickstart](https://docs.docker.com/compose/gettingstarted/)

### **部署过程**

1. 应用app.py

2. Dockerfile将应用打包为镜像

3. Docker-compose yaml文件

	定义整个服务，需要环境、web、redis，完整的上线服务

4. 启动Compose项目（docker-compose up）

### **Compose任务流程**

1. 创建网络
2. 执行Docker-compose yaml
3. 启动服务

### Compose默认规则

> `docker ps`中看到两个容器`web_1`、`redis_1`的命名来源

默认文件名：文件名\_服务器\_副本id

> `docker images`中看到所有容器的自动下载规则

> `docker service ls`的报错问题

> 关于Compose创建的Docker网络规则

`docker network ls`中可以看到一个新增网络`composetest_default`，通过docker network inspect 

docker swarm

docker stack

docker secret

docker config