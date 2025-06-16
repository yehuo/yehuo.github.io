---
title: "Linux基础"
date: 2025-06-16
categories:
  - System
tags:
  - Linux
excerpt: "一些常见的Linux面试问题"
---



# Linux 系统基础

## Part A 系统工具与调试

### 1. CPU分析

- `top` / `htop`：实时 CPU 使用率（三个数字代表1/5/15分钟内CPU执行进程的平均数）
- `vmstat`：查看 CPU 的 user/sys/io 等占比
- `mpstat`（来自 `sysstat`）：多核 CPU 使用情况
- `perf top / perf record`：函数级别的 CPU 开销分析

### 2. 内存分析

- `top` / `htop`：进程级内存占用
- `free -h`：系统整体内存占用
- `vmstat`：内存分页、swap 情况
- `perf stat`：查看 cache miss
- `sar -r`（来自 sysstat）：内存统计历史

### 3. **磁盘 I/O 分析**

- `iotop`：进程级磁盘 I/O
- `iostat`（sysstat）查看设备级磁盘使用率
- `dstat`：实时磁盘读写 + 网络数据
- `strace`：追踪文件 read/write 系统调用

### 4. **系统调用级诊断**

- `strace -p <pid>`：查看进程的系统调用序列
- `perf trace`：按系统调用频率分析程序瓶颈，用于排查程序卡顿、慢调用、未响应等

### 5. **网络与端口占用**

- `ss -tulnp` / `netstat`：查看端口监听
- `lsof -i :80`：查看哪个进程占用了 80 端口
- `dstat -n`：实时网络流量
- `iftop` / `nethogs`（额外工具）：进程级网络流量监控

### 6. **文件句柄 / FD 泄漏**

- `lsof`：列出进程打开的所有文件、socket、FIFO
- `ls /proc/<pid>/fd/`：直接查看 FD 数

### 7. 常见问题排查诊断

> 标准回答：我通常使用 `vmstat 1 5` 来快速定位系统瓶颈。通过观察 `r`, `b`, `si/so`, `wa`, 和 `cs` 字段，可以判断系统是 CPU 饱和、I/O 阻塞、还是内存不足，进而决定是否深入用 `iotop`, `perf`, 或 `top -H` 等工具进一步排查。
>
> | 现象             | 可能问题                   |
> | ---------------- | -------------------------- |
> | `r` ≫ CPU 核心数 | CPU 排队严重               |
> | `b` 持续不为 0   | I/O 阻塞严重               |
> | `si/so` 持续大   | swap 活跃，内存不足        |
> | `wa` > 20%       | I/O 等待瓶颈，磁盘慢       |
> | `cs` 很高        | 线程调度过多，可能线程泄漏 |
> | `id` ≈ 0         | CPU 饱和                   |

**内存泄漏**：程序内存占用不断上升，**free -h 中可用内存持续下降**；应用长时间运行后变慢、卡顿，甚至 OOM 被杀死；`top`/`htop` 中 RSS 或 VIRT 持续增大。

```shell
free -h					# 查看内存变化
vmstat 1 5			# 1s一次采样5次 性能监控结果
top -o %MEM      # 按内存排序
ps aux --sort=-%mem | head
watch -n 1 pmap -x <pid> | grep total	# 查看进程内存增长趋势
cat /proc/<pid>/status								# 排查是否是泄漏还是缓存
```

**CPU 使用率异常**：`top` 中 `%us` 或 `%sy` 占用高，`idle` 逼近 0%；`load average` 高于 CPU 核心数；响应慢、线程卡顿。

```shell
top								# 判断是单核爆？还是所有核爆？
mpstat -P ALL 1 5	# 1s一次采样5次 CPU核心使用情况
top -o %CPU				# 定位高占用进程
ps aux --sort=-%cpu | head	# 查找PID
top -H -p <pid>		#查找线程级别占用
```

**线程数爆炸**：程序线程数迅速增加，占用大量资源；上下文切换暴增（`cs` in `vmstat`）；进程崩溃、卡死、响应慢。

```shell
ps -eLf | wc -l            # 系统总线程数
ps -L -p <pid> | wc -l     # 某进程的线程数
watch "ps -L -p <pid> | wc -l"	# 监控线程增长，判断线程泄漏
# 最后查看线程堆栈，判断线程池未回收、死循环
```

## Part B 系统启动与服务管理

### 8. 什么是systemd、journalctl、systemctl

**`systemd` 系统和服务管理器（底层框架）**，是一个**初始化系统（init system）**，取代了传统的 `SysVinit` 和 `Upstart`。启动时由**内核调用，负责初始化系统、挂载文件系统、启动服务**等。同时还包含定时器、登录会话管理、日志管理等子模块。

**`systemctl` 是用于控制和管理 systemd 的服务（最常用的命令）**，是操控 `systemd` 的主力工具，支持启动、停止、查看、配置服务等操作。

**`journalctl` 用于查看 systemd 的日志系统**，是 `systemd` 内建的日志管理工具，用来替代传统的 `/var/log/messages` 或 `rsyslog`

### 9. 如何查看系统日志、服务状态、故障定位

使用 `journalctl` 查看系统日志，非 `systemd` 系统打开 `/var/log` 查看系统日志

```shell
journalctl -xe         # 查看最近的错误日志（最常用）
journalctl -u nginx    # 查看 nginx 服务日志
journalctl -f          # 实时滚动日志（tail -f）
journalctl -b          # 查看上次启动以来的日志
```

使用 `systemctl` 查看服务状态，非 `systemd` 系统使用 `service` 命令（SysVinit / Upstart 通用）或服务 `init`脚本（极简系统、容器环境或 `service` 命令不存在的系统）来查看服务状态

```shell
systemctl status nginx       # 查看 nginx 服务状态
systemctl is-active nginx    # 是否运行中（running）
systemctl is-enabled nginx   # 是否开机自启
systemctl restart nginx      # 重启服务
systemctl list-units --type=service  # 查看所有服务状态
```

其他内容诊断

| 工具         | 作用                             | 示例                |
| ------------ | -------------------------------- | ------------------- |
| `top`/`htop` | 总览资源使用情况                 | CPU、内存、进程消耗 |
| `vmstat`     | 快速判断是 CPU、I/O 还是内存瓶颈 | `vmstat 1 5`        |
| `iotop`      | 找出磁盘 I/O 高的进程            | `iotop -o -P`       |
| `lsof`       | 查看进程打开的文件和端口         | `lsof -p <pid>`     |
| `strace`     | 跟踪系统调用                     | `strace -p <pid>`   |
| `journalctl` | 查看服务失败的具体日志           | `journalctl -xe`    |
| `dmesg`      | 查看内核级别错误信息             | 如硬盘/内存故障     |

## Part C 文件系统与权限

### 10. 什么是 inode、软硬链接、文件权限 

**inode（索引节点）** 是 Linux 文件系统中，每个文件（包括目录）对应的元数据结构，**记录了文件的所有信息**，除了文件名。

**硬链接（Hard Link）**是**多个文件名指向同一个 `inode`**，即多个目录项共享一个实际文件内容。拥有相同的 inode 号，删除任意一个名字，文件实际内容不会丢失（除非最后一个 link 被删），**不能跨分区、不能对目录创建硬链接**。

**软链接（Symbolic Link / symlink）**是**一个特殊类型的文件，指向另一个文件的路径名**，类似 Windows 的快捷方式。拥有**不同 inode**，可以跨分区、可以指向目录，若原始文件被删除，**软链接失效（变成悬挂链接）**，可以是绝对路径或相对路径。

**文件权限（Permission）**权限中三类用户的顺序是 `User`/`Group`/`Others`，然后用rwx来去做区分，额外还有三种权限**（Special Permissions）** 

- **SUID（Set User ID）**当用户执行某个**可执行文件**时，程序会**临时以该文件的所有者身份运行**。`chmod u+s filename `
- **SGID（Set Group ID）**程序运行时以文件所属“用户组”的身份运行（作用类似 SUID 但针对组），在该目录中新建的文件/目录，其 group 会被**强制继承父目录的组**。`chmod g+s filename_or_dir`
- **Sticky Bit** 只对**目录**有效。启用后，**只有文件的拥有者或 root** 才能删除该目录下的文件。`chmod +t directory`

| 名称           | 标志 | 适用对象          | 功能作用                                               |
| -------------- | ---- | ----------------- | ------------------------------------------------------ |
| **SUID**       | `s`  | 可执行文件        | 运行时使用文件“所有者”的权限                           |
| **SGID**       | `s`  | 可执行文件 / 目录 | 可执行文件：使用“所属组”权限；目录：**新建文件继承组** |
| **Sticky Bit** | `t`  | 目录              | 限制删除行为：只有文件拥有者可以删除自己的文件         |

### 11. 如何变更文件权限 `chmod`, `chown`, `umask`

`chmod` —— 修改文件权限（**change mode**）`chmod [权限模式] 文件名`

`chown` —— 修改文件所有者（**change owner**）`chown [user][:group] 文件名`

`chgrp` —— 修改文件所属组（**change group**）`chgrp [groupname] 文件名`

`umask` —— 设置默认权限掩码（**user file creation mask**），减去掩码才是真实权限

```shell
umask         # 查看当前 umask（如 0022）
umask 0002    # 设置新建文件默认权限为 664，新建目录为 775
```

### 12. ext4 vs xfs 等文件系统性能差异

简单分析

| 文件系统  | 一句话总结                       | 常见用途                     | 特性                       |
| --------- | -------------------------------- | ---------------------------- | -------------------------- |
| **ext4**  | 稳定耐用、安全默认，日常系统首选 | 传统服务器 / Web / 应用部署  | 稳定、默认、安全           |
| **XFS**   | 并发高效，大文件日志吞吐之选     | 日志服务 / 大文件批处理      | 吞吐高、并发好             |
| **Btrfs** | 支持快照压缩，适合容器与开发场景 | 快照 + 压缩 + 容器/开发      | 灵活、支持子卷             |
| **ZFS**   | 数据安全第一，适合归档/数据库    | 数据库 / 存档 / 高可靠性存储 | 自修复 + 快照 + 压缩       |
| **tmpfs** | 内存速度爆炸，但重启就没了       | 高速缓存 / 临时文件 / `/tmp` | 内存中极速读写，掉电即清空 |

详细对比

| 特性/文件系统  | **ext4**      | **XFS**    | **Btrfs**                  | **ZFS**                | **tmpfs**            |
| -------------- | ------------- | ---------- | -------------------------- | ---------------------- | -------------------- |
| 文件系统类型   | journaling    | journaling | copy-on-write + journaling | copy-on-write + 自修复 | 内存文件系统         |
| 最大文件/分区  | 16TB / 1EB    | 8EB / 8EB  | 16EB / 16EB                | 256ZB / 16EB           | 内存限制（动态扩展） |
| 快照支持       | ❌             | ❌          | ✅                          | ✅（功能强大）          | ❌                    |
| 自修复能力     | ❌             | ❌          | ✅（CRC 校验）              | ✅（ECC、自愈）         | ❌                    |
| 并发写入性能   | 中            | ✅ 高       | 中（多子卷支持）           | 中（吞吐高，延迟高）   | 极快（纯内存）       |
| 小文件读写性能 | ✅ 强          | 中         | 中                         | 中                     | ✅ 强                 |
| 在线扩容       | ✅             | ✅          | ✅                          | ✅                      | —                    |
| 在线缩容       | ❌（有限支持） | ❌          | ✅                          | ✅                      | —                    |
| 原生压缩       | ❌             | ❌          | ✅                          | ✅                      | ❌                    |
| 原生 RAID      | ❌             | ❌          | ✅（简单）                  | ✅（RAID-Z 强大）       | ❌                    |
| 是否掉电丢数据 | ❌（持久存储） | ❌          | ❌                          | ❌                      | ✅（重启即失）        |

