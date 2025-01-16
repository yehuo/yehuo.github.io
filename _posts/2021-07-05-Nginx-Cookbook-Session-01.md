---
title: Nginx Cookbook Session 01
date: 2021-07-05
excerpt: "通过 Nginx 服务可以构建四层/七层负载均衡，并通过HTTP协议与TCP协议来支持Session保持，健康状态检测"
categories:
    - Network
tags:
    - Nginx
---



# 0x01 高性能负载均衡High-Performance Load Balancing

## 1. HTTP负载均衡

```
upstream backend { 
	server 10.10.12.45:80 weight=1; 
	server app.example.com:80 weight=2;
} 
server { 
	location / { 
	proxy_pass http://backend;
	} 
}
```

HTTP 模块的 upstream 用于设置被代理的 HTTP 服务器实现负载均衡。模块 内定义一个目标服务器连接池，它可以是 **UNIX 套接字、IP 地址、DNS 记录 或它们的混合使用配置**；此外 upstream 还可以通过 weight 参数配置，如何 分发请求到应用服务器。 所有 HTTP 服务器在 upstream 块级指令中由 server 指令配置完成。server 指令接收 UNIX 套接字、IP 地址或 FQDN(Fully Qualified Domain Name: 全限 定域名) 及一些可选参数。

可选参数能够精细化控制请求分发。它们包括用于负 载均衡算法的 `weight` 参数；判断目标服务器是否可用，及如何判断服务器可用 性的 `max_fails` 指令和 `fail_timeout` 指令。NGINX Plus 版本提供了许多其他 方便的参数，比如**服务器的连接限制、高级DNS解析控制，以及在服务器启动后 缓慢地连接到服务器的能力**。

## 2. TCP 负载均衡

```nginx
stream { 
    upstream mysql_read { 
        server read1.example.com:3306 weight=5; 
        server read2.example.com:3306; 
        server 10.10.12.34:3306 backup;
    } 
    server { 
        listen 3306; 
        proxy_pass mysql_read;
    } 
}
```

- backup服务器仅在访问失败时访问

TCP 负载均衡在 stream 模块中配置实现。stream 模块类似于 http 模块。 配置时需要在 server 块中使用 listen 指令配置待监听端口或 IP 加端口。 接着，需要明确配置目标服务，目标服务可以使代理服务或 upstream 指令 所配置的连接池。 TCP 负载均衡实现中的 upstream 指令配置和 HTTP 负载 均衡实现中的 upstream 指令配置相似。TCP 服务器在 server 指令中配置， 格式同样为 **UNIX 套接字、IP地址或 FQDN(Fully Qualified Domain Name: 全限定域名)**；用于精细化控制的 weight 权重参数、最大连接数、DNS 解析器、判断服务是否可用和启用为备选服务的 backup 参数一样能在 TCP 负载均衡中使用。

## 3. 负载均衡算法

## 轮询Round Robin

权重算法的核心技术是，依据**访问权重求均值**进行概率统计。轮询作为默认的负载均衡算法，将在没有指定明确的负载均衡指令的情况下启用。

## 最少连接数Least Connections

```nginx
upstream backend { 
    least_conn; 
    server backend.example.com; 
    server backend1.example.com;
}
```

## 最短响应时间 Least Time

是对最少连接数负载均衡算法的优化实现，因为最少的访问连接并非意味着 更快的响应。该指令的配置名称是 `least_time`。

## 通用散列算法 Generic Hash

服务器管理员依据请求或运行时提供的**文本、变量或文本和变量的组合**来生成散列值。通过生成的散列值决定使用哪一台被代理的应用服务器，并 将请求分发给它。

在需要对访问请求进行**负载可控**，或将访问请求负载到 已经有数据缓存的应用服务器的业务场景下，该算法会非常有用。需要注意 的是，**在 upstream 中有应用服务器被加入或删除时，会重新计算散列进行 分发，**因而，该指令提供了一个可选的参数选项来保持散列一致性，减少 因应用服务器变更带来的负载压力。该指令的配置名称是 `hash`。

## IP散列算法 IP Hash

这对需要存储使用会话， 而又没有使用共享内存存储会话的应用服务来说，能够保证同一个客户端 请求，在应用服务可用的情况下，永远被负载到同一台应用服务器上。 该指令同样提供了权重参数选项。该指令的配置名称是 `ip_hash`。

# 0x03 会话保持（Intelligent Session Persistence）

在真实的服务里，应用会有会话状态变量被存储在本地。例如，在应用程序中，要处理的数据非常大，网络开销在性能上非常昂贵。NGINX通过三种方式跟踪会话持久性：

  - 通过创建和跟踪自己的cookie
  - 检测应用程序何时指定cookie
  - 基于运行时变量路由

## 1.Sticky Cookie

### 工作原理

Sticky是Nginx的一个模块，它是基于cookie的一种Nginx的负载均衡解决方案，通过分发和识别cookie，来使同一个客户端的请求落在同一台服务器上，默认标识名为route

1. 客户端首次发起访问请求，Nginx接收后，发现请求头没有cookie，则以轮询方式将请求分发给后端服务器。
2. 后端服务器处理完请求，将响应数据返回给Nginx。
3. 此时Nginx生成带route的cookie，返回给客户端。route的值与后端服务器对应，可能是明文，也可能是md5、sha1等Hash值
4. 客户端接收请求，并保存带route的cookie。
5. 当客户端下一次发送请求时，会带上route，Nginx根据接收到的cookie中的route值，转发给对应的后端服务器。

### 模块内容

参考解释资料：[nginx会话保持之sticky模块](https://www.cnblogs.com/tssc/p/7481885.html)

| 属性                    | 功能                                                         |
| ----------------------- | ------------------------------------------------------------ |
| [name=route]            | 设置用来记录会话的cookie名称                                 |
| [domain=.foo.bar]       | 设置cookie作用的域名                                         |
| [path=/]                | 设置cookie作用的URL路径，默认根目录                          |
| [expires=1h]            | 设置cookie的生存期，默认不设置，浏览器关闭即失效，需要是大于1秒的值 |
| [hash=index\|md5\|sha1] | 设置cookie中服务器的标识是用明文还是使用md5值，默认使用md5   |
| [no_fallback]           | 设置该项，当sticky的后端机器挂了以后，Nginx返回502，而不转发到其他服务器，不建议设置 |
| [secure]                | 设置启用安全的cookie，需要HTTPS支持                          |
| [httponly]              | 允许cookie不通过JS泄漏，没用过                               |

### 模块样本

```nginx
upstream backend {
    server backend1.example.com;
    server backend2.example.com;
    sticky cookie
        affinity
        expires=1h
        domain=.example.com
        httponly
        secure
        path=/;
}
```

The cookie in this example is named affinity , is set for example.com, persists an hour, cannot be consumed client-side, can only be sent over HTTPS, and is valid for all paths.

## 2. Sticky Learn

如何将downstream的客户端和upstream的服务器通过一个cookie连接，Nginx可以通过sticky learn来自动发现、追踪被upstream创建的cookie名字

```nginx
upstream backend {
    server backend1.example.com:8080;
    server backend2.example.com:8081;
    sticky learn
        create=$upstream_cookie_cookiename
        lookup=$cookie_cookiename
        zone=client_sessions:2m;
}
```

这个例子指示NGINX通过在响应头中查找名为COOKIENAME的cookie来查找和跟踪会话，并通过在请求头中查找相同的cookie来查找已存在的会话。这个会话关联存储在一个 2MB 的共享内存域中，可以跟踪大约16,000个会话。

## 3. Sticky Routing

如果需要颗粒化控制把持久session匹配到upstream的服务器，使用可以将sticky和route同时使用

```nginx
map $cookie_jsessionid $route_cookie {
    ~.+\.(?P<route>\w+)$ $route;
}
map $request_uri $route_uri {
    ~jsessionid=.+\.(?P<route>\w+)$ $route;
}

upstream backend {
    server backend1.example.com route=a;
    server backend2.example.com route=b;
    sticky route $route_cookie $route_uri;
}
```

The example attempts to extract a Java session ID, first from a cookie by mapping the value of the Java session ID cookie to a vari‐
able with the first map block, and second by looking into the request URI for a parameter called jsessionid , mapping the value to a variable using the second map block. 

The sticky directive with the route parameter is passed any number of variables. The first non zero or nonempty value is used for the route. If a jsessionid cookie is used, the request is routed to `backend1` ; if a URI parameter is used, the request is routed to `backend2`.

## 4. Connection Draining

如果需要在移出某个节点前关闭连接，可以通过如下命令进行

```shell
curl 'http://localhost/upstream_conf?upstream=backend&id=1&drain=1'
```

- Draining connections is the process of letting sessions to that server expire natively before removing the server from the upstream pool.
- Draining can be configured for a particular server by adding the drain parameter to the server directive.
- When the drain parameter is set, NGINX Plus will stop sending new sessions to this server but will allow current sessions to continue being served for the length of their session.

# 0x03 Health Checks

TCP 服务的 Health Checks 可以参考 NGINX 服务器官网的教程 [TCP Health Checks Guide](https://docs.nginx.com/nginx/admin-guide/load-balancer/tcp-health-check/)。

## 1. HTTP 状态码检测

负载均衡器可以通过获取被负载服务器的响应状态码是否为 200 判断应用服务器进程是否正常。

## 2. 慢连接 Slow Start

刚刚上线的服务器往往可能会被负载瞬间压垮，Nginx提供一种慢连接方式，让服务器weight值可以从0逐渐上升到与预定值。但是当节点池只有一台服务器时，`slow start` 参数是无效的。

```nginx
upstream backend {
    server backend1.example.com:12345 slow_start=30s;
    server backend2.example.com;
    server 192.0.0.1 backup;
}
```

## 3. TCP Health Check

TCP Health Check 会对代理池中的节点进行主动监测。

当出现连续 **3** 个非响应等TCP请求时，则被该服务认为是失效的服务。失效后只有连续满足 **2** 个正常响应后，才能重新上线，中间 NGINX 服务器会每隔 **10** 秒进行一次检测。

```nginx
stream { 
    server { 
        listen 3306; 
        proxy_pass read_backend; 
        health_check interval=10 passes=2 fails=3;
    } 
}
```

## 4. HTTP健康监测

HTTP Health Check 会每 **2** 秒访问一次/目录，连续五次通过测试，则确认健康状态，连续 **2** 次失败则认为服务器宕机。返回response必须与match模块匹配。

```nginx
http {
    server {
        ...
        location / {
            proxy_pass http://backend;
            health_check interval=2s
                fails=2
                passes=5
                uri=/
                match=welcome;
        }
    }
    # status is 200, content type is "text/html",
    # and body contains "Welcome to nginx!"
    match welcome {
        status 200;
        header Content-Type = text/html;
        body ~ "Welcome to nginx!";
    }
}
```