---
title: Redis Introduction Session 02
date: 2021-07-25
excerpt: "[狂神说JAVA系列]中，秦疆关于Redis的解说P28-P36"
categories:
    - Notes
tags:
    - Redis
---



# Redis持久化

## 概念描述

**RDB 是一种类似于快照的方式进行持久化**

原理是他单独 fork 了一个子进程专门去干这件事。可以通过修改配置文件来修改 RDB 的持久化策略。RDB 就是按照定义的策略，定时或者在修改多少次之后来进行数据快照本分，在宕机或者关闭时将数据存入 dump 文件。当 Redis 再次开启时，会自动读取dump文件来恢复数据。RDB 是默认开启的，绝大多数情况下的需求 RDB 是可以满足的。

**AOF 是以一种日志记录的方式来进行持久化的**

他会记录每一次的操作。默认是每秒同步一次。在宕机或者异常情况重启后他会自动恢复。如果AOF文件遭到破坏可以通过一个Redis目录里的`check-aof`的文件来进行修复。AOF方式默认是未开启，需要去配置文件设置`appendonly yes`。

## RDB 与 AOF 的对比

RDB 在效率上明显好于 AOF，但是对数据完整性没有保证。此外，每次save都需要fork进程，需要占用一定内存空间。

AOF 文件默认大小64M当满了之后会重新fork一个子进程来弄个新文件存储。如果同时开启了 RDB 和 AOF。Redis会优先使用 AOF。

![](\images\redis2-3.png)

## 使用场景

购物车数据通常可以使用了cookie与 Redis 共存同步的方式，Redis 也是一定要设置持久化机制的。但是 RDB 不建议使用，RDB持久化方式可能会造成少量数据缺失。所以即使使用 AOF 速度更慢、占用硬盘空间更多，在购物车场景下还是应当使用 AOF。

另外如果是常用的平台的阅读量统计场景，+1操作就无需使用 AOF 来进行持久化。毕竟不是重要数据，把数据保持在一个大概正确范围即可。

## RDB触发机制

- 满足配置文件中的save规则
- `flushall`命令触发RDB产生一个`dump.rdb`文件
- 关闭Redis时，会产生一个`dump.rdb`

使用RDB，只需要将`dump.rdb`文件放到Redis目录下即可，启动时Redis会自动使用，生产环境中，经常备份这个文件。

## AOF文件破坏

破坏`appendonly.aof`后，尝试启动Redis时，就会收到报错

![](\images\redis2-1.png)

```shell
# 如果文件被破坏，可以通过这样方式修复
redis-check-aof --fix appendonly.aof
```

修复后，重新打开即可正常使用

![](\images\redis2-2.png)

# Redis发布订阅

在源码中`pubsub.c`文件中实现，底层维护了一个字典，同时维护了一个保存所有客户端的列表。

- 订阅频道模式 `PSUBSCRIBE pattern [pattern ...]`

    Subscribes the client to the given patterns.

- 发布信息 `PUBLISH channel message`

    Posts a message to the given channel.

    In a Redis Cluster clients can publish to every node. The cluster makes sure that published messages are forwarded as needed, so clients can subscribe to any channel by connecting to any one of the nodes.

- 查看订阅系统信息 `PUBSUB subcommand [argument [argument ...]]`

    The PUBSUB command is an introspection command that allows to inspect the state of the Pub/Sub subsystem. It is composed of subcommands that are documented separately. The general form is:

    ```shell
    PUBSUB <subcommand> <args>
    ```

    - 列出所有可用频道  PUBSUB CHANNELS [pattern]
    - 查看每个频道的订阅人数 `PUBSUB NUMSUB [channel-1 ... channel-N]`
    - 查看当前服务器订阅模式数量 `PUBSUB NUMPAT`

- 取消订阅频道模式 `PUNSUBSCRIBE [pattern [pattern ...]]`

    Unsubscribes the client from the given patterns, or from all of them if none is given.

    When no patterns are specified, the client is unsubscribed from all the previously subscribed patterns. In this case, a message for every unsubscribed pattern will be sent to the client.

- 订阅频道 `SUBSCRIBE channel [channel ...]`

  ![](\images\redis2-4.png)

  Subscribes the client to the specified channels.

  Once the client enters the subscribed state it is not supposed to issue any other commands, except for additional [SUBSCRIBE](https://redis.io/commands/subscribe), [PSUBSCRIBE](https://redis.io/commands/psubscribe), [UNSUBSCRIBE](https://redis.io/commands/unsubscribe), [PUNSUBSCRIBE](https://redis.io/commands/punsubscribe), [PING](https://redis.io/commands/ping), [RESET](https://redis.io/commands/reset) and [QUIT](https://redis.io/commands/quit) commands.

- 取消订阅频道 `UNSUBSCRIBE [channel [channel ...]]`

    Unsubscribes the client from the given channels, or from all of them if none is given.

    When no channels are specified, the client is unsubscribed from all the previously subscribed channels. In this case, a message for every unsubscribed channel will be sent to the client.

# Redis主从复制

配置从库不配置主库

## 环境搭建

```shell
INFO replication    # 查看角色
# 修改配置文件
cp redis.self.conf redis79.conf
cp redis.self.conf redis80.conf
cp redis.self.conf redis81.conf

# 修改 port 6379-6381
# 修改 pidfile '/var/run/redis_6379-6381.pid'
# 修改logfile 'log$id'
# 修改dbfilename 'dump$id.rdb'
```

## 通过命令配置

```shell
# 到主机Redis命令行中
SLAVEOF 127.0.0.1 6379
# 到主从上分别执行
INFO replication
```

## 通过config文件配置

```shell
REPLICAOF <master-ip> <master-port>
MASTERAUTH <master-password>
```

## 读写实验

- 主机可以写，从机只能读
- 未配置哨兵时，主机宕机后，从机依然保持状态
- 主机重启后，从机依然可以获取主机新写的信息
- 从机宕机后，重新上线后，若是通过命令行设置主从，则主从关系失效
- 从机重现连接主机后，master会发一个sync命令，和从机同步所有历史数据
- 当一个从机，被其他从机当作主机，此时就是【层层链路】模型。该节点依然无法修改数据，但是主机的内容，依然可以同步到第二层主机
- 主机断了，使用`SLAVEOF no one`就可以恢复从节点主机身份

## 哨兵模式（自动选取主机）

[Redis Sentinel Documentation](https://redis.io/topics/sentinel)

![](\images\redis2-5.png)

由于哨兵本身也有可能挂掉，所以通常配置多个哨兵，避免出现因为自己网络不通，强制Master下线的问题

![](\images\redis2-6.png)

![](\images\redis2-7.png)

配置`sentinel.conf`

```shell
# 设置监控节点
# sentinel monitor <master-group-name> <ip> <port> <quorum>
sentinel monitor myredis 127.0.0.1 6379 1
```

> The **quorum** is the number of Sentinels that need to agree about the fact the master is not reachable, in order to really mark the master as failing, and eventually start a failover procedure if possible.
>
> However **the quorum is only used to detect the failure**. In order to actually perform a failover, one of the Sentinels need to be elected leader for the failover and be authorized to proceed. This only happens with the vote of the **majority of the Sentinel processes**.

```shell
redis-sentinel /path/to/sentinel.conf
```

主机重新上线后，哨兵会自动将原主机convert为新主机的从机

哨兵的问题在于不许在线扩容，集群容量到达上限后，横向扩容时，需要修改哨兵的配置文件，会较为复杂。

# 缓存穿透与雪崩

详细内容参考[缓存穿透、缓存击穿、缓存雪崩区别和解决方案](https://blog.csdn.net/kongtiao5/article/details/82771694)

## 缓存穿透

【问题描述】缓存穿透是指缓存和数据库中都没有的数据，而用户不断发起请求，如发起为id为“-1”的数据或id为特别大不存在的数据。这时的用户很可能是攻击者，攻击会导致数据库压力过大。

【解决方案】

- 【**布隆过滤器**】接口层增加校验，如用户鉴权校验，id做基础校验，id<=0的直接拦截
- 【**缓存空对象**】从缓存取不到的数据，在数据库中也没有取到，这时也可以将key-value对写为key-null，缓存有效时间可以设置短点，如30秒（设置太长会导致正常情况也没法使用）。这样可以防止攻击用户反复用同一个id暴力攻击

## 缓存击穿

【问题描述】缓存击穿是指缓存中没有但数据库中有的数据（一般是缓存时间到期），这时由于并发用户特别多，同时读缓存没读到数据，又同时去数据库去取数据，引起数据库压力瞬间增大，造成过大压力

【解决方案】

1. 设置热点数据永远不过期。
2. 加分布式互斥锁，给每一个key，同一时间，只有一个线程可以去后台访问数据

## 缓存雪崩

【问题描述】缓存雪崩是指缓存中数据大批量到过期时间（几乎等同于宕机），而查询数据量巨大，引起数据库压力过大甚至down机。和缓存击穿不同的是；缓存击穿指并发查同一条数据，缓存雪崩是不同数据都过期了，很多数据都查不到从而查数据库。

【解决方案】

- 【**Redis高可用**】横向扩容，异地多活

- 【**数据预热**】在正式开始部署前，先从本地把可能需要的数据访问一边，将尽可能多的数据假如缓存；同时缓存数据的过期时间设置随机，防止同一时间大量数据过期现象发生
- 【**限流降级**】缓存失效后，通过加锁、队列来控制读数据库写缓存的线程数量，例如对某个key只允许一个线程查询数据、写缓存、其他等待
- 【**限流降级**】如果缓存数据库是分布式部署，将热点数据均匀分布在不同搞得缓存数据库中（或者在敏感时段，停掉一些次要的服务）
- 设置热点数据永远不过期
