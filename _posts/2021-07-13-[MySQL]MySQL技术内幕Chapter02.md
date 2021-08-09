---
title: MySQL技术内幕 InnoDB存储引擎【Chapter02】
date: 2021-07-13
excerpt: "InnoDB的存储引擎系统，关于线程、内存、Checkpoint、Master Thread的实现细节，以及InnoDB五项特性"
categories: Notes
tags: [InnoDB, MySQL, Database]
---



# 2.3 InnoDB架构体系

## 2.3.1 后台进程

> Master Thread

负责将缓冲池数据异步刷新到磁盘，保证数据一致性，脏页的刷新，合并插入缓冲`INSERT BUFFER`，UNDO页回收

> IO Thread

InnoDB 1.0版本之前，包含4个IO Thread，分别是write | read | insert buffer  | log。Linux平台相关线程数不可调整，Windows平台中可以通过`innodb_file_io_threads`调整。InnoDB 1.0.x开始，读写线程分别增加到了4个，使用`innodb_read_io_threads`，`innodb_write_io_threads`区别。

```sql
-- 查看版本
SHOW VARIABLES LIKE 'innodb_version'\G
-- 查看线程数
SHOW VARIABLES LIKE 'innodb_%io_threads'\G
-- 查看线程详情
SHOW ENGINE INNODB STATUS\G
```

> Purge Thread

用于回收commit后undo页的线程，可通过my.ini文件中`innodb_purge_threads`设置，InnoDB 1.1版本中，最大只可设为1，后续版本可以设置更大。

```sql
SHOW VARIABLES LIKE 'innodb_purge_threads'\G
```

> Page Cleaner Thread

脏页刷新操作专用线程，从InnoDB 1.2.x开始引入

## 2.3.2内存

> 缓冲池

缓存的数据页包括：索引页，数据页，undo页，插入缓冲（insert buffer），自适应哈希索引（adaptive hash index），InnoDB锁信息（lock info），数据字典信息（data dictionary）等。

```sql
-- 查看缓冲池大小
SHOW VARIABLES LIKE 'innodb_buffer_pool_size'\G
-- 配置缓冲池实例个数
SHOW VARIABLES LIKE 'innodb_buffer_pool_instances'\G
-- MySQL5.6开始可以通过infomation_schema下变量查看缓冲池
SELECT POOL_ID,POOL_SIZE,FREE_BUFFERS,DATABASE_PAGES 
FROM INNODB_BUFFER_POOL_STATS\G; 
```

> LRU列表

LRU 算法优化：`midpoint insertion strategy`，每次不从首部插入，而是从midpoint插入，midpoint默认放在5/8处，可由参数控制。同时InnoDB会把midpoint后的表称作 old 列表，之前的表为 new 列表。

```sql
-- 查看midpoint位置
SHOW VARIABLES LIKE 'innodb_old_blocks_pct'\G
-- 默认结果为37，代表midpoint在距离页结尾37%(约3/8)处位置
```

页被放在midpoint后，经过一段时间，将会被认为是热点页，放到 new 列表中，这个时间，同样可以设置

```mysql
SET GLOBAL innodb_old_blocks_time=1000;
```

数据库刚启动时，LRU列表为空，所有的页都在Free列表中。当需要时，从Free列表删除并加载到LRU列表，在LRU列表中被LRU算法从 old 列表 刷到 new 列表过程被称为 `page made young`，而因`innodb_old_block_time`未能刷进 new 列表情况被称作 `page not made young`。通过查看InnoDB状态，可以看到LRU列表及Free列表状态和使用情况

```sql
SHOW ENGINE INNODB STATUS\G;
-- 注意Buffer pool hit rate参数，不应当小于95
-- 否则很有可能是因全表扫描引发的LRU列表污染问题
-- 该命令现实的并非数据库当前状态，而是数据库过去一段时间内的状态
```

LRU池一些关键状态也可以使用如下命令查看

```sql
SELECT POOL_ID,HIT_RATE,PAGES_MADE_YOUNG,PAGES_NOT_MADE_YOUNG
FROM information_schema.INNODB_BUFFER_POOL_STATS\G;
```

由于InnoDB 1.0.x开始支持压缩页功能，将16KB的页压缩成 1KB | 2KB | 4KB | 8KB 的格式，并通过专门的页表unzip_LRU列表进行管理，管理方式是通过向LRU申请16KB的页，掰开分给需要存放的1-8KB压缩页，使用的`INNODB_BUFFER_PAGE_LRU`表参见[MySQL 5.7 Doc](https://dev.mysql.com/doc/refman/5.7/en/information-schema-innodb-buffer-page-lru-table.html)。

```sql
-- 查看占用空间为1的页
SELECT TABLE_NAME,SPACE,PAGE_NUMBER,PAGE_TYPE
FROM INNODB_BUFFER_PAGE_LRU WHERE SPACE=1;
-- 查看unzip_LRU表中的页
SELECT TABLE_NAME,SPACE,PAGE_NUMBER,COMPRESSED_SIZE
FROM INNODB_BUFFER_PAGE_LUR
WHERE COMPRESSED_SIZE <> 0;
```

LRU列表中的页被修改后，即称为脏页dirty page，数据库会通过CHECKPOINT机制将脏页刷回磁盘，同时脏页也受Flush列表的管理。但是Flush列表主要是管理将页修改刷回磁盘的操作，并不影响LRU列表管理脏页。Flush列表也可以通过`SHOW ENGINE INNODB STATUS`查看，或者在`INNODB_BUFFER_PAGE_LRU`中寻找脏页：

```sql
SELECT TABLE_BAME,SPACE,PAGE_NUMBER,PAGE_TYPE
FROM INNODB_BUFFER_PAGE_LRU
WHERE OLDEST_MODIFICATION > 0;
```

> redo log缓冲

重做日志缓冲（redo log buffer）适用于缓冲存放redo log的，一般不需要很大，因为通常每秒都会把用户的redo log往磁盘中的redo log刷新一次，缓冲大小默认8MB（实际查询为1MB），此外，在以下三种情况中，才会把缓冲刷回磁盘：

- Master Thread每秒将重做日志缓冲刷新到重做日志文件
- 每个事务提交时，将重做日志缓冲刷新到重做日志文件
- 重做日志缓冲池小于1/2时，重做日志缓冲刷新到重做日志文件

```sql
SHOW VARIABLES LIKE 'innodb_log_buffer_size'\G;
```

# 2.4 Checkpoint技术

InnoDB通过日志序列号(Log Sequence Number, LSN)来标记redo日志版本，从而循环使用redo日志，当出现宕机时，数据库恢复若不需要这部分日志，则这部分redo日志姐已经可以被覆盖重用。LSN是一个8字节数字，单位是字节。每个页都有LSN，redo log、Checkpoint也有LSN，可以通过 `SHOW ENGINE INNODB STATUS`中LOG项查看各项LSN。

Checkpoint分为两种

- sharp checkpoint：关闭数据库时，把所有脏页刷回磁盘
- fuzzy checkpoint：只刷新部分脏页回磁盘

# 2.5 Master Thread

# 2.6 InnoDB关键特性

# 2.7 启动、关闭与恢复