---
title: Redis Introduction Session 01
date: 2021-07-24
excerpt: "[狂神说JAVA系列]中，秦疆关于Redis的解说P1-P27"
categories:
    - Notes
tags:
    - Redis
---



# 阿里巴巴数据架构演进

| 时间      | 大情况         | 技术                                                         |
| --------- | -------------- | ------------------------------------------------------------ |
| 1999      | 第一代网站     | Perl,CGI,Oracle                                              |
| 2000      | 拥抱JAVA       | Java,Servlet                                                 |
| 2001-2004 | EJB时代        | EJB(SLSB,CMP,MDB)<br />Pattern（ServiceLocator，Delegate，DAO，DTO） |
| 2005-2007 | Without EJB    | Spring，iBatis，Webx，Antx<br />iSearch，MQ+ESB，数据挖掘，CMS |
| 2008-2009 | 海量数据       | Memcached、MySQL+数据切分<br />Cobar，分布式，Hadoop，KV，CDN |
| 2010      | 安全镜像       | 安全、镜像、引用服务器升级、NoSQL、SSD                       |
| 2011      | 第五代网站架构 | 敏捷、开放、体验                                             |

## 技术应用

1. 图片存储问题——FastDFS 分布式文件系统
    - 淘宝： TFS
    - Google： GFS
    - Hadoop： HDFS
    - 阿里云： OSS
2. 全文检索问题
    - 淘宝： ISearch
    - 京东： Elasticsearch
3. 文字存储——文档型数据库
    - MongoDB

## 数据架构的复杂性

各类的存储系统的情况

![](\images\redis1-1.png)

解决方案：提供通用数据接口

# NoSQL概述

- KV键值对
    - 新浪：Redis
    - 美团：Redis+Tair
    - 阿里、百度：Redis+memcache
- 文档型数据库 CouchDB\\MongoDB
- 列存储数据库 Cassandra\\HBase\\Riak
- 图形数据库 Neo4J\\InfoGrid\\Infinite Graph

# Redis概述

Remote Dictionary Server，C语言实现，支持网络，基于内存，KV数据库，开源，多种语言API，支持主从复制。

Redis 是一种开源软件（BSD 许可）、内存中数据存储系统。可以用作 **数据库**、**缓存** 和 **消息中间件**。Redis 提供了诸如字符串、散列、列表、集合、带范围查询的排序集合、位图、超级日志、地理空间索引和流等数据结构。Redis 内置复制、Lua 脚本、LRU 驱逐、事务和不同级别的磁盘持久化，并通过 Redis Sentinel 和 Redis Cluster 自动分区提供高可用性。

> Redis is an open source (BSD licensed), in-memory data structure store, used as a database, cache, and message broker. Redis provides data structures such as strings, hashes, lists, sets, sorted sets with range queries, bitmaps, hyperloglogs, geospatial indexes, and streams. Redis has built-in replication, Lua scripting, LRU eviction, transactions, and different levels of on-disk persistence, and provides high availability via Redis Sentinel and automatic partitioning with Redis Cluster.

- 对比memcached优势
    - **Redis 支持更丰富的数据类型（支持更复杂的应用场景）**。Redis 不仅仅支持简单的 k/v 类型的数据，同时还提供 list，set，zset，hash 等数据结构的存储。memcached 只支持最简单的 k/v 数据类型。
    - **Redis 支持数据的持久化，可以将内存中的数据保持在磁盘中，重启的时候可以再次加载进行使用,而 memcached 把数据全部存在内存之中。**
    - **Redis 有灾难恢复机制。** 因为可以把缓存中的数据持久化到磁盘上。
    - **Redis 在服务器内存使用完之后，可以将不用的数据放到磁盘**。但是，memcached 在服务器内存使用完之后，就会直接报异常
    - memcached 没有原生的**集群模式**，需要依靠客户端来实现往集群中分片写入数据；但是 Redis 目前是原生支持 **cluster 模式的**
    - **memcached 是多线程，非阻塞 IO 复用的网络模型**；Redis 使用单线程的多路 IO 复用模型（Redis 6.0 引入了多线程 IO ）
    - Redis 支持发布 **订阅模型、Lua 脚本、事务等功能**，而 memcached 不支持。Redis 支持更多的编程语言
    - memcached过期数据的删除策略只用了**惰性删除**，而 Redis 同时支持**惰性删除与定期删除**

- 性能
    - 条件：测试完成了50个并发执行100000个请求；设置和获取的值是一个256字节字符串；Linux box是运行Linux 2.6,这是X3320 Xeon 2.5 GHz；文本执行使用loopback接口(127.0.0.1)
    - 结果:读的速度是110000次/s,写的速度是81000次/s

- 功能
    - 内存存储、数据持久化（RDB+AOF）
    - 适于告诉缓存
    - 始于发布订阅
    - 地图信息分析
    - 适用于计时器、计数器
- 参考文档
    - [官方网站](https://redis.io/)
    - [Redis中文网站](www.redis.cn)
    - [GitHub Redis项目](https://github.com/redis/redis)
    - [Redis Windows项目](https://github.com/microsoftarchive/redis/releases/tag/win-3.2.100)：官方不推荐在Windows搭建，Windows版本只支持GitHub下载，Windows版本最后一次2016更新

## Redis为什么使用单线程

Redis瓶颈是根据内存决定的，并非CPU。对于内存操作，进行上下文切换（多线程），只会降低QPS，所以使用单线程。从Redis 6.2.x后Redis开始了对多线程的支持，

# 安装Redis

配置文件：`redis.conf`

```shell
# wget
cd /home
mkdir redis
cd ./redis
wget ""

# 解压至opt目录下
tar -zxvf "" -C /opt/redis/
vim /opt/redis/redis.conf

# 安装gcc环境，redis由C编写
yum install -y gcc-c++
cd /opt/redis/
make && make install

# 查看redis安装位置，可以看到6个以redis开头的文件
ls /usr/local/bin

# 复制配置文件作为启动依据
cp /opt/redis/redis.conf /usr/local/bin/redis.self.conf

# redis默认非后台启动，修改配置
# daemonize no -> daemonize yes 
vim redis.self.conf

# 通过指定配置文件启动
/usr/local/bin/redis-server /usr/local/bin/redis.self.conf

# 使用客户端连接，使用shutdown退出
redis-cli -p 6379

# 查看redis进程
ps -ef | grep redis
```

# benchmark性能测试

[benchmark的官方文档](https://redis.io/topics/benchmarks)

> Usage: redis-benchmark [-h <host>] [-p <port>] [-c <clients>] [-n <requests]> [-k <boolean>]
>
> - -h <hostname>      Server hostname (default 127.0.0.1)
>
> - -p <port>          Server port (default 6379)
>
> - -s <socket>        Server socket (overrides host and port)
>
> - -a <password>      Password for Redis Auth
>
> - -c <clients>       Number of parallel connections (default 50)
>
> - -n <requests>      Total number of requests (default 100000)
>
> - -d <size>          Data size of SET/GET value in bytes (default 2)
>
>     - --dbnum <db>       SELECT the specified db number (default 0)
>
> - -k <boolean>       1=keep alive 0=reconnect (default 1)
>
> - -r <keyspacelen>   Use random keys for SET/GET/INCR, random values for SADD
>
>     *Using this option the benchmark will expand the string **rand_int** inside an argument with a 12 digits number in the specified range from 0 to keyspacelen-1. The substitution changes every time a command is executed. Default tests use this to hit random keys in the specified range.*
>
> - -P <numreq>        Pipeline <numreq> requests. Default 1 (no pipeline).
>
> - -q                 Quiet. Just show query/sec values
>
> - --csv              Output in CSV format
>
> - -l                 Loop. Run the tests forever
>
> - -t <tests>         Only run the comma separated list of tests. The test names are the same as the ones produced as output.
>
> - -I                 Idle mode. Just open N idle connections and wait.

```shell
cd /usr/local/bin
redis-server redis.self.conf
redis-benchmark -h localhost -p 6379 -c 100 -n 100000
```

![](\images\redis1-2.png)

- 100000个请求在1.52s内完成
- 100并行用户，3字节载荷
- keep alive表示每次只有一台机器处理请求

# 配置文件分析

```shell
# 查看数据库数目(redis默认有16个数据库)
awk '$1=="databases" {print $2}' redis.self.conf
# 进入redis-ctl后
select $db_id    # 切换数据库
DBSIZE    # 查看数据库条目数
# 查看数据库信息
select 0
keys *
# 清空当前数据库
flushdb
# 清空全部数据库
FLUSHALL
```

# 五种数据类型

## Redis-Key

```shell
set $key $val
get $key
keys *

# 查看key是否存在
EXISTS $key

# 从当前数据库1中移除key
move $key 1

# 设置key过期时间，以s为单位
EXPIRE $key $time

# 查看key过期时间
ttl $key

# 查看key类型
type $key
```

## String类型

使用场景：常规计数器（value除了是字符串，也可以是数字）、统计多单位的数量、计算粉丝数、需要缓存存储的对象（例如token）

```shell
# 追加内容
APPEND $key "appendString"

# 查看字符串长度
STRLEN $key

# 自增、自减命令
incr $key
decr $key
INCRBY $key $step
DECRBY $key $step

# 截取字符串，支持"-1"，闭区间
GETRANGE $key $startIndex $endIndex

# 替换字符串
set $key $newVal
SETRANGE $key $newSubString

# 设置命令
# setex(set with expire)
# setnx(set if not exist)
setex $key $time $val
setnx $notExistKey $val1
# 再次设置时失败
setnx $notExistKey $val2

# 批量操作 mset,mget
mset k1 v1 k2 v2 k3 v3
mget k1 k2 k3
# 由于是原子性操作，下面会设置失败
msetnx k1 v1 k4 v4
# k4 此时是nil的
get k4

# 设置对象 user:{id}:{field}
# 方案1：使用Json字符串设置
set user:1 {name:zhang3,age:25}
# 方案2：分开设置
mset user:1:name zhang3 user:1:age 25
mget user:1:name user:1:age

# getset命令: 先get，再set，适用于update
get db redis    # 返回nil
get db redis1    # 返回"redis"
```

## List类型

可以当作栈、队列，双向队列（阻塞队列）使用

所有队列命令都以L\R开头

```shell
LPUSH $listName $val
RPUSH $listName $val
# 从左向右输出
LRANGE $listName $startIndex $endIndex
LPOP $listName 
RPOP $listName

LINDEX $listName $index
RINDEX $listName $index

# 计算长度只有LLEN，没有LEN和RLEN
LLEN $listName
# 删除某个值，没有RREM
LREM $list $count $val

# 阶段操作trim，将截取结果赋值给原list
LTRIM $list $startIndex $length

# 右侧pop元素，同时插入新列表
RPOPLPUSH $oldList $newList

# update，如果index不存在则报错
LSET $list $index $newVal

# insert，多个oldVal时，以第一个为准
LINSERT $key BEFORE\AFTER $oldVal $newVal
```

使用场景：消息队列，消息排队

操作中间元素的效率小于操作两边元素效率

## SET类型

```shell
# 添加多个元素，返回成功添加个数
# 如果元素已经存在，则无法添加，但不会报错，也不影响同一语句其他元素添加
SADD $setName $val1 $val2
SMEMBERS $setName

# 查看是否存在某元素，存在返回1，否则0
SISMEMBER $setName $val

# 查看set元素个数
SCARD $setName

# 移除set元素
SREM $val

# 随机抽出元素
SRANDMEMBER $setName
SRANDMEMBER $setName $count

# 随机删除元素
SPOP $setName

# 移动某个元素
SMOVE $oldSetName $newSetName $val
```

使用场景：微博中的集合操作，例如：共同关注（需要求交集）、推荐好友（需要求差集）；Linked In二度好友，求二度集合的并集，然后和以关注求差集

```shell
SDIFF $set1 $set2
SINTER $set1 $set2
SUNION $set1 $set2
```

## Hash类型

Map结合，key-map

```shell
# 赋值、取值
HSET $hashSet $field $val
HGET $hashSet $field
HMSET $hashSet $field1 $val1 $field2 $val2
HMGET $hashSet $field1 $field2
HGETALL $hashSet
# 单独获取字段和值
HKEYS $hashSet
HVALS $hashSet

# 删除
HDEL $hashSet $field

# 调整数值
HINCRYBY $hashName $field $step

# 随机返回一个field，默认只返回field
HRANDFIELD $hashName $count [WITHVALUES]

# 查看长度
HLEN $hashSet
# 判断field存在
HEXIST $hashSet $field

# 存在性
HSETNX $hashname $field $val
```

使用场景：

- HSETNX适用于分布式锁
- HASH适合存储对象，以及经常变更信息的存储

## ZSet类型【有序集合】

```shell
ZADD 
ZCARD $key
ZRANGEBYSCORE $field $min $max
```

# 三种特殊数据类型

## Geospatial地理位置

Redis 3.2版本开始添加

## GEOADD 添加位置

> GEOADD key [NX \| XX] [CH] longitude latitude member [longitude latitude member ...]

- 有效范围

    - Valid longitudes are from -180 to 180 degrees.
    - Valid latitudes are from -85.05112878 to 85.05112878 degrees.

- 参数详解

    > - **XX**: Only update elements that already exist. Never add elements.
    > - **NX**: Don't update already existing elements. Always add new elements.
    > - **CH**: Modify the return value from the number of new elements added, to the total number of elements changed (CH is an abbreviation of *changed*).

    Note: The **XX** and **NX** options are mutually exclusive.

- 示例

    ```shell
    GEOADD Sicily 13.361389 38.115556 "Palermo" 15.087269 37.502669 "Catania"
    ```

## GEODIST 计算两个位置距离

```shell
GEODIST Sicily Palermo Catania
```

## GEOHASH 返回一个城市的Hash值
```shell
GEOHASH Sicily Palermo Catania
```

## GEOPOS 返回一个城市位置
```shell
GEOPOS Sicily Palermo Catania
```

## GEORADIUS 返回范围内的节点位置
> - GEORADIUS key longitude latitude radius m\|km\|ft\|mi [WITHCOORD] [WITHDIST] [WITHHASH] [COUNT count [ANY]] [ASC\|DESC] [STORE key] [STOREDIST key]
>
> - GEORADIUSBYMEMBER key member radius m\|km\|ft\|mi [WITHCOORD] [WITHDIST] [WITHHASH] [COUNT count [ANY]] [ASC\|DESC] [STORE key] [STOREDIST key]

`WITHCOORD \ WITHDIST \ WITHHASH`决定了返回信息内容

`COUNT`决定了返回位置数量

`ASC \ DESC`决定了返回顺序是否按距离正序

`STORE \ STOREDIST`决定是否将返回结果存入新的key，以及是否按DIST顺序存储

`GEORADIUSBYMEMBER`可以使用key值作为中心位置

```shell
GEORADIUS Sicily 15 37 200 km COUNT 1 WITHDIST
GEORADIUSBYMEMBER Sicily Agrigento 100 km
```

## GEOSERACH搜索位置

从Redis 6.2版本开始支持，主要是为了支持长方形区域搜索。[使用实例](https://blog.csdn.net/weixin_31499719/article/details/113593620)

> This command extends the [GEORADIUS](https://redis.io/commands/georadius) command, so in addition to searching within circular areas, it supports searching within rectangular areas.

> GEOSEARCH key [FROMMEMBER member] [FROMLONLAT longitude latitude] [BYRADIUS radius m\|km\|ft\|mi] [BYBOX width height m\|km\|ft\|mi] [ASC\|DESC] [COUNT count [ANY]] [WITHCOORD] [WITHDIST] [WITHHASH]

```shell
GEOADD Sicily 12.758489 38.788135 "edge1" 17.241510 38.788135 "edge2"

GEOSEARCH Sicily FROMLONLAT 15 37 BYBOX 400 400 km ASC WITHCOORD WITHDIST
```

==Notes: 所谓矩形，是一个轴平行矩形，是存在于球面上的矩形，这个矩形的中心是你设置中心点，长是 2 * Width，高是2 * Height。==

## GEO与Zset

> GEO底层就是用Zset实现，可以通过Zset命令操作GEO

```shell
ZRANGE Sicily 0 -1
ZREM Sicily Palermo
```

## HyperLogLog

> 基数：不重复的元素数目

Redis统计技术方案：[Hyperloglog算法](https://blog.csdn.net/zanpengfei/article/details/86519324)

Redis统计源码分析：[从算法和源码层面解析Hyperloglog算法](https://zhuanlan.zhihu.com/p/58519480)

相比于转换为Set方法，HyperLogLog要求有一定的容错性（Hash碰撞问题），优点在于需要内存极小且是固定的，只需12KB就可以解决2^64类元素的基数求解问题

- 在 Redis 里面，每个 HyperLogLog 键只需要花费 12 KB 内存，就可以计算接近 2^64 个不同元素的基
    数。

## 应用场景——统计UV

假如我要统计网页的UV（浏览用户数量，一天内同一个用户多次访问只能算一次），传统的解决方案是使用Set来保存用户id，然后统计Set中的元素数量来获取页面UV。但这种方案只能承载少量用户，一旦用户数量大起来就需要消耗大量的空间来存储用户id

我的目的是统计用户数量而不是保存用户，这简直是个吃力不讨好的方案！而使用Redis的HyperLogLog最多需要12k就可以统计大量的用户数，尽管它大概有0.81%的错误率，但对于统计UV这种不需要很精确的数据是可以忽略不计

## PFADD

Redis PFADD 命令将所有元素参数添加到 HyperLogLog 数据结构中

```shell
PFADD mykey a b c d e f g h i j
```

## PFCOUNT

Redis PFCOUNT 命令返回给定 HyperLogLog 的基数估算值

```shell
PFADD hll1 foo bar zap a
PFADD some-other-hll 1 2 3
PFCOUNT hll some-other-hll
```

## PFMERGE

Redis PFMERGE 命令将多个 HyperLogLog 合并为一个 HyperLogLog ，合并后的 HyperLogLog 的基数估算值是通过对所有 给定 HyperLogLog 进行并集计算得出的

```shell
# PFMERGE destkey sourcekey [sourcekey ...]
PFADD hll1 foo bar zap a
PFADD hll2 a b c foo
PFMERGE hll3 hll1 hll2
```

## Bitmaps

## 使用场景——统计用户活跃度

- 在开发中，需要统计用户信息，如活跃或不活跃，登录或者不登录。如需要记录用户一年的打卡情况，打卡了是1， 没有打卡是0，如果使用普通的 key/value存储，则要记录365条记录。如果用户量很大，需要的空间也会很大。
- Redis 提供了 Bitmaps 位图数据结构，Bitmap 就是通过操作二进制位来进行记录，即为 0 和 1。如果要记录 365 天的打卡情况，使用 Bitmaps表示的形式大概如下：0101...，这样好处就是大幅节约内存，365 天相当于 365 bit，又 1 字节 = 8 bit , 所以相当于使用 46 个字节即可。

# Redis 事务

Redis事务本质，就是一组命令的集合，所有的命令都会被序列化，然后放入队列，最后一起执行；Redis单条命令存在原子性，但是事务不保证原子性，也不存在隔离级别的概念；Redis事务支持一次性、顺序性、排他性。

## 事务命令

```shell
# 开启事务
MULTI
set k1 v1
set k2 v2
get k2
# 执行事务
EXEC
```

![](\images\redis1-3.png)

```shell
# 取消事务
DISCARD
```

- 编译型错误：如果代码、命令有错，所有命令都不会执行，例如命令少了一个参数
- 运算时错误：如果事务队列中有语句执行时预计会错误，那么输入exec命令，其他命令还可以继续执行，例如对空值+1

## 监控：乐观锁&悲观锁

悲观锁：先判断，加锁后再修改

乐观锁（CAS, check and set）：先修改，更改Version，写入前再判断Version是否正确

```shell
SET money 100
SET out 0
WATCH money
MULTI
DECRBY money 20
INCRBY out 20
EXEC
```

如果在MULTI开始后，EXEC前，另一个进程修改了money，此时EXEC将执行失败，此时需要`UNWATCH money`，然后重新`WATCH money`，然后再次执行事务。

业务场景：[Redis分布式锁实现秒杀业务(乐观锁、悲观锁)](https://www.cnblogs.com/jasonZh/p/9522772.html)

# P23-P26 PASS

# Redis配置文件

参考博客：[DBA's Record](https://www.cnblogs.com/zhoujinyi/p/13261607.html)

## 网络配置NETWORK

> **Protected Mode**
>
> When protected mode is on and if:
>
> 1) The server is not binding explicitly to a set of addresses using the "bind" directive.
>
> 2) No password is configured.
>
> The server only accepts connections from clients connecting from the IPv4 and IPv6 loopback addresses 127.0.0.1 and ::1, and from Unix domain sockets.

```shell
bing $ip1 $ip2
protected-mode yes
port 6379    # 默认对外端口
```

## 通用配置GENERAL

> `pidfile` 设置 daemonize 选项为 yes 会使 Redis 以守护进程模式启动，在此模式下，Redis 默认会将 pid 写入 /var/run/redis.pid。 可以通过 pidfile 选项修改写入的文件

> `supervised`当你通过 upstart 或者 systemd 运行 Redis 时，Redis 可以和你的 supervision tree 进行交互
>
> - no 无交互
> - upstart 通过向 Redis 发送 SIGSTOP 信号来通知 upstart
> - systemd 通过向 $NOTIFY_SOCKET 写入 READY=1 来通知 systemd
> - auto 通过是否设置了 UPSTART_JOB 或者 NOTIFY_SOCKET 环境变量来决定选项为 upstart 或者 systemd

```shell
daemonize yes    # 守护进程方式运行
supervised no    # 监控模式
pidfile /var/run/redis_6379.pid    # pid记录位置
loglevel notic    # 日志级别 debug/verbose/notice/warning
logfile /var/log/redis/redis-server.log    # 日志存放位置
syslog-enable no    # 是否将日志输出到syslog
syslog-ident redis
syslog-facility local0
databases 16    # 数据库数量
always-show-logo yes    # 开启日志头部是否现实log
```

## 快照设置SNAPSHOTTING

```shell
save 900 1    # 900s 内出现至少一个key被修改，就进行持久化
# 被修改后是否还继续工作
stop-writes-on-bgsave-errors yes
rdbcompression yes    # 是否使用LZO算法压缩持久化到硬盘的string对象
rdbchecksum yes        # 是否开启rdb校验
dbfilename dump.rdb    # RDB文件名
dir /var/lib/redis    # RDB和AOF文件存储位置
```

## 主从设置REPLICATION

```shell
replicaof <masterip> <masterport>
```

## 安全设置SECURITY

```shell
# Command操作
config get requirepass
config set requirepass "123456"    # 此时需要重新登录
auth 123456
# config文件
requirepass foobared
```

## 客户端限制操作CLIENTS

```shell
maxclients 10000    # 设置最大客户端连接数
```

## 内存设置MEMORY MANAGEMENT

内存用尽时的8种策略

| 配置参数        | Description                                                  |
| --------------- | ------------------------------------------------------------ |
| volatile-lru    | Evict using approximated LRU, only keys with an expire set.  |
| allkeys-lru     | Evict any key using approximated LRU.                        |
| volatile-lfu    | Evict using approximated LFU, only keys with an expire set.  |
| allkeys-lfu     | Evict any key using approximated LFU.                        |
| volatile-random | Remove a random key having an expire set.                    |
| allkeys-random  | Remove a random key, any key.                                |
| volatile-ttl    | Remove the key with the nearest expire time (minor TTL).     |
| noeviction      | Don't evict anything, just return an error on write operations. |

```shell
maxmemory <bytes>    # 设置最大可用内存
maxmemory-policy noeviction    # 设置内存用尽策略
```

## AOF设置APPEND ONLY MODE

```shell
appendonly no    # 默认不开启AOF
appendfilename "appednonly.aof"    # AOF文件存储位置
appendfsync everysec    # 同步策略 everysec/no/always
```
