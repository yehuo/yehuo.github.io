---
title: MySQL进阶笔记
date: 2021-07-12
excerpt: "关于InnoDB中事务与锁的实现方案的初步学习"
categories: Notes
tags:
    - MySQL
---



# 1 事务

## 1.1 事务特性

- 原子性 Atomicity：事务作为一个整体被执行，包含在其中的对数据库的操作要么全部被执行，要么都不执行
- 一致性 Consistency：事务应确保数据库的状态从一个一致状态转变为另一个一致状态。一致状态的含义是数据库中的数据应满足完整性约束
- 隔离性 Isolation：多个事务并发执行时，一个事务的执行不应影响其他事务的执行
- 持久性 Durability：已被提交的事务对数据库的修改应该永久保存在数据库中

## 1.2 [特性的实现](https://juejin.cn/post/6945713828470620191)

### 原子性与undo log

通过`undo log`实现，`undo log`是InnoDB存储引擎特有的。具体的实现机制是：将所有对数据的修改（增、删、改）的反操作都写入`undo log`

`undo log`是逻辑日志的一种，可以理解为：记录和事务操作相反的SQL语句，事务执行insert语句，`undo log`就记录delete语句。它以追加写的方式记录日志，不会覆盖之前的日志。除此之外undo log还用来实现数据库多版本并发控制（Multi Version Concurrency Control，简称MVCC）。
 如果一个事务中的一部分操作已经成功，但另一部分操作，由于断电/系统崩溃/其它的软硬件错误而无法成功执行，则通过回溯日志，将已经执行成功的操作撤销，从而达到全部操作失败的目的。

### 持久性与redo log

持久性是通过`redo log`来实现的。`redo log`也是InnoDB存储引擎特有的。具体实现机制是：当发生数据修改（增、删、改）的时候，InnoDB引擎会先将记录写到`redo log`中，并更新内存，此时更新就算完成了。同时InnoDB引擎会在合适的时机将记录刷到磁盘中。
 `redo log`是物理日志，记录的是在某个数据页做了什么修改，而不是SQL语句的形式。它有固定大小，是循环写的方式记录日志，空间用完后会覆盖之前的日志。

### redo log 与 undo log 存储机制

`undo log`和`redo log`并不是直接写到磁盘上的，而是先写入`log buffer`。再等待合适的时机同步到`OS buffer`，再由操作系统决定何时刷到磁盘，具体过程如下：

![logbuffer](\images\logbuffer.PNG)

`undo log`和`redo log`都是从`log buffer` 到 `OS buffer`，再到磁盘。所以中途还是有可能因为断电/硬件故障等原因导致日志丢失。为此MySQL提供了三种持久化方式：

这里有一个参数`innodb_flush_log_at_trx_commit`，这个参数主要控制`InnoDB`将`log buffer`中的数据写入`OS buffer`，并刷到磁盘的时间点，取值分别为0，1，2，默认是1。如下图所示：

![innodbflushlog](\images\innodbflushlog.PNG)

### crash recovery

数据库系统崩溃后重启，此时数据库处于不一致的状态，必须先执行一个`crash recovery`的过程：首先读取`redo log`，把成功提交但是还没来得及写入磁盘的数据重新写入磁盘，保证了持久性。再读取`undo log`将还没有成功提交的事务进行回滚，保证了原子性。`crash recovery`结束后，数据库恢复到一致性状态，可以继续被使用。

### 隔离性与五类读取故障

- 第一类丢失更新：事务A在撤销的时候，覆盖了事务B已提交的更新数据。
- 脏读：事务A读到了事务B未提交的更新数据。
- 幻读：事务A读到了事务B已提交的新增数据。
- 不可重复读：事务A读到了事务B已提交的更新数据。
- 第二类丢失更新：事务A在提交的时候，覆盖了事务B已提交的更新数据。

### 隔离性与四种隔离级别

- **Serializable（串行化）** ：事务之间以一种串行的方式执行，安全性非常高，效率低
- **Repeatable Read（可重复读）** ：是MySQL默认的隔离级别，同一个事务中相同的查询会看到同样的数据行，安全性较高，效率较好
- **Read Committed（读已提交）** ：一个事务可以读到另一个事务已经提交的数据，安全性较低，效率较高
- **Read Uncommitted（读未提交）** ：一个事务可以读到另一个事务未提交的数据，安全性低，效率高

| 隔离级别         | 是否出现第一类丢失更新 | 是否出现脏读 | 是否出现虚读 | 是否出现不可重复读 | 是否出现第二类丢失更新 |
| ---------------- | ---------------------- | ------------ | ------------ | ------------------ | ---------------------- |
| Serializable     | 否                     | 否           | 否           | 否                 | 否                     |
| Repeatable Read  | 否                     | 否           | 是           | 否                 | 否                     |
| Read Committed   | 否                     | 否           | 是           | 是                 | 是                     |
| Read Uncommitted | 否                     | 是           | 是           | 是                 | 是                     |

### SELECT 与 Snapshot Read

`Repeatable Read`是MySQL默认的隔离级别，也是使用最多的隔离级别，理论上`Repeatable Read`无法解决幻读问题。但是MySQL可以解决。

首先创建一个表并插入一条记录：

```sql
CREATE TABLE `student` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `stu_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '学生学号',
  `stu_name` varchar(100) DEFAULT NULL COMMENT '学生姓名',
  `created_date` datetime NOT NULL COMMENT '创建时间',
  `modified_date` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  `ldelete_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '逻辑删除标志，0：未删除，2：已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='学生信息表';

INSERT INTO `student` VALUES (1, 230160340, 'Carson', '2016-08-20 16:37:00', '2016-08-31 16:37:05', 0);
```

假设AB两个事务按如下进程操作：

| Time | 事务A                 | 事务B                 |
| ---- | --------------------- | --------------------- |
| T1   | SELECT * FROM student |                       |
| T2   |                       | INSERT INTO new value |
| T3   |                       | COMMIT                |
| T4   | SELECT * FROM student |                       |

此时A是不会出现幻读的，因为MySQL的事务开始时，第一条 SELECT 语句查询结果集会生成一个快照（`snapshot`），并且这个事务结束前，同样的 SELECT 语句返回的都是这个快照的结果，而不是最新的查询结果，这就是MySQL在`Repeatable Read`隔离级别对普通 SELECT 语句使用的**快照读**(`snapshot read`)。

MVCC是多版本并发控制，快照就是其中的一个版本。所以可以说**MVCC实现了快照读**，具体的实现方式涉及到MySQL的隐藏列。MySQL会给每个表自动创建三个隐藏列：

| COLUMNS       | DETAILS                                                      |
| ------------- | ------------------------------------------------------------ |
| `DB_TRX_ID`   | 事务ID，记录操作（增、删、改）该数据事务的事务ID             |
| `DB_ROLL_PTR` | 回滚指针，记录上一个版本的数据在`undo log`中的位置           |
| `DB_ROW_ID`   | 隐藏ID ，创建表没有合适的索引作为聚簇索引时，会用该隐藏ID创建聚簇索引 |

由于`undo log`中记录了各个版本的数据，并且通过`DB_ROLL_PTR`可以找到各个历史版本，并且由`DB_TRX_ID`决定使用哪个版本（快照）。所以相当于`undo log`实现了MVCC，MVCC实现了快照读。

### UPDATE \| INSERT  \| DELETE 与 GAP LOCK

相比于 SELECT 语句的快照读(snapshot read)， UPDATE | INSERT | DELETE  都是使用当前读(current read)的，为了验证，可以做如下实验：

| Time | 事务A                 | 事务B                  |
| ---- | --------------------- | ---------------------- |
| T1   | SELECT * FROM student |                        |
| T2   |                       | INSERT INTO NEW_COLUMN |
| T3   |                       | COMMIT                 |
| T4   | UPDATE NEW_COLUMN     |                        |
| T5   | SELECT * FROM student |                        |

事务A此时不仅可以成功更新 UPDATE 事务B插入的新行，最后一次 SELECT 还可以看到更新后新行（此时事务A中已出现幻读）。

### `Repeatable Read`隔离级别解决幻读问题的方案

`Repeatable Read`是通过`Gap Lock`来解决的。InnoDB是支持行锁的，并且行锁是锁住索引。而`Gap Lock`用来锁定索引记录间隙，确保索引记录的间隙不变。间隙锁是针对事务隔离级别为`Repeatable Read`或以上级别而设的，`Gap Lock`和行锁一起组成了`Next-Key Lock`。

当InnoDB扫描索引记录的时候，会首先对索引记录加上行锁，再对索引记录两边的间隙加上`Gap Lock`。加上`Gap Lock`之后，其他事务就不能在这个间隙插入记录。这样就有效的防止了幻读的发生。

默认情况下，InnoDB工作在`Repeatable Read`的隔离级别下，并且以`Next-Key Lock`的方式对索引行进行加锁。当查询的索引具有唯一性（主键、唯一索引）时，InnoDB存储引擎会对`Next-Key Lock`进行优化，将其降为行锁，仅仅锁住索引本身，而不是范围（除非锁定不存在的值）。若是普通索引，则会使用`Next-Key Lock`将记录和间隙一起锁定。

### **Locking Reads** 通过读锁实现限定不同隔离级别

If you query data and then insert or update related data within the same transaction, the regular SELECT statement does not give enough protection. Other transactions can update or delete the same rows you just queried. InnoDB supports two types of locking reads that offer extra safety:

**SELECT ... LOCK IN SHARE MODE**

Sets a shared mode lock on any rows that are read. Other sessions can read the rows, but cannot modify them until your transaction commits. If any of these rows were changed by another transaction that has not yet committed, your query waits until that transaction ends and then uses the latest values.

**SELECT ... FOR UPDATE | DELETE | INSERT**

For index records the search encounters, locks the rows and any associated index entries, the same as if you issued an UPDATE statement for those rows. Other transactions are blocked from updating those rows, from doing SELECT ... LOCK IN SHARE MODE, or from reading the data in certain transaction isolation levels. Consistent reads ignore any locks set on the records that exist in the read view. (Old versions of a record cannot be locked; they are reconstructed by applying undo logs on an in-memory copy of the record.)

### 小结

```sql
-- 使用snapshot read的语句
SELECT * FROM students
-- 使用current read的语句
SELECT * FROM ... lock in share mode
SELECT * FROM ... for update
INSERT INTO table ...
UPDATE table SET ...
DELETE table WHERE ...
```

## 1.3 做实验需要的知识

### InnoDB锁状态监控

四种锁状态监控方案参见[博客](https://www.cnblogs.com/wangdong/p/9235249.html)。InnoDB主要提供的四类监控，四类监控都可以用基于表和基于系统参数两种方式开启，但是基于表的开启方式将会被废弃，不在此说明。

- 标准监控(Standard InnoDB Monitor)：监视活动事务持有的表锁、行锁；事务锁等待；线程信号量等待；文件IO请求；buffer pool统计信息；InnoDB主线程purge和change buffer merge活动。
- 锁监控(InnoDB Lock Monitor)：提供额外的锁信息。
- 表空间监控(InnoDB Tablespace Monitor)：监控共享表空间中的文件段以及表空间数据结构配置验证。
- 表监控(InnoDB Table Monitor)：监控内部数据字典的内容。

表空间监控和表监控都会在后续被废弃，不在此说明。

> **Standard InnoDB Monitor** & **InnoDB Lock Monitor**

二者都是基于系统参数：`innodb_status_output`控制，自MySQL 5.6.16版本之后，可以通过设置系统参数(`innodb_status_output`)的方式开启或者关闭标准监控。

```sql
-- 数据库监控的信息全部记录到 err log
-- 为避免日志增长过快，默认是关闭的
set GLOBAL innodb_status_output=ON;
set GLOBAL innodb_status_output_locks=ON;
```

### 查看系统锁的方法

- 实验细节参见[B站马士兵教程](https://www.bilibili.com/video/BV1E44y1B77X?p=8)
- 实验流程参见[CSDN博客](https://blog.csdn.net/byamao1/article/details/81612647)

```SQL
SET GLOBAL innodb_status_output_locks=1
SHOW ENGINE INNODB STATUS\G
```

# 2 InnoDB特性

关于InnoDB四种特性的初步了解参见[CSDN博客](https://www.cnblogs.com/zhs0/p/10528520.html)

## 2.1 插入缓冲 insert buffer

插入缓冲（Insert Buffer/Change Buffer）：提升插入性能，change buffering是insert buffer的加强，insert buffer只针对insert有效，change buffering对insert、delete、update(delete+insert)、purge都有效

只对于非聚集索引（非唯一）的插入和更新有效，对于每一次的插入不是写到索引页中，而是先判断插入的非聚集索引页是否在缓冲池中，如果在则直接插入；若不在，则先放到Insert Buffer 中，再按照一定的频率进行合并操作，再写回disk。这样通常能将多个插入合并到一个操作中，目的还是为了减少随机IO带来性能损耗

## 2.2 二次写入 double write

DoubleWrite缓存是位于系统表空间的存储区域，用来缓存InnoDB的数据页从InnoDB buffer pool中flush之后并写入到数据文件之前，所以当操作系统或者数据库进程在数据页写磁盘的过程中崩溃，InnoDB可以在DoubleWrite缓存中找到数据页的备份而用来执行crash恢复。数据页写入到DoubleWrite缓存的动作所需要的IO消耗要小于写入到数据文件的消耗，因为此写入操作会以一次大的连续块的方式写入

## 2.3 自适应哈希索引 adaptive hash index

可以通过`innodb_adaptive_hash_index`参数开启，或通过`skip innodb_adaptive_hash_index`命令关闭。当满足以下条件时，InnoDB会将数据项判断为热点数据，并为之建立Hash索引：

- 索引是否被访问了17次

- 索引中的某个页已经被访问了100次

- 访问模式必须相同索引是否被访问了17次

	2.索引中的某个页已经被访问了100次

	3.访问模式必须是一样的，`where a = xxx`和`where a = xxx and b = xxx`属于不同的访问模式

## 2.4 预读 read ahead

首先了解MySQL中的数据结构 `extent（区）`和`page（页）`，参见博客[《MySQL InnoDB 逻辑存储结构》](https://www.cnblogs.com/wilburxu/p/9429014.html)

- 线性预读 linear read-ahead

	如果一个extent中被顺序读取的page超过某个数值时，InnoDB将会异步提前将下一个extent读入buffer pool。这个数值由 `innodb_read_ahead_threshold`设置，未设置时，只有读取到extent中最后一个page，才会将下一个extent放入buffer pool。

- 随机预读random read-ahead

	当同一个extent中的一些page在buffer pool中被发现时，InnoDB将会该extent中剩余的page一起读入。但是出于这种方法不稳定性的考虑，该方法已经在MySQL5.5中被废弃，可以通过 `innodb_random_read_ahead`来打开随机预读。

# 3 杂项

SQL语句执行顺序：

> FROM -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY -> LIMIT 



