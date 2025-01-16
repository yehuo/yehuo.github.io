---
title: From HCI to Proxmox
date: 2022-11-17
excerpt: "超融合架构HCI的一些基础知识..."
categories: 
    - Cloud Service
tags: 
    - Virtualization
---



# 0x01 什么是 HCI 超融合？

根据 软件定义 的 IT 基础架构，将所有硬件定义系统中的元素虚拟化，至少包含一下三项

- 软件定义的存储
- 虚拟化网络software-defined networking
- 虚拟化计算hypervisor

具体而言，就是将零碎的，硬件定义的系统，统一链接和包装到一个完全的软件定义环境当中。然后使用一些开箱即用的商用服务器（commercial off-the-shelf， COTS servers）来部署。HCI系统通常由装有direct attached storage的服务器组成，HCI具有系统聚合能力，可以将所有物理数据中心资源都驻留在硬件和软件层的单一管理平台上。

HCI的主要目标是，公司可以忽略掉各类计算和存储系统的差异，不过如果想要代替所有商业领域中的存储阵列，现在还为时过早。

# 0x02 HCI 相关的核心文章

### 1. [SUSE定义超融合架构](https://www.suse.com/suse-defines/definition/hyper-converged-architecture/)

However, a drawback to this approach is that all resources must be increased in order to increase any single resource. This means that companies that want to get more storage capacity have to increase their compute power at the same time, whether they need more or not.

HCI carries the risk of vendor lock-in, because you can’t combine nodes from one HCI vendor with those from another. Still, many organizations are drawn to the ease of management and the lower TCO that can be achieved in a hyper-converged data center.

### Converged infrastructure

**Converged infrastructure** is a way of structuring an [information technology](https://en.wikipedia.org/wiki/Information_technology) (IT) system which groups multiple components into a single optimized computing package.

# 0x03 HCI 沿革简析

从 Wikipedia 的文献时间可以看出来，HCI（hyper-converged-architecture） 这个概念最火的时间是在 2015 年。之前的 CI（Converged Infrastructure）比较火的时间是在 2009 年。二者在名字上的区别就是 **Hyper** 这个前缀，具体来说就是虚拟化在基础架构中所起的作用。

![HyperConvergence](https://upload.wikimedia.org/wikipedia/commons/c/ca/Hyperconvergence.jpg)

相比于今天的云计算，HCI 架构的一个较为明显的劣势其虚拟化的程度不够。HCI 概念中被反复提及的 TCO （Total cost of ownership），就是要求系统使用统一化的商用服务器。

HCI 这个概念本身并不打算解决混乱的底层硬件环境问题。HCI 是寄希望于企业通过采购在一套服务器，甚至于一个型号的服务器去解决所有问题。

但是在现实场景中中，这个预期显然是不现实的。从商业角度看，服务器供应商垄断机房供应必然会产生企业失去议价权的麻烦。从技术角度看，生产环境所需的一些特定 feature 往往需要扩大采购范围，这两方面原因都会导致生产环境里的服务器没法真正做到型号一致。

最终，现代的云服务实际上是通过 容器化 才真正克服了这个问题。无论对于什么样的硬件设置，只要能跑 Linux，就能做**容器隔离**，只要能做容器隔离，Kubernetes 等容器编排服务就会帮你解决网络、存储、计算等所有问题。计算资源、存储资源也做到了分开配置。

当然，由于增加了新的容器层，相比于 HCI，云计算架构的 io 效率和计算效率都是有所损耗的。例如一台16核的云服务器，是绝对无法运行 4 个 4 core request 的 Pod 的。

所以对于一些刚刚起步的小公司，HCI 依然不失为一个简单高效私有云解决方案，至少比最原始的那种一个单体服务运行在几个硬件服务器上的架构还是好维护很多。在满足业务需求的条件下，HCI 这套东西的 TCO 确实很平衡，更适合小型运维团队。

---

## Reference

- [[Wikipedia] Hyper-converged infrastructure](https://en.wikipedia.org/wiki/Hyper-converged_infrastructure)
- [[Wikipedia] Converged infrastructure](https://en.wikipedia.org/wiki/Converged_infrastructure)