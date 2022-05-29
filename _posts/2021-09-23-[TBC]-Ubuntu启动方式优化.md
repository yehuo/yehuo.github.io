---
title: Ubuntu启动方式优化
date: 2021-09-23
excerpt: 工作中的start project-增进ubuntu preseed 自动化
categories: 
- Tech
- OS
tags:
- Ubuntu
---



Ubuntu系统网络安装通常采用两类方法，或是使用定制镜像，或是使用初始镜像+应答文件。前者修改复杂，但是安装迅速，支持无人化操作。后者修改简单，但是安装较慢，支持多镜像选择（也意味着通常要有人进行初始操作）。

这次工作是通过应答文件完成的，所以仅介绍后一种安装方式。

# 概念解析

- [PXE](https://en.wikipedia.org/wiki/Preboot_Execution_Environment)

  > In computing, the **Preboot eXecution Environment**, **PXE** (most often pronounced as [/ˈpɪksiː/](https://en.wikipedia.org/wiki/Help:IPA/English) *pixie*) specification describes a standardized [client–server](https://en.wikipedia.org/wiki/Client–server_model) environment that [boots](https://en.wikipedia.org/wiki/Booting) a software assembly, retrieved from a network, on PXE-enabled clients. On the client side it requires only a PXE-capable [network interface controller](https://en.wikipedia.org/wiki/Network_interface_controller) (NIC), and uses a small set of industry-standard network protocols such as [DHCP](https://en.wikipedia.org/wiki/DHCP) and [TFTP](https://en.wikipedia.org/wiki/TFTP).

- 启动文件

  启动文件指的就是启动过程中target server需要从TFTP上下载的文件，通常包括镜像(image)、应答文件(pxelinux.0)，启动引导(bootloader)

  - bootloader

  - 应答文件(preseed file)

    对于preseed的支持更多来源于Ubuntu官方，Ubuntu的preseed文件支持一种独特的语法，大部分语句以`d-i`开头，以如下格式组成命令：

    ```
    <owner> <question name> <question type> <value>
    ```

    更多语法参考Ubunut amd64架构[Help Doc apbs](https://help.ubuntu.com/lts/installation-guide/amd64/apb.html)，文档有中文版，但是翻译做的比较google...建议不看。

- 固件支撑基础——[iPXE](https://ipxe.org/)

  ipxe实际上是一种固件（实际需要有专门硬件支持，这个硬件专门用于PXE，同时支持你用代码方式修改它的运行方式和参数），用以代替传统通过网卡上PXE ROM来实现的PXE流程。通过iPXE技术，可以实现通过如下方式启动：HTTP、iSCSI SAN、wireless Network等，以及可以通过script来控制启动流程（例如选择不同镜像，设置kernel参数等）。

  通常使用`ctrl+B`来进入命令行，但是有些解决方案里取消了这个快捷键（例如netbootxyz），支持直接选择进入iPXE命令行。

- 固件解决方案——[netbootxyz](https://github.com/netbootxyz)

  netboot.xyz实际上是对iPXE的一层封装，完善了对多架构的支持，添加了对选择页面的优化（例如添加背景图）。一些组织提供了很好的安装镜像，但是netbootxyz本身文档做的非常差劲，更多功能还是要通过直接参考ipxe设置完成

- **UEFI** & **Legacy BIOS**

# 架构设计

整个preseed系统通常需要提前在网络中布置以下三类service

- dhcp：用于引导服务器进入net boot镜像启动
- tftp：用于存放安装所需文件，例如应答文件
- nfs：用于存放安装所需组件，如镜像、内核
- dns：用于解析域名来完成文件下载

现实情况中，大部分人都是所有服务放到一个physical server上实现，其中tftp和nfs实际上又可以合并到netbootxyz服务中，本文将dhcp和netbootxyz分开两个server存放，并对dns所需的配置做简单讲解。

## DHCP Server

## Option 1: [dnsmasq](https://en.wikipedia.org/wiki/Dnsmasq)

> dnsmasq is a lightweight, easy to configure DNS forwarder, designed to provide DNS (and optionally DHCP and [TFTP](https://en.wikipedia.org/wiki/Trivial_File_Transfer_Protocol)) services to a small-scale network. It can serve the names of local machines which are not in the global DNS.

dnsmasq组件是由个人开发的，可同时部署dns、dhcp、tftp三种服务的方案，目前较为流行，本文不做讲解。

## Option 2: isc-dhcpd [Recommended]



## Netboot Server (Netboot.xyz)





## DNS Server

## powerdns

# Reference

[脚本配置GRUB2+iPXE引导netboot.xyz进行网络重装](https://www.sm.link/2020/07/08/92.html)