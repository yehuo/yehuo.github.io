---
title: Nginx Basic Function
date: 2022-11-10
excerpt: "Nginx的启动及信号格式..."
categories: 
    - Web
tags: 
    - Nginx
---



# Basic Functionality

## 运行时的Nginx进程控制

### NGINX在运行时的调整

Nginx有一个主进程和一个或多个工作进程，如果启用了caching，cache的loader和manager进程也会启动。主进程的主要目标是用于读取和执行配置文件，以及保持工作进程的正常运行。

工作进程是实际去处理请求，具体请求如何调用工作进程，是Nginx基于操作系统实现的。工作进程的数目是在`nginx.conf`中设计的，可以设定以为一个固定数字或根据CPU核数动态调整。

### 控制Nginx

为了重载nginx的新配置，一般需要关闭或重启Nginx，或者通过向主进程发送信号的模式来实现。向Nginx发送信号可以使用`-s`命令

```shell
nginx -s <SIGNAL>
```

signal主要包括下述4种：

- `quit` Gracful shutdown的关闭方式，发出`SIGQUIT`信号
- `reload` 重载配置文件，发出`SIGHUP`信号
- `reopen` 重新打开log文件，发送`SIGUSR1`信号
- `stop` 立即关闭，发送`SIGTERM`信号

Linux的`kill`命令也可以用于向主进程发送一个信号，主进程的pid号通常记录在nging.pid文件中，相应文件通常放在`/usr/local/nginx/logs`或`/var/run`目录下

## 创建Nginx Plus和Nginx的配置文件

Nginx的配置文件，主要是由一些指令和上下文元素组成的。Nginx的配置文件一般放置于`/etc/nginx/nginx.conf`目录下。对于开源版本Nginx，具体位置就取决于安装器，通常位于下面三个位置

- `/usr/local/nging/conf`
- `/etc/nginx`
- `/usr/local/etc/nginx`

### 指令模块

配置文件中会包含一些指令模块，通常附带参数，单行指令需要分号结尾，其他指令需要使用花括号包裹，也被叫做指令块。

```nginx
user				nobody;
error_log			logs/error.log notice;
worker_processes	1;
```

### 按功能区分的配置文件

为了方便维护，Nginx的指令配置支持模块化调用，可以将同一功能相关的配置放到一个文件中，并在主配置文件中通过`include`调用，单独的配置文件可以放到`/etc/nginx/conf.d`下。

```nginx
include conf.d/http;
include conf.d/steam;
include conf.d/exchage-enhanced;
```

### 上下文模块 Contexts

Context是一些高级指令，通常组合起来使用，以定义不同的流量类型，例如

- `events` 通用的连接进程
- `http` HTTP流量
- `mail` Mail流量
- `stream` TCP和UDP流量

在上述这些Context以外配置的指令，属于`main context`

### 虚拟服务器 Virtual Servers

在每个流量处理的上下文中，都需要有一个或多个`server`块，来定义虚拟服务器，从而定义如何处理请求。具体`server`中可以定义的指令，则根据所属Context而各有不同。对于HTTP流量，每个`server`可以用于处理访问指定domain或者IP的请求。对于Mail和Stream流量，每个`server`可以用于处理对于特定TCP端口的请求或或来源于特定UNIX套接字的访问。

```nginx
user	nobody;
events: { ... } # 配置链接流程
http {
	server { 	# 配置http虚拟服务器1
		location /one { ... } # 配置处理访问/one的URI
		location /two { ... } # 配置处理访问/two的URI
	}
	server { ... }	# 配置http虚拟服务器2
}
stream {
	server { ... }	# 配置TCP虚拟服务器1
}
```

**指令继承问题**，一些子上下文，就是被套用在另一些上下文配置中的指令，是可以继承父级上下文中的一些配置。一些指令可以同时出现在多个级别的上下文中，例如`proxy_set_header`指令，就可以在子context中重置父context中的`header`内容。

### 重载Configuration

为了使配置文件生效，你需要restart nginx进程或使用reload信号来升级配置。使用reload方式，可以不终端对于当前请求的处理。在NGINX Plus中，还可以动态配置load balancing，而无需reload配置。还可以使用NGINX Plus API和kv存储来动态控制访问， 例如[动态配置IP地址denylist](https://docs.nginx.com/nginx/admin-guide/security-controls/denylisting-ip-addresses/)。