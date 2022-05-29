---
title: ZFS Storage基础
date: 2021-11-17
excerpt: 关于ZFS cluster作为存储解决方案的一些常识
categories: 
  - Devops
  - Storage
tags:
  - ZFS
---

# Zpools, Vdevs, and Devices

## zpool

每个Zpool中vdev的拓扑种类可以不同

## topologies

- Single Disk

  Single-device vdevs are also just what they sound like—and they're inherently dangerous. A single-device vdev cannot survive any failure—and if it's being used as a storage or `SPECIAL` vdev, its failure will take the entire `zpool` down with it. Be very, very careful here.

- Mirror

  Mirror vdevs are precisely what they sound like—in a mirror vdev, each block is stored on every device in the vdev. Although two-wide mirrors are the most common, a mirror vdev can contain any arbitrary number of devices—three-way are common in larger setups for the higher read performance and fault resistance. A mirror vdev can survive any failure, so long as at least one device in the vdev remains healthy.

- RAIDz1 & RAIDz2 & RAIDz3

  RAIDz1, RAIDz2, and RAIDz3 are special varieties of what storage greybeards call "diagonal parity RAID." The 1, 2, and 3 refer to how many parity blocks are allocated to each data stripe. Rather than having entire disks dedicated to parity, RAIDz vdevs distribute that parity semi-evenly across the disks. A RAIDz array can lose as many disks as it has parity blocks; if it loses another, it fails, and takes the `zpool` down with it.

## vdev

通常vdev都是存储原声数据，但是一些支持vdev可以提供上面的topologies支持

## 支持类vdev

- CACHE
- LOG
- SPECIAL

`CACHE`, `LOG`, and `SPECIAL` vdevs can be created using any of the above topologies—but remember, loss of a `SPECIAL` vdev means loss of the pool, so redundant topology is strongly encouraged.

## Devices

# Datasets, Blocks, and Sectors

# Copy-on-Write

Unlinking the old `block` and linking in the new is accomplished in a single operation, so it can't be interrupted—if you dump the power after it happens, you have the new version of the file, and if you dump power before, then you have the old version. You're always filesystem-consistent, either way.

Copy-on-write in ZFS isn't only at the filesystem level, it's also at the disk management level. This means that the RAID hole—a condition in which a stripe is only partially written before the system crashes, making the array inconsistent and corrupt after a restart—doesn't affect ZFS. Stripe writes are atomic, the vdev is always consistent.

# ZIL(ZFS Intent Log) & SLOG(Secondary Log Device)

两种redo方法，ZIL模式下，Write操作会同时写入RAM和Zpool中的ZIL中。正常情况下，ZIL是只写的（pool import操作例外）。当crash发生后，ZIL将缓存数据重新交给RAM，并再次由RAM永久写入Zpool的永久存储设备。SLOG模式下，ZIL的角色由一个特殊的vdev担当，这个vdev将被视作log vdev。

SLOG的实现内部还是相当于把不同vdev上的ZIL集中达到了一个vdev上存储，通过使用更快的存储设备作为log vdev，可以提升Write速度。

# Reference

https://arstechnica.com/information-technology/2020/05/zfs-101-understanding-zfs-storage-and-performance/