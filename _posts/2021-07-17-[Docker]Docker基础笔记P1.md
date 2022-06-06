---
title: Docker基础笔记-Part1
date: 2021-07-17
excerpt: "[狂神说JAVA系列]中，秦疆关于Docker系列的讲解"
categories:
    - Notes
tags:
    - Docker
---



# Docker基础知识-Part1

**Docker的历史**

- 2013.05.30 Docker.io正式提交GitHub，Docker开源
- 2014.04.09 Docker 1.0正式发布

**Docker与VMware**

之前的虚拟技术：虚拟机VMware，OpenStack，以linux CentOS镜像为例

|        | 占用空间 | 启动时间 |
| ------ | -------- | -------- |
| VMware | GB级     | 分钟级   |
| Docker | MB级     | 秒级     |

- Docker有着比虚拟机更少的抽象层，由于Docker不需要Hypervisor实现硬件资源虚拟化，运行在Docker容器上的程序直接使用的都是实际物理机的硬件资源，因此在Cpu、内存利用率上Docker将会在效率上有明显优势。
- Docker利用的是宿主机的内核，而不需要Guest OS，因此，当新建一个容器时，Docker不需要和虚拟机一样重新加载一个操作系统，避免了引导、加载操作系统内核这个比较费时费资源的过程，当新建一个虚拟机时，虚拟机软件需要加载Guest OS，这个新建过程是分钟级别的，而Docker由于直接利用宿主机的操作系统则省略了这个过程，因此新建一个Docker容器只需要几秒钟。

|            | Docker容器              | VM虚拟机                    |
| ---------- | ----------------------- | --------------------------- |
| 操作系统   | 与宿主机共享OS          | 宿主机OS上运行宿主机OS      |
| 存储大小   | 镜像小，便于存储与传输  | 镜像庞大（vmdk等）          |
| 运行性能   | 几乎无额外性能损失      | 操作系统额外的cpu、内存消耗 |
| 移植性     | 轻便、灵活、适用于Linux | 笨重、与虚拟化技术耦合度高  |
| 硬件亲和性 | 面向软件开发者          | 面向硬件运维者              |

![](\images\docker1-4.png)

**Docker基于Go语言开发**

- Docker官网 https://www.docker.com/
- Docker文档 https://docs.docker.com/
- Docker Hub https://hub.docker.com/

**系统组成**

- Image：模板，通过模板启动容器
- Container：启动、停止、删除、基本命令
- Repository：存放Image的仓库，阿里云、网易云、华为云都会开放服务，默认国外

![](\images\docker1-1.png)

# 安装Docker

[官方安装文档](https://docs.docker.com/engine/install/centos/) To install Docker Engine, you need a maintained version of CentOS 7 or 8. Archived versions aren’t supported or tested.

1. 删除已有的软件

    ```
    yum remove docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-engine
    ```

2. 需要的安装包

    Install the `yum-utils` package (which provides the `yum-config-manager` utility) and set up the **stable** repository.

    ```shell
    yum install -y yum-utils
    ```

3. 设置镜像仓库，国内镜像方法参见（https://www.cnblogs.com/hui-shao/p/docker-ali.html）

    ```shell
    # 官方仓库
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    # 国内（阿里云）仓库
    yum-config-manager --add-repo \
        http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    # 更新软件包索引
    yum makecache fast
    ```
    
    > To install a *specific version* of Docker Engine, list the available versions in the repo, then select and install
    
    ```shell
    yum list docker-ce --showduplicates | sort -r
    yum install docker-ce-<VERSION_STRING> docker-ce-cli-<VERSION_STRING> containerd.io
    systemctl start docker
    ```
    
4. 安装docker

    ```shell
    yum install -y docker-ce docker-ce-cli containerd.io
    ```

5. 启动docker

  ```shell
  systemctl start docker
  docker version
  ```

  Docker版本信息

  ![](\images\docker1-2.png)

6. 测试`hello-world`

  ```shell
  docker run hello-world    # 下载并启动hello-world
  docker images    # 查看docker 镜像
  ```

  对于没有的新镜像需要先下载，默认下载latest版本

  ![](\images\docker1-3.png)

7. *卸载docker

    `/var/lib/docker`是docker的默认工作路径

    ```shell
    yum remove docker-ce docker-ce-cli containerd.io
    rm -rf /var/lib/docker
    ```

# 配置阿里云镜像加速

官方文档（https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors）

配置 `/etc/docker/daemon.json`文件

```shell
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://rcjneej2.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker
```

# Docker工作原理

Docker是CS结构的系统，Docker服务以守护进程形式一直运行在主机端，DockerServer接到Docker-Client指令，就会在系统内执行。

# Docker常用命令

关于Commandline的官方文档可以查看[Docker Reference](https://docs.docker.com/engine/reference/commandline/)

## 帮助命令

```shell
docker version
docker info
docker [command] -help
```

## 镜像命令

Docker Image Reference: **[[Image Command Document](https://docs.docker.com/engine/reference/commandline/images/)]**

## 查看镜像命令

```shell
docker images
# -a\--all 列出所有镜像
# -q\--quiet 只显示镜像id
```

## IMAGE命令结果内容分析

![](\images\docker1-6.png)

| NAME       | DESCRIPTION  |
| ---------- | ------------ |
| REPOSITORY | 镜像仓库源   |
| TAG        | 镜像标签     |
| IMAGE ID   | 镜像ID       |
| CREATED    | 镜像创建时间 |
| SIZE       | 镜像大小     |

## 搜索\拉取镜像命令

```shell
docker search [OPTIONS] TERM
docker search --filter=STARS=3000 mysql    # 搜索大于3000 stars的镜像

docker pull [OPTIONS] NAME[:TAG|@DIGEST]
docker pull ubuntu:14.04
docker pull ubuntu\
    @sha256:45b23dee08af5e43a7fea6c4cf9c25ccf269ee113168c19722f87876677c5cb2
```

## PULL命令结果内容分析

![](\images\docker1-5.PNG)

- 默认使用latest版本
- 后面的一系列Pull complete使用了分层下载概念，多个镜像之间的层可以共用

## 删除镜像命令

```shell
# docker rmi [OPTIONS] IMAGE [IMAGE...]
docker rmi -f 5c62e459e087    # 删除指定镜像
docker rmi \    # 通过限制容器版本、digest来删除容器
    localhost:5000/test/busybox\
    @sha256:cbbf2f9a99b47fc460d422812b6a5adff7dfee951d8fa2e4a98caa0382cfbdbf
docker rmi -f $(docker images -aq)    # 删除所有镜像
```

## 容器命令

容器运行命令`docker run `，对应[Docker Run Reference](https://docs.docker.com/engine/reference/commandline/run/)

```shell
# 以centos为例
docker pull centos
```

## 运行容器

```shell
# 运行容器: docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
    # --name="Name" 为容器设置名字Name
    # -d 后台运行
    # -it 用terminal方式进入容器交互运行
    # -p 指定端口映射
    # -P 随机指定端口
docker run -it centos /bin/bash
```

## 退出容器

- 使用`exit`命令退出容器，退出后容器停止
-  `Ctrl+P+Q`容器不停止，退出

## 查看容器

```shell
# 列出所有容器: docker ps [OPTIONS]
# -a/--all     Show all containers (default shows just running)
# -q/--quiet Only display container IDs
docker ps
```

## 删除容器

默认无法删除正在运行的容器

```shell
# 删除容器: docker rm [OPTIONS] CONTAINER [CONTAINER...]
docker rm 
docker rm -f $(docker ps -aq)
docker ps -a -q|xargs docker rm
```

## 启动、停止、重启容器

```shell
docker start [container_id]
docker stop [container_id]
docker restart [container_id]
docker kill [container_id]    # 强制停止一个容器
```

## 常用其他命令

docker使用后台运行，必须要有一个前台进程，如果docker启动后发现没有前台进程，就会默认自动停止进程。

```shell
docker run -d centos
docker ps    # 此时没有任何容器在运行
```

## 查看容器日志

```shell
# 查看容器日志:docker logs [OPTIONS] CONTAINER
    # -f Follow log output
    # -t/--timestamps Show timestamps 
    # --tail Number of lines to show from the end of the logs

# centos默认没有日志输出，使用如下脚本使容器输出日志
# "while true; do echo Hello_World;sleep 1;done"
docker run -d centos /bin/sh -C "while true; do echo Hello_World;sleep 1;done"
docer ps
docker logs -tf --tail 10 $INSTANCE_ID
```

## 查看容器进程

```shell
# 查看容器进程:docker top CONTAINER [ps OPTIONS]
docker top $INSTANCE_ID

# 查看容器底层信息:docker inspect [OPTIONS] NAME|ID [NAME|ID...]
docker inspect $INSTANCE_ID
docker inspect --format=\    # 查看容器IP
    '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
    $INSTANCE_ID
```

> By default, `docker inspect` will render results in a JSON array. For example uses of this command, refer to the [examples section](https://docs.docker.com/engine/reference/commandline/inspect/#examples) below.

## 进入容器命令

进入容器的常用方式，可以参考[Docker容器进入的4种方式](https://www.cnblogs.com/xhyan/p/6593075.html)

- 使用docker attach
- 使用SSH
- 使用nsenter
- 使用exec

```shell
# 进入容器后开启新的终端，可以直接操作
docker exec -it $INSTANCE_ID /bin/bash
# 正在执行当前的代码
docker attach -it $INSTANCE_ID
# 从容器内拷贝文件到主机(非运行状态也不影响)
docker cp $INSTANCE_ID:/test.java ./
```

## 命令小结

![](\images\docker1-7.png)

```shell
attach      Attach to a running container            # 当前shell下attach连接指定运行镜像
build       Build an image from a Dockerfile         # 通过Dockerfile定制镜像
commit      Create a new image from a container changes   #提交当前容器为新镜像
cp          Copy files/folders from the containers filesystem to the host path   # 从容器中拷贝指定文件或者目录到宿主机中
create      Create a new container                   # 创建一个新的容器，同run，但不启动容器
diff        Inspect changes on a container‘s filesystem   # 查看docker容器变化
events      Get real time events from the server     # 从docker服务获取容器实时事件
exec        Run a command in an existing container   # 在已存在的容器上运行命令
export      Stream the contents of a container as a tar archive  # 导出容器的内容流作为一个tar归档文件[对应import]
history     Show the history of an image             # 展示一个镜像形成历史
images      List images                              # 列出系统当前镜像
import      Create a new filesystem image from the contents of a tarball # 从tar包中的内容创建一个新的文件系统映像[对应export]
info        Display system-wide information          # 显示系统相关信息
inspect     Return low-level information on a container   # 查看容器详细信息
kill        Kill a running container                 # kill指定docker容器
load        Load an image from a tar archive         # 从一个tar包中加载一个镜像[对应save]
login       Register or Login to the docker registry server  # 注册或者登陆一个docker源服务器
logout      Log out from a Docker registry server    # 从当前Docker registry 退出
logs        Fetch the logs of a container             # 输出当前容器日志信息
port        Lookup the public-facting port which is NAT-ed to PRIVATE_PORT   # 查看映射端口对应的容器内部源端口
pause       Pause all processes within a container   # 暂停容器
ps          List containers                          # 列出容器列表
pull        Pull an image or a repository from the docker registry server   # 从docker镜像源服务器拉取指定镜像或者库镜像
push        Push an image or a repository to the docker registry server   # 推送指定镜像或者库镜像至docker源服务器
restart     Restart a running container              # 重启运行的容器
rm          Remove one or more containers            # 移除一个或者多个容器
rmi         Remove one or more images                # 移除一个或者多个镜像[无容器使用该镜像才可删除，否则需删除相关容器才可以继续或 -f 强制删除]
run         Run a command in a new container         # 创建一个新的容器并运行一个命令
save        Save an image to a tar archive           # 保存一个镜像为一个tar包[对应load]
search      Search for an image on the Docker Hub    # 在docker hub 中搜索镜像
start       Start a stopped containers               # 启动容器
stop        Stop a running containers                # 停止容器
tag         Tag an image into a repository           # 给源中镜像大标签
top         Lookup the running processes of a container   # 查看容器中运行的进程信息
unpause     Unpause a paused container               # 取消暂停容器
versiohn    Show the docker version information      # 查看docker版本号
wait        Blocke until a container stops, then print its exit code # 截取容器停止时的退出状态值
```

# 任务1 Nginx安装

```shell
# 下载镜像
docker pull nginx
# 运行容器
# -p: 3344是服务器端口，80是容器端口
docker run -d --name nginx01 -p 3344:80 nginx
# 查看容器
docker ps
# 访问容器
curl localhost:3344
docker exec -it nginx01 /bin/bash
# 以下为容器内执行的命令 
cd /etc/nginx
```

此时如果需要修改`nginx.conf`，此时就会发现没有`vim`/`vi`工具，除去用yum在docker内部下载工具，可以通过目录映射来在宿主机上修改。参见[Docker使用 | 修改Docker容器内文件](https://www.cnblogs.com/-saber/p/14667070.html)。

```shell
docker run -itd -p 8080:80 -v \
    /etc/nginx/nginx.conf:/etc/nginx/nginx.conf \
    --name=webtest nginx:latest
```

# 任务2 Tomcat安装

[Tomcat Docker Hub](https://hub.docker.com/_/tomcat)

```shell
# 官方的使用
docker run -it --rm tomcat:9.0    # 用完就删
docker ps -a    # 此时无法看到在运行的tomcat容器
# 建议使用的办法
docker run -d -p 3355:8080 --name tomcat01 tomcat
```

此时已经可以通过3355端口访问Tomcat，但是会显示404页面，因为官方只提供了最基础的版本，webapps目录为空。

```shell
docker exec -it tomcat01 /bin/bash    # 进入容器
cd /usr/local/tomcat/webapps    # 目录为空
cd /usr/local/tomcat/webapps.dist    # 目录是正常的
cp -r webapps.dist/* webapps/    # 将必要文件拷贝进入webapps
```

此时访问3355端口，就可以看到正常的Tomcat页面。

# 任务3 ES & Kibana安装

[ES Docker Hub](https://hub.docker.com/_/elasticsearch) & [Kibana Docker Hub](https://hub.docker.com/_/kibana)

```shell
# 官方配置
docker network create somenetwork
docker run -d --name elasticsearch \
    --net somenetwork -p 9200:9200 -p 9300:9300 \
    -e "discovery.type=single-node" elasticsearch:tag
# 暂时不配置网络
docker run -d --name elasticsearch \
    -p 9200:9200 -p 9300:9300 \
    -e "discovery.type=single-node" elasticsearch:7.6.2
```

## 解决ES的内存问题

```shell
# 查看CPU状态
docker stats
docker run -d --name elasticsearch -p 9200:9200 -p 9300:9300 \
    -e "discovery.type=single-node" \
    -e ES_JAVA_OPTS="-Xms64m -Xms512m" elasticsearch:7.6.2 
curl localhost:9200
```

```json
{
  "name" : "ac181acd9ee2",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "-gBDxsJaTx2XKqeGb5JS2g",
  "version" : {
    "number" : "7.6.2",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "ef48eb35cf30adf4db14086e8aabd07ef6fb113f",
    "build_date" : "2020-03-26T06:34:37.794943Z",
    "build_snapshot" : false,
    "lucene_version" : "8.4.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```

## 【TBC】解决Kibana和ES联通的网络问题

# Docker可视化

## 【TBC】portainer是什么

**[[Offical Document](https://www.portainer.io/)]** Portainer is a universal container management tool that helps users deploy and manage container-based applications without needing to know how to write any platform-specific code.

```shell
docker run -d -p 8088:9000 \
    --restart=always -v /var/run/docker.sock:/var/run/docker.sock \
    --privileged=true portainer/portainer
```

此时，可以通过8088端口页面访问portainer后端。

## 【TBC】Rancher（CI/CD使用）

# Docker镜像原理

## 镜像获取来源

- 下载镜像
- 直接拷贝
- 自行制作

## 【TBC】联合文件系统 UnionFS

> **Union文件系统**（UnionFS）是一种分层、轻量级并且高性能的文件系统，它支持对文件系统的修改作为一次提交来一层层的叠加，同时可以将不同目录挂载到同一个虚拟文件系统下(unite several directories into a single virtual filesystem)。Union 文件系统是 Docker 镜像的基础。镜像可以通过分层来进行继承，基于基础镜像（没有父镜像），可以制作各种具体的应用镜像。

> **特性**：一次同时加载多个文件系统，但从外面看起来，只能看到一个文件系统，联合加载会把各层文件系统叠加起来，这样最终的文件系统会包含所有底层的文件和目录

[参考目录](https://www.cnblogs.com/ilinuxer/p/6188654.html)

[参考文档2](https://www.cnblogs.com/ilinuxer/p/6188654.html)

## 【TBC】Docker镜像加载原理

docker的镜像实际上由一层一层的文件系统组成，这种层级的文件系统UnionFS。

- bootfs(boot file system)主要包含bootloader和kernel, bootloader主要是引导加载kernel, Linux刚启动时会加载bootfs文件系统，在Docker镜像的最底层是bootfs。这一层与我们典型的Linux/Unix系统是一样的，包含boot加载器和内核。当boot加载完成之后整个内核就都在内存中了，此时内存的使用权已由bootfs转交给内核，此时系统也会卸载bootfs。

- rootfs (root file system) ，在bootfs之上。包含的就是典型 Linux 系统中的 /dev, /proc, /bin, /etc 等标准目录和文件。rootfs就是各种不同的操作系统发行版，比如Ubuntu，Centos等等。

> 平时我们安装进虚拟机的CentOS都是好几个G，为什么docker这里才200M？？
>
> 对于一个精简的OS，rootfs可以很小，只需要包括最基本的命令、工具和程序库就可以了，因为底层直接用Host的kernel，自己只需要提供 rootfs 就行了。由此可见对于不同的linux发行版, bootfs基本是一致的, rootfs会有差别, 因此不同的发行版可以公用bootfs。 虚拟机是分钟级，容器是秒级。

## 【TBC】分层理解

![](\images\docker1-8.png)

```shell
# 查看镜像分层情况
docker image inspect $image_id:$tag
```

