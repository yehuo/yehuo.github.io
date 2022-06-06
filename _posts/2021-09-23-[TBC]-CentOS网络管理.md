---
title: "CentOS网络管理"
date: 2021-09-23
excerpt: "CentOS7中的网络配置方式"
categories: 
    - OS
tags:
    - Linux
    - Network
---



# Manual Configure

手工配置CentOS网络时需要修改`ifcfg-eth0`文件

```shell
vi /etc/sysconfig/network-scripts/ifcfg-eth0
```

Network Config文件修改内容参考如下配置

```shell
 DEVICE=eth0  #网卡设备名称   
 ONBOOT=yes  #启动时是否激活 yes | no  
 BOOTPROTO=static  #协议类型 dhcp bootp none  
 IPADDR=192.168.1.90  #网络IP地址  
 NETMASK=255.255.255.0  #网络子网地址  
 GATEWAY=192.168.1.1  #网关地址  
 BROADCAST=192.168.1.255  #广播地址  
 HWADDR=00:0C:29:FE:1A:09  #网卡MAC地址  
 TYPE=Ethernet  #网卡类型为以太网
```

修改完成后，仍需采用重启network服务使之生效

```shell
/etc/init.d/network reload
```

# NetworkManager



## Reference

https://www.cnblogs.com/zonglonglong/p/12545400.html

https://blog.csdn.net/whatday/article/details/106112714