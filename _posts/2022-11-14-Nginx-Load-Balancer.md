---
title: Nginx Load Balancer
date: 2022-11-14
excerpt: "Nginx 仲负载均衡相关配置..."
categories: 
    - Web
tags: 
    - Nginx
---



# 0x01 Load Balancer

## [HTTP的负载均衡](https://docs.nginx.com/nginx/admin-guide/load-balancer/http-load-balancer/)

多个应用实例间的负载均衡，通常用于优化资源使用，优化吞吐量，减少时延，和保证容错配置。可以查看[Nginx Plus对于负责均衡和扩容的研讨会](https://www.nginx.com/resources/webinars/nginx-plus-for-load-balancing-30-min/)来进一步加深理解。

### 为服务器集群代理HTTP流量

为了使用NGINX负载均衡HTTP的流量，首先需要在`http`的context中定义一个`upstream`指令，然后物理服务器需要使用`server`指令来定义（和NGINX中定义虚拟服务器的`server`指令是有区别的）。例如下面就定义了一个名为`backend`的服务器集群，并包含3个服务器配置（可能实际节点不只3个）。

```nginx
http {
	upstream backend {
		server backend1.example.com weight=5;
		server backend2.example.com;
		server 192.0.0.1 backup;
	}
}
```

为了定义公共的代理端口，就需要`proxy_pass`中定义对应处理请求的服务器集群。下面就是定义了一个虚拟服务器，从而使NGINX将所有请求转发到`backend`上游集群中

```nginx
server {
	location / {
		proxy_pass hhttp://backend;
	}
}
```

将两段代码结合，就可以定义如何将HTTP请求转发到`backend`服务器集群，这个集群包含3个节点，其中2个运行着相同的程序，最后1个是备份，由于这里没有定义轮询算法，这里将默认使用Round Robin算法来完成负载分流

```nginx
http {
	upstream backend {
		server backend1.example.com weight=5;
		server backend2.example.com;
		server 192.0.0.1 backup;
	}
	server {
		location / {
			proxy_pass http://backend;
		}
	}
}
```

### 定义负载均衡算法

NGINX支持4中负载均衡方法，NGINX Plus支持2中额外的方法

- Round Robin：将请求均等地分发到所有服务器

  ```nginx
  upstream backend {
     # no load balancing method is specified for Round Robin
     server backend1.example.com;
     server backend2.example.com;
  }
  ```

- Last Connections：将请求分发到目前连接数最少的服务器，考虑server weights

  ```nginx
  upstream backend {
      least_conn;
      server backend1.example.com;
      server backend2.example.com;
  }
  ```

- IP Hash：取决于发请求的客户端IP地址，可以使用IPv4的前3个字节地址（24位），或者IPv6的整个地址来计算hash值，如果服务器down了，可以标记为down状态，请求将会自动发往group中下一个服务器

  ```nginx
  upstream backend {
      ip_hash;
      server backend1.example.com;
      server backend2.example.com;
      server backend3.example.com down;
  }
  ```

- Generic Hash：用户定义key，可以是一个文本字符串、变量或连接符，key可能是地址端口对，或者uri，其中`consistent`参数将会开启`ketama`算法来保障hash过程一致性，即在添加或删除服务器时，只有少数几个值将被hash

  ```nginx
  upstream backend {
      hash $request_uri consistent;
      server backend1.example.com;
      server backend2.example.com;
  }
  ```

- Least Time (NGINX Plus)：选择最低平均实验和最少活动连接的服务器，平均时延的计算方式取决于下面三个参数

  - `header` 收到服务器返回的第一个字节的时间
  - `last_byte` 收到完整response的时间
  - `last_byte inflight` 收到完整response的时间，算入未完成的request

  ```nginx
  upstream backend {
      least_time header;
      server backend1.example.com;
      server backend2.example.com;
  }
  ```

- Random，如果定义了`two`参数，NGINX将随机抽取两台服务器，然后按照下述3中方法之一来挑选最优服务器作为服务对象

  - `least_conn`最少活动连接
  - `least_time=header`(NGINX Plus) 收到response header的平均时间
  - `least_time=last_byte`(NGINX Plus) 收到完整response的平均时间

  ```nginx
  upstream backend {
      random two least_time=last_byte;
      server backend1.example.com;
      server backend2.example.com;
      server backend3.example.com;
      server backend4.example.com;
  }
  ```

### Server Weights

所有服务器默认`weight`是 1，假设两台应用服务器，Server A的`weight`为5，Server B的`weight`为1，使用RR均衡方案，则6个请求中，将由Server A处理5个，Server B处理1个

```nginx
upstream backend {
    server backend1.example.com weight=5;
    server backend2.example.com;
    server 192.0.0.1 backup;
}
```

### 慢启动 Server Slow-Start

**Why** 对于刚启动的服务器，如果直接将大量请求打上去，可能会导致服务器重新被标为fail

**How** 在NGINX Plus中，将会让服务器的`weight`从0开始逐渐增长到所设置的正常数值，使用`slow_start`配置即可，具体时间则是上升到正常`weight`所使用的时间。

```nginx
upstream backend {
    server backend1.example.com slow_start=30s;
    server backend2.example.com;
    server 192.0.0.1 backup;
}
```

> p.s. 当Group中只有一台服务器时，`max_fails`,`fail_timeout`,`slow_start`参数就都是无效的，且服务器永远不会被当做不可用。

### 启用会话保持

在NGINX Open Source方案中，需要通过`hash`和`ip_hash`方式来做会话保持，在NGINX Plus中，提供了`sticky`指令来支持下述3种会话保持方法

- `cookie` NGINX Plus为第一个response添加cookie，后续使用相同cookie的，就默认为是同一session的内容

  ```nginx
  upstream backend {
      server backend1.example.com;
      server backend2.example.com;
      sticky cookie srv_id expires=1h domain=.example.com path=/;
  }
  ```

- `route` NGINX Plus为客户端设置一个route配置，route使用cookie或者request URI定义，所有后续接受的请求都会和`route`参数作比较，从而寻找前序回话使用的服务器

  ```nginx
  upstream backend {
      server backend1.example.com route=a;
      server backend2.example.com route=b;
      sticky route $route_cookie $route_uri;
  }
  ```

- `learn` NGINX Plus自动请求和响应中寻找相同的会话标识符，之后NGINX Plus就会自动学习到不同的upstream对应哪个会话标识符，这种`session identifier`通常就是放在cookie里面的，对于已经识别过的会话，NGINX Plus就会自动匹配对应会话

  ```nginx
  upstream backend {
  	server backend1.example.com;
     	server backend2.example.com;
     	sticky learn
     	create=$upstream_cookie_examplecookie
      	lookup=$cookie_examplecookie
         	zone=client_sessions:1m
          timeout=1h;
          sync;
  }
  ```

  > 上游服务器通过在响应中设置cookie `EXAMPLECOOKIE`来创建会话。带有此cookie的其他请求将传递到同一服务器。如果服务器无法处理请求，则选择新服务器，就像尚未绑定客户端一样。
  >
  > 参数`create`和`lookup`指定分别指示如何创建新会话和搜索现有会话的变量。可以多次指定两个参数，在这种情况下，将使用第一个非空变量。会话存储在共享内存区域中，其名称和大小由`zone`参数配置。
  >
  > 一个1 MB的区域可以在64位平台上存储大约4000个会话。在超时参数指定的时间内未访问的会话将从区域中删除。默认情况下，超时设置为10分钟。
  >
  > 对于多个upstream使用同一个cookie空间时，可以设定`zone_sync`来共享命名信息

### 限制连接数

使用`max_conn`参数，如果超过连接数，就会通过`queue`参数加入队列，如果超过时间，客户端就会接到`error`

```nginx
upstream backend {
    server backend1.example.com max_conns=3;
    server backend2.example.com;
    queue 100 timeout=70;
}
```

### 多进程数据共享（Multiple Worker Processes）

如果不在`upstream`中设置`zone`，各个worker进程就会使用独立的服务器group配置，并维护独立的计数器，例如当前服务器的连接数，服务器重连的失败次数。

使用了`zone`之后，上游集群的服务器配置就可以放在一个公共的内存区域中。对于upstream的活动健康检测，动态重新配置功能，必须启用`zone`。对于最小连接数的负载均衡方式，也需要启用`zone`来保证服务器的同步。

> p.s. 在负载较小时，如果没配置`zone`，某个工作进程在将请求发给某个服务器后，可能另一个工作进程也向相同会发送请求，但是当加大载荷和请求数时，由于系统会将请求相对均衡地放在多个工作进程中，最小连接数算法反而可以相对稳定地进行工作。

**sticky_route设置建议** 当存储IP地址和端口对时，一个256KB的zone可以存储如下数目的配置信息：对于IP:port格式，可以存储128台服务器；对于hostname:port格式，且支持每台resolve的配置，可以存储88台；对于上述配置配置，且resolve可以支持多个IP，可以存储12台。

### 使用DNS配置HTTP负载均衡

在上游服务器Group中，如果使用了域名来定义服务器，还可以通过设置`resolver`命令来制定DNS服务器，这样如果DNS有了更新，NGINX Plus将无需重启，自动更新域名对应服务器位置。

```nginx
http {
    resolver 10.0.0.1 valid=300s ipv6=off;
    resolver_timeout 10s;
    server {
        location / {
            proxy_pass http://backend;
        }
    }
    upstream backend {
        zone backend 32k;
        least_conn;
        # ...
        server backend1.example.com resolve;
        server backend2.example.com resolve;
    }
}
```

这里定义的`resolver`制定了要用于解析的DNS服务器，设定之后，NGINX服务器会没过一段时间，就做一次DNS查询，查询服务器中的域名，这里设定的时间间隔是300s，也就是5分钟。另外，这里设定关闭ipv6后，就将只有ipv4用于负载均衡。

## TCP和UDP的负载均衡

## HTTP的健康检测

## TCP的健康检测

## UDP健康检测

## gRPC健康检测

## 使用NGINX Plus API来的动态配置上游流量

## 对PROXY协议的支持