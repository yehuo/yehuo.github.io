---
title: "Ceph基础知识"
date: 2022-07-25
excerpt: "结合ceph基础知识对proxmox存储的分析..."
categories: 
    - Storage
tags: 
    - HCI
---



# Introduce

## Advantage

- Easy setup and management via CLI and GUI
- Thin provisioning
- Snapshot support
- Self healing
- Scalable to the exabyte level
- Setup pools with different performance and redundancy characteristics
- Data is replicated, making it fault tolerant
- Runs on commodity hardware
- No need for hardware RAID controllers
- Open source

## Daemons for RBD storage

- Ceph Monitor
- Ceph Manageer
- Ceph OSD(Object Storage Daemon)

# Ceph Startup

## Intro

- **Monitors**: A [Ceph Monitor](https://docs.ceph.com/en/octopus/glossary/#term-Ceph-Monitor) (`ceph-mon`) maintains maps of the cluster state, including the monitor map, manager map, the OSD map, the MDS map, and the CRUSH map. These maps are critical cluster state required for Ceph daemons to coordinate with each other. Monitors are also responsible for managing authentication between daemons and clients. At least three monitors are normally required for redundancy and high availability.
- **Managers**: A [Ceph Manager](https://docs.ceph.com/en/octopus/glossary/#term-Ceph-Manager) daemon (`ceph-mgr`) is responsible for keeping track of runtime metrics and the current state of the Ceph cluster, including storage utilization, current performance metrics, and system load. The Ceph Manager daemons also host python-based modules to manage and expose Ceph cluster information, including a web-based [Ceph Dashboard](https://docs.ceph.com/en/octopus/mgr/dashboard/#mgr-dashboard) and [REST API](https://docs.ceph.com/en/octopus/mgr/restful). At least two managers are normally required for high availability.
- **Ceph OSDs**: A [Ceph OSD](https://docs.ceph.com/en/octopus/glossary/#term-Ceph-OSD) (object storage daemon, `ceph-osd`) stores data, handles data replication, recovery, rebalancing, and provides some monitoring information to Ceph Monitors and Managers by checking other Ceph OSD Daemons for a heartbeat. At least three Ceph OSDs are normally required for redundancy and high availability.
- **MDSs**: A [Ceph Metadata Server](https://docs.ceph.com/en/octopus/glossary/#term-Ceph-Metadata-Server) (MDS, `ceph-mds`) stores metadata on behalf of the [Ceph File System](https://docs.ceph.com/en/octopus/glossary/#term-Ceph-File-System) (i.e., Ceph Block Devices and Ceph Object Storage do not use MDS). Ceph Metadata Servers allow POSIX file system users to execute basic commands (like `ls`, `find`, etc.) without placing an enormous burden on the Ceph Storage Cluster.

## Architecture

### Dynamic Cluster Management (Pools)

Ceph支持Storage Pools的概念，实际就是为所有存储对象提供一个逻辑分区位置。Ceph在将对象写入Storage Pools时，多需要先从Ceph Monitor获取最新的Cluster Map。Pools的大小、副本数目、CRUSH规则和Placement Group的数目会最终决定Ceph如何存储data。

![../_images/6bd81b732befb17e664371189141fdf2c18e032d2c0f87b2a29f8fb78f895f78.png](https://docs.ceph.com/en/octopus/_images/6bd81b732befb17e664371189141fdf2c18e032d2c0f87b2a29f8fb78f895f78.png)

Pools由下面几个参数定义：Objects的所有者和权限，Placement Groups的数目和当前所用的CRUSH规则

### [MAPPING PGS TO OSDS](https://docs.ceph.com/en/octopus/architecture/#mapping-pgs-to-osds)

每个storage pool都有许多placement groups，CRUSH会动态的将这些PG映射到OSD中去。当Clients真正存储一个obj时，CRUSH会将每个obj映射到一个PG上去。

将obj映射到PGs的过程，实际上就是在OSD守护进程和Ceph Client中间创建了一个隐形中间层。Ceph Storage Cluster则完成了动态增减和平衡obj存储位置的功能。只要Client知道哪个OSD拥有哪些obj，就可以创建一种Client和OSD之间的紧耦合。CRUSH算法则会将每个obj映射到一个PG，然后将每个PG交给一个或多个Ceph OSD管理。而这种中间层的产生，也允许当新的OSD进程和底层OSD设备加入到集群后，进行存储位置的动态平衡。下图展示了CRUSH如何将obj映射到PG，然后将PG映射到OSD。

![../_images/f592d64bd19e67476c118c14caf9d4e3df61607d25670d5b3e83b45d2f29db99.png](https://docs.ceph.com/en/octopus/_images/f592d64bd19e67476c118c14caf9d4e3df61607d25670d5b3e83b45d2f29db99.png)

这样只要凭借一份Cluster map和CRUSH算法，Client就能计算出使用哪个OSD来读取特定的某个obj。

### Calculating PG IDs

Client与Monitor绑定后，就可以获得最新的Cluster Map，Client就可以获得所有monitors、OSDs和nodes metadata信息。**但是其中不包含obj的存储位置。**

> Object locations get computed

Client只需要知道obj ID和对应Pools就可以计算出location。举例来说，当一个Client想要存储一个名为george的obj，Client会通过下面四项计算出一个存储位置：

- obj name
- obj name hash code
- number of PGs in Pool
- Pool Name

具体计算流程如下：

1. Client输入Pool name和Object ID
2. Ceph提取object ID，然后计算其hash值
3. Ceph使用PGs的数目对hash值取模
4. Ceph根据Pool Name获得Pool ID
5. 拼接Pool ID和PG ID

这种计算方式要比通过一个session传输快很多。Client只要通过CRUSH算法计算出obj应该存放的PG，就可以通过primary OSD存取obj。

### Peering and Sets

每个PGs都应该被存储在至少两个地方，所以OSD之间会做数据同步，被称为Peering。每个Acting Set中，第一个OSD被称为Primary OSD（第二个被称为Secondary OSD），是一个比较特殊的OSD。Primary OSD负责协调其他OSD之间的Peering过程，且是唯一可以接收client-initiated writes obj请求的OSD。

当有许多OSD对一个PG负责时，这些OSD就被成为Acting Set。一个Acting Set通常就是指当前对某个PG负责的一系列OSD，或是某个时期对PG负责的一系列OSD。但是Acting Set中所有OSD并非总是处于up状态，当一个OSD处于up状态时，它就属于Acting Set中的Up Set。而当一个OSD fail时，Ceph就会将PGs remap到Up Set中的其他OSD去。

> In an *Acting Set* for a PG containing `osd.25`, `osd.32` and `osd.61`, the first OSD, `osd.25`, is the *Primary*. If that OSD fails, the Secondary, `osd.32`, becomes the *Primary*, and `osd.25` will be removed from the *Up Set*.

### Rebalancing

在Cluster中添加OSD后，由于计算PG ID的流程发生改变，就需要进行PG的rebalancing，这个过程就会更改Cluster Map，下图粗略展示了Rebalancing流程，对于大型集群，这个流程影响要小得多。注意即使是在Rebalancing过程中，CRUSH仍然是稳定的。

![../_images/930c5c07291356f1e914a3dae54c53ce2f68bff4680cf7bc423ad0855e263bc0.png](https://docs.ceph.com/en/octopus/_images/930c5c07291356f1e914a3dae54c53ce2f68bff4680cf7bc423ad0855e263bc0.png)

### Data Consistency

作为维护数据一致性和清洁性的一部分。Ceph OSD会在PG中scrub数据对象。具体来说，就是Ceph会比较拿PG的metadata和其存储在其他OSD的副本PG作比较。这种流程可以帮助处理OSD bugs和文件系统错误。OSD也可以逐比特进行深层scrub。Deep scrubbing可以找到disk上的bad sectors，而这是light scrub无法完成的。

## Reference

- [Deploy Hyper-Converged Ceph Cluster](https://pve.proxmox.com/wiki/Deploy_Hyper-Converged_Ceph_Cluster)
- [Ceph Intro](https://docs.ceph.com/en/octopus/start/intro/)
- [Ceph Architecture](https://docs.ceph.com/en/octopus/architecture/)
- [Ceph Glossary](https://docs.ceph.com/en/octopus/glossary/)


