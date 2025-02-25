---
title: "Linux File System Deepdive Session"
date: 2021-09-24
excerpt: "Linux文件系统中的基础概念与常用命令"
categories: 
    - System
tags:
    - File System
---



# 概念解析

- sector
- block
- group
- inode
- 磁盘分区方式：GPT vs MBR
- 文件管理系统：From `ext2` to `xfs`

# 查看当前分区状态

## 分区操作

## `df` 分区状态统计

## `dumpe2fs` 查看分区详细信息

## `mount/umount` 挂载分区

## `tune2fs` 查看ext2/ext3文件系统参数

## `lsblk` / `blkid` / `blockdev` 查看修改block信息

## `e2label` 设定分区label

## 文件操作

## `du` 查看空间占用

## `stat` 查看详细信息

## `fuser` 查找使用文件进程

## 修改分区状态

## `mkfs` / `mke2fs` 格式化分区

## `fdisk` 查看管理分区

## `fsck` / `badblocks` / `filefrag` 检查修复分区

## Reference

- [Linux inode详解](https://www.cnblogs.com/llife/p/11470668.html)
- [Linux存储相关命令](https://blog.liu-kevin.com/2020/11/01/linuxcun-chu-xiang-guan-ming-ling/)

