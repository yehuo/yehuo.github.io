---
title: "Ubuntu网络工具"
date: 2022-08-29
excerpt: "是时候告别ifconfig和netstat了"
categories: 
   - Experience
tags:
   - Ubuntu

---



# 网络命令一二事

`ip`命令是可以替代前期的`ifconfig`命令的，秉承一些复杂linux命令的涉及思路，`ip`指令下的功能是以模块化设计的，主要包含下面几个模块

- `link`查看网络设备
- `address`设备上协议地址
- `addrlabel`协议地址选择标签配置
- `route`路由表条目
- `rule`路由策略数据库中的规则

Ubuntu官方也是[建议](https://ubuntu.com/blog/if-youre-still-using-ifconfig-youre-living-in-the-past)要使用`ip`来代替`ifconfig`的，此外同样[建议](https://ubuntu.com/blog/ss-another-way-to-get-socket-statistics)使用`ss`代替`netstat`，这两项替换都来源与`iproute2` package的引入。

最后无论在使用`ip`命令修改后，还需要使用`netplan`交互式查看修改的有效性。

# `ip`常用操作及option

凡是可以通过`ip link show`看到的信息也都都可以通过`ip link`命令设置的

```shell
ip link show	# 查看网口信息
ip link set eno1 up	# 开启eno1网卡
ip link set eno1 mtu 1400	# 设置一个网口的mtu

ip addr show 	# 内容与link show较为相似
ip addr add 192.168.0.1/24 dev eno1	# 为eno1设定IP
ip addr del 192.168.0.1/24 dev eno1	# 删除eno1网卡IP

ip route show add default via 192.168.1.254	# 设置默认网关
# 设定192.168.4.0/24的流量从eno1走254网关发出
ip route add 192.168.4.0/24 via 192.168.0.254 dev eno1
```

# Reference

- [If you’re still using ifconfig, you’re living in the past](https://ubuntu.com/blog/if-youre-still-using-ifconfig-youre-living-in-the-past)
- [ss: another way to get socket statistics](https://ubuntu.com/blog/ss-another-way-to-get-socket-statistics)
- [什么不能用`ip address show type`看到物理网口（附shell偷鸡方法）](https://serverfault.com/questions/1019363/using-ip-address-show-type-to-display-physical-network-interface)