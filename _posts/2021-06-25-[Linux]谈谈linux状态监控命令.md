---
title: 谈谈Linux状态监控命令
date: 2021-06-25
excerpt: "从磁盘、内存、CPU角度谈谈Linux常用监控命令"
categories: Blog
tags: [Linux]
---

# 谈谈Linux状态监控命令

### 磁盘

### 内存

#### 进程分析

##### Linux中进程的5种状态

- 运行(正在运行或在运行队列中等待)
- 中断(休眠中, 受阻, 在等待某个条件的形成或接受到信号)
- 不可中断(收到信号不唤醒和不可运行, 进程必须等待直到有中断发生)
- 僵死(进程已终止, 但进程描述符存在, 直到父进程调用wait4()系统调用后释放)
- 停止(进程收到SIGSTOP, SIGSTP, SIGTIN, SIGTOU信号后停止运行运行)

##### 5种状态码

- D 不可中断 uninterruptible sleep (usually IO)
- R 运行 runnable (on run queue)
- S 中断 sleeping
- T 停止 traced or stopped
- Z 僵死 a defunct (”zombie”) process

#### 查看内存的方法

- `top`
- `free`
- `cat /pro/meminfo`
- `ps aux --sort -rss`

- `**vmstat -s**`
- `**gnome-shell-system-monitor-applet**`

### CPU