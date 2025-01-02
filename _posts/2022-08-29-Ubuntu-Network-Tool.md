---
title: "Ubuntu Network Tools: Replacing ifconfig and netstat"
date: 2022-08-29
excerpt: "随着 ifconfig 和 netstat 的逐步淘汰，ip 和 ss 已经成为 Ubuntu 系统中管理网络的现代工具。这篇专门研究了 ip 命令的基本用法，帮助系统管理员告别旧命令，并展示如何通过 netplan 检查网络配置的有效性。"
categories: 
   - Ubuntu
tags:
   - Network
   - Tooling
---



在Ubuntu系统中，`ip`和`ss`命令已逐步取代传统的`ifconfig`和`netstat`命令。`ip`和`ss`命令是基于`iproute2`包的工具，它们更高效、功能更强大，因此推荐使用这些命令来管理和调试网络设置。

# `ip` 命令介绍

`ip`命令替代了旧的`ifconfig`命令，采用模块化设计，包含多个功能模块，主要用于网络设备、路由、地址等的管理。

## 常用模块

- **link**：查看网络设备
- **address**：设备上的协议地址
- **addrlabel**：协议地址选择标签配置
- **route**：路由表条目
- **rule**：路由策略数据库中的规则

Ubuntu官方也推荐使用`ip`命令代替`ifconfig`，并且建议使用`ss`代替`netstat`。这两个工具的引入增强了网络管理的灵活性和可扩展性。

## `ip` 常用操作及选项

以下是一些常用的`ip`命令操作：

```shell
# 查看网口信息
ip link show

# 开启网卡 eno1
ip link set eno1 up

# 设置网卡 MTU 为 1400
ip link set eno1 mtu 1400

# 查看设备 IP 地址
ip addr show

# 为 eno1 网卡设置 IP 地址
ip addr add 192.168.0.1/24 dev eno1

# 删除 eno1 网卡上的 IP 地址
ip addr del 192.168.0.1/24 dev eno1

# 设置默认网关
ip route add default via 192.168.1.254

# 设置特定路由，通过网卡 eno1 发送流量
ip route add 192.168.4.0/24 via 192.168.0.254 dev eno1
```

通过这些命令，用户可以轻松地查看和修改网络配置。

# `ss` 命令介绍

`ss`（Socket Statistics）命令是用来查看网络套接字的状态和统计信息，已逐渐取代传统的`netstat`命令。`ss`比`netstat`更高效，能够处理大量连接并快速返回结果，同时支持更多的过滤选项，适合用于快速查询和调试。

## 常用 `ss` 命令选项

```shell
# 查看所有连接（包括监听中的连接）
`ss` -a

# 查看所有监听的端口
`ss` -l

# 查看所有 TCP 连接
`ss` -t

# 查看所有 UDP 连接
`ss` -u

# 查看连接的概览统计信息
`ss` -s

# 查看指定端口的连接
`ss` -t dst 192.168.1.1

# 查看详细信息
`ss` -n   # 数字化显示 IP 和端口
`ss` -p   # 显示连接与进程的对应关系
`ss` -i   # 显示连接的详细信息，包括内核状态
```

## 示例

```shell
# 查看所有 TCP 连接，包括监听和已建立的连接
`ss` -t -a

# 查看所有监听中的 TCP 端口
`ss` -ltn

# 查看与进程相关的端口
`ss` -pln

# 查看所有 UDP 连接
`ss` -u -a
```

`ss`命令提供了比`netstat`更多的过滤选项，能够帮助用户精确地查询网络连接的详细信息。

## `ss` 命令的优势

1. **性能高**：``ss``比`netstat`更高效，特别是在处理大量连接时能够迅速返回结果。
2. **功能强大**：支持更多的过滤选项，能够根据协议、端口、状态等条件查询信息。
3. **更简洁的输出**：``ss``默认输出简洁，但也支持详细输出，满足不同用户需求。
4. **内核支持**：直接与内核交互，提供准确的网络连接状态。

# 总结

随着`iproute2`包的普及，`ip`和`ss`命令已成为现代Linux系统中网络管理的标准工具。通过这些命令，用户可以更高效、灵活地管理网络设备、查看网络状态以及调试网络连接。推荐用户逐步告别传统的`ifconfig`和`netstat`命令，转而使用功能更强大、性能更优的`ip`和`ss`。

------

## References

- [If you’re still using ifconfig, you’re living in the past](https://ubuntu.com/blog/if-youre-still-using-ifconfig-youre-living-in-the-past)
- [ss: another way to get socket statistics](https://ubuntu.com/blog/`ss`-another-way-to-get-socket-statistics)
- [Using `ip address show type` to display physical network interface](https://serverfault.com/questions/1019363/using-ip-addre`ss`-show-type-to-display-physical-network-interface)