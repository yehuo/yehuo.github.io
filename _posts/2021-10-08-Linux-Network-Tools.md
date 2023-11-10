---
title: "Linux Network Tools"
date: 2021-10-08
excerpt: "谈谈Ubuntu中常用的几个网络诊断工具"
categories: 
    - Tools
tags: 
    - Ubuntu
    - Linux
---



# Network Tools

## ping

## traceroute

Linux系统中，命令为traceroute，通常需要独立安装

Windows中为tracert，Windows中自带

## Principle

> traceroute是利用 ICMP 及 IP header 的`TTL` field。首先，traceroute送出一个`TTL`为 1 的IP datagram（其实，每次送出的为3个40字节的包，包括源地址，目的地址和包发出的时间标签）到目的地，当路径上的第一个路由器（router）收到这个datagram时，它将`TTL`减1。
>
> 此时，`TTL`变为0了，所以该路由器会将此datagram丢掉，并送回一个`ICMP time exceeded`消息（包括发IP包的源地址，IP包的所有内容及路由器的IP地址），traceroute 收到这个消息后，便知道这个路由器存在于这个路径上，接着traceroute 再送出另一个`TTL`是2 的datagram，发现第2 个路由器。由此类推，traceroute 每次将送出的datagram的`TTL`加1来发现另一个路由器，这个重复的动作一直持续到某个datagram 抵达目的地。
>
> 当datagram到达目的地后，该主机并不会送回`ICMP time exceeded`消息，因为它已是目的地了，那么traceroute如何得知目的地到达了呢？Traceroute在送出UDP datagrams到目的地时，它所选择送达的port number 是一个一般应用程序都不会用的号码（30000 以上），所以当此UDP datagram 到达目的地后该主机会送回一个`ICMP port unreachable`的消息，而当traceroute 收到这个消息时，便知道目的地已经到达了。所以traceroute 在Server端也是没有所谓的Daemon程式。

## Usage

> Traceroute提取发 ICMP TTL到期消息设备的IP地址并作域名解析。每次 ，Traceroute都打印出一系列数据,包括所经过的路由设备的域名及 IP地址,三个包每次来回所花时间。
>
> 有时我们traceroute 一台主机时，会看到有一些行是以星号表示的。出现这样的情况，可能是防火墙封掉了ICMP的返回信息，所以我们得不到什么相关的数据包返回数据；
>
> 有时我们在某一网关处延时比较长，有可能是某台网关比较阻塞，也可能是物理设备本身的原因。当然如果某台DNS出现问题时，不能解析主机名、域名时，也会 有延时长的现象；您可以加-n 参数来避免DNS解析，以IP格式输出数据；
>
> 如果在局域网中的不同网段之间，我们可以通过traceroute 来排查问题所在，是主机的问题还是网关的问题。如果我们通过远程来访问某台服务器遇到问题时，我们用到traceroute 追踪数据包所经过的网关，提交IDC服务商，也有助于解决问题；但目前看来在国内解决这样的问题是比较困难的，就是我们发现问题所在，IDC服务商也不可能帮助我们解决。

## Example

```shell
# 设定最大跳数
traceroute -m 10 www.baidu.com
# 只看IP，不查主机名
traceroute -n www.baidu.com
```

# dig

# mtr

## Reference

- [traceroute讲解](https://www.cnblogs.com/peida/archive/2013/03/07/2947326.html)
- [mtr官方文档](https://linux.die.net/man/8/mtr)