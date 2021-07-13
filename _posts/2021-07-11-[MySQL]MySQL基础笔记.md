---
title: MySQL基础笔记
date: 2021-07-11
excerpt: "【狂神说JAVA系列】中，秦疆关于MySQL系列的讲解"
categories: Notes
tags: MySQL
---

# MySQL基础笔记

- [B站狂神说JAVA系列](https://www.bilibili.com/video/BV1NJ411J79W)，评论区有原始代码可供参考
- [视频原始官网](www.kuangstudy.com)，有一些用户笔记可供参考

## 1 SQL语句

SQL语句分类

- DQL（数据查询语言）: 查询语句，凡是select语句都是DQL
- DML（数据操作语言）：insert delete update，对表当中的数据进行增删改
- DDL（数据定义语言）：create drop alter，对表结构的增删改
- TCL（事务控制语言）：commit提交事务，rollback回滚事务(TCL中的T是Transaction)
- DCL（数据控制语言）: grant授权、revoke撤销权限等

## 2 操作数据库

### 2.4 根据已有数据库查看新建数据库代码

```sql
SHOW CREATE DATABASE school
SHOW CREATE TABLE student
DESC student -- 显示表结构
```

### 2.5 数据表类型

| Function   | MyISAM               | InnoDB        |
| ---------- | -------------------- | ------------- |
| 事务支持   | 不支持               | 支持          |
| 数据行锁定 | 不支持（仅支持表锁） | 支持          |
| 外键约束   | 不支持               | 支持          |
| 全文索引   | 支持                 | 不支持        |
| 表空间大小 | 较小                 | 较大，约为2倍 |

#### 常规使用操作

- MyISAM(MySQL 5.1以前默认)：节约空间，速度较快

- InnoDB：安全性高，事务处理，支持多表多用户操作

#### 数据表所在位置

所有数据库文件都存在data目录下

- InnoDB：`*.frm`文件以及上级目录（或本级）的`*.ibd`或`*.ibdata1`文件

- MyISAM：

	- `*.frm` 表结构定义文件
	- `*.MYD` 数据文件
	- `*.MYI` 索引文件 index

- 设立数据库字符集编码(https://www.jianshu.com/p/ec0c86ee3e04)

	- 建库时添加

		```sql
		CHARSET=utf8
		```

	- 在`my.ini`配置默认编码

		```sql
		character-set-server=utf-8
		```

	- 字符集比较设置`COLLATE`(https://blog.csdn.net/weixin_34832150/article/details/113338337)

		```sql
		CREATE DATABASE shop CHARSET SET utf8 COLLATE utf_8_general_ci
		```

### 2.6 修改删除表

注意`MODIFY`和`CHANGE`的区别：

- `CHANGE`可以更改 **列名** 和 **列属性** （每次都要把新列名和旧列名写上，即使两个列名没有更改，只是改了类型）
- `MODIFY`只能更改 **列属性** ，只需要写一次 **列名** ，比`CHANGE`简单

```sql
-- 修改表名:ALTER TABLE 旧表情
ALTER TABLE teacher RENAME AS teacher1
-- 增加表字段
ALTER TABLE teacher ADD age INT(11)

-- 修改表字段
-- ALTER TABLE 表名 MODIFY 字段名 列属性[]
ALTER TABLE teacher1 MODIFY age VARCHAR(11)
-- ALTER TABLE 表名 CHANGE 旧名字 新名字 列属性[]
ALTER TABLE teacher1 CHANGE age age1 INT(11)

-- 删除表字段 ALTER TABLE 表名 DROP 字段名
ALTER TABLE teacher1 DROP age1

-- 删除表
DROP TABLE teacher1 IF EXISTS
```

## 3 MySQL数据管理

### 3.1 外键

学生表的`gradeid`字段要去引用年级的`gradeid`字段时，定义外键key，给这个外键添加约束（执行引用）

```sql
-- 创建学生表时，添加如下外键语句
KEY `FK_gradeid` (`gradeiD`),
CONSTRAINT `FK_gradeid` FOREIGN KEY (`gradeid`) REFERENCES `grade`(`gradeid`)
-- 用语句添加外键
-- ALTER TABLE 表名 ADD CONSTRAINT 约束名 FOREIGN KEY (外键列) REFERENCES 哪个表(哪个字段)
ALTER TABLE `student`
ADD CONSTRAINT `FK_gradeid` FOREIGN KEY(`gradeid`) REFERENCES `grade`(`gradeid`)
```

以上都是物理外键，为避免数据库级别的外键过多造成困扰，一般不作为业务使用。实际过程中使用多张表的外键，都会用程序去实现。

### 3.5 删除

delete和truncate区别：

- truncate自增会归零
- delete删除后
	- InnoDB 断电后重新从0开始自增
	- MYISAM 即使断电后也会继续从上一个自增量开始

## 4 DQL查询

### 4.2 查询制定字段

表达式官方文档(https://dev.mysql.com/doc/refman/5.7/en/built-in-function-reference.html)

```sql
SELECT VERSION()	-- 查询系统版本函数
SELECT 100*3-1 AS 计算结果	-- 用于计算：表达式
SELECT @@auto_increament_increment	-- 查询自增步长：变量
```

### 4.3 where

通配符：

- %：匹配无限个字符

- _：匹配一个字符

	```sql
	SELECT `student` FROM student WHERE student LIKE '刘__'
	```

### 4.4 联表查询

- [七种join理论](https://blog.csdn.net/Assassinhanc/article/details/92678759)

![7join](/images/7join.png)

- 自联结查询

	```sql
	CREATE TABLE `school`.`category`( 
	    `categoryid` INT(3) NOT NULL COMMENT id, 
	    `pid` INT(3) NOT NULL COMMENT 父id 没有父则为1, 
	    `categoryname` VARCHAR(10) NOT NULL COMMENT 种类名字, 
	    PRIMARY KEY (`categoryid`) 
	) ENGINE=INNODB CHARSET=utf8 COLLATE=utf8_general_ci; 
	
	INSERT INTO `school`.`category` (`categoryid`, `pid`, `categoryname`) VALUES (2, 1, 信息技术);
	INSERT INTO `school`.`category` (`categoryid`, `pid`, `categoryname`) VALUES (3, 1, 软件开发);
	INSERT INTO `school`.`category` (`categoryid`, `PId`, `categoryname`) VALUES (5, 1, 美术设计);
	INSERT INTO `School`.`category` (`categoryid`, `pid`, `categoryname`) VAlUES (4, 3, 数据库); 
	INSERT INTO `school`.`category` (`categoryid`, `pid`, `categoryname`) VALUES (8, 2, 办公信息);
	INSERT INTO `school`.`category` (`categoryid`, `pid`, `categoryname`) VALUES (6, 3, web开发); 
	INSERT INTO `school`.`category` (`categoryid`, `pid`, `categoryname`) VALUES (7, 5, ps技术);
	
	-- 需要同时现实父子id的名称，需要通过表内自联结结合pid和categoryid内容
	SELECT a.`categoryName` AS 'parent categories', b.`categoryName` AS 'son categories'
	FROM `category` AS a, `category` AS b
	WHERE a.`categoryid`=b.`pid`
	```

### 4.5 分页与排序

```sql
LIMIT STARTID, ENDID
```

## 5 MySQL函数

### 5.2 聚合函数

```sql
SELECT COUNT(*) FROM student
SELECT COUNT(1) FROM student
-- 用1代表列，速度最快
SELECT COUNT(`BornDate`) FROM student
-- 会忽视列中的null值
```

### 5.3 数据库级别的MD5加密

```sql
-- 修改已有明文数据库
UPDATE testmd5 SET pwd=MD5(pwd)
```

## 6 事务

核心：将一组SQL放在同一个批次执行，要么都成功，要么都失败

### 6.1 ACID原则

- 原子性 Atomicity：一起成功或者一起失败
- 一致性 Consistency：【最终一致性】某一属性在操作前后不变，例如转账中，现金总和
- 隔离性 Isolation：多个用户同时操作，排除其他事务对本事务影响
- 持久性 Durability：事务结束后的数据不随着外界原因导致数据丢失，事务没有提交，则回复原状。事务一旦提交，就不可逆。

### 6.2 出现的问题

- 脏读：一个事务读取了另外事务未提交的数据
- 不可重复读：在一个事务内，同一个数据项，两次读取结果不一致
- 幻读（虚读）：在一个事务内读到了其他事务新插入的数据，导致同一个事务内两次查询不一致

```sql
-- 关闭自动提交每个sql，默认是开启状态
SET autocommit=0

-- 标记一个事务的开始从这之后的内容都在一个事务中
START TRANSACTION

-- 相关功能
COMMIT		-- 提交事务
ROLLBACK	-- 回滚到指定保存点
SAVEPOINT savepoint_name	-- 指定保存点
ROLLBACK SAVEPOINT savepoint_name	-- 回滚到某个保存点 
RELEASE SAVEPOINT savepoint_name	-- 删除某个保存点
```

### 6.3 事务实例

```sql
SET AUTOCOMMIT=0;
START TRANSACTION
UPDATE account SET money=money-500 WHERE `name`='A'
UPDATE account SET money=money+500 WHERE `name`='B'
COMMIT;
ROLLBACK;
SET AUTOCOMMIT=1;
```

## 7 索引

### 7.1 索引分类

- 主键索引 PRIMARY KEY

- 唯一索引 UNIQUE KEY：避免重复的列，可以给多个列定义

- 常规索引 KEY/INDEX

	```sql
	CREATE INDEX `idx_app_user_name` ON app_user(`name`)
	```

- 全文索引 FULLTEXT

	```sql
	ALTER TABLE school.student ADD FULLTEXT INDEX `studentName`(`studentName`)
	```

### 7.2 数据结构及算法原理

#### MySQL分析诊断工具学习

- 利用Explain语句分析查询过程
- 利用`PERFORMANCE_SCHEMA`表和`profiles`监控数据库运行状态

#### 利用Explain分析查询过程

- 参考资料(https://blog.csdn.net/jiadajing267/article/details/81269067)

- 官方文档(https://dev.mysql.com/doc/refman/5.7/en/explain-output.html)

- 结果表项解释

	- `type`：显示联结类型，显示查询使用了何种类型，按照从最佳到最坏类型排序，一般保证查询至少达到range级别，最好能达到ref

		| Output | Explanation                                                  |
		| ------ | ------------------------------------------------------------ |
		| system | 表中仅有一行（=系统表）这是const联结类型的一个特例           |
		| const  | 表示通过索引一次就找到，const用于比较primary  key或者unique索引。因为只匹配一行数据，所以如果将主键置于where列表中，mysql能将该查询转换为一个常量 |
		| eq_ref | 唯一性索引扫描，对于每个索引键，表中只有一条记录与之匹配。常见于唯一索引或者主键扫描 |
		| ref    | 非唯一性索引扫描，返回匹配某个单独值的所有行，本质上也是一种索引访问，它返回所有匹配某个单独值的行，可能会找多个符合条件的行，属于查找和扫描的混合体 |
		| range  | 只检索给定范围的行，使用一个索引来选择行。key列显示使用了哪个索引，一般就是where语句中出现了between,in等范围的查询。这种范围扫描索引扫描比全表扫描要好，因为它开始于索引的某一个点，而结束另一个点，不用全表扫描 |
		| index  | index 与all区别为index类型只遍历索引树。通常比all快，因为索引文件比数据文件小很多 |
		| all    | 遍历全表以找到匹配的行                                       |

	- `extra`：包含不适合在其他列中显示，但是十分重要的额外信息

		| Output                       | Explanation                                                  |
		| ---------------------------- | ------------------------------------------------------------ |
		| Using filesort               | 说明mysql会对数据适用一个外部的索引排序。而不是按照表内的索引顺序进行读取。MySQL中无法利用索引完成排序操作称为“文件排序” |
		| Using temporary              | 使用了临时表保存中间结果，mysql在查询结果排序时使用临时表。常见于排序order by和分组查询group by |
		| Using index                  | 表示相应的select操作用使用覆盖索引，避免访问了表的数据行。如果同时出现using  where，表名索引被用来执行索引键值的查找；如果没有同时出现using where，表名索引用来读取数据而非执行查询动作 |
		| Using where                  | 表明使用where过滤                                            |
		| using join buffer            | 使用了连接缓存                                               |
		| impossible where             | where子句的值总是false，不能用来获取任何元组                 |
		| select tables optimized away | 在没有group  by子句的情况下，基于索引优化Min、max操作或者对于MyISAM存储引擎优化count（*），不必等到执行阶段再进行计算，查询执行计划生成的阶段即完成优化 |
		| distinct                     | 优化distinct操作，在找到第一匹配的元组后即停止找同样值的动作 |

	- `key`：显示MySQL实际决定使用的键(索引)。如果没有选择索引,键是NULL。查询中如果使用覆盖索引，则该索引和查询的select字段重叠。
	- `rows`：根据表统计信息以及索引选用情况，大致估算出找到所需的记录所需要读取的行数

#### 利用`PERFORMANCE_SCHEMA`和`profile`监控数据库运行状态

- `PERFORMANCE_SCHEMA`表的查看方式
	- [MySQL 5.7 Reference Manual](https://dev.mysql.com/doc/refman/5.7/en/innodb-information-schema.html)
	- [使用方法](https://www.cnblogs.com/duanxz/p/3757511.html)

- 使用`SHOW PROFILE`查看单条SQL语句的开销，参考[《使用show profiles分析SQL性能》](https://www.cnblogs.com/duanxz/archive/2013/01/23/2872537.html)

	这种方式将从MySQL 5.6.7开始被移除，了解即可。通过这种方式，可以查看单条SQL语句执行的块IO相关开销、CPU相关开销、内存相关开销等几类开销。

	```sql
	--  查看profile功能是否开启
	SHOW VARIABLES LIKE "%pro%";
	-- 开启profile功能
	SET profiling=1;
	-- 查看profile参考
	HELP PROFILE;  
	-- 查看近期执行的语句
	SHOW PROFILES;
	-- 查看其中某一条的执行开销
	SHOW PROFILE FOR QUERY query_id;
	-- 查看Query 2的CPU开销
	SHOW PROFILE cpu FOR QUERY 2
	```

#### 索引数据结构分析

主要内容来源是一篇很精细的Blog[《MySQL索引背后的数据结构及算法原理》](http://blog.codinglabs.org/articles/theory-of-mysql-index.html)，建议一次读完

索引本身也很大，不可能全部存储在内存中，因此索引往往以索引文件的形式存储的磁盘上。这样的话，索引查找过程中就要产生磁盘I/O消耗，相对于内存存取，I/O存取的消耗要高几个数量级，所以评价一个数据结构作为索引的优劣最重要的指标就是在查找过程中磁盘I/O操作次数的渐进复杂度。换句话说，索引的结构组织要尽量减少查找过程中磁盘I/O的存取次数。

##### B-Tree

![B-Tree](/images/B-Tree.png)

- B-树特性（d为度，h为高度）
	- 每个非叶子节点由n-1个key和n个指针组成，其中d<=n<=2d
	- 每个叶子节点最少包含一个key和两个指针，最多包含2d-1个key和2d个指针，叶节点的指针均为null
	- **所有叶节点具有相同的深度，等于树高h**
	- **key和指针互相间隔，节点两端是指针**
	- **一个节点中的key从左到右非递减排列**

##### B+Tree

![B+Tree](/images/B+Tree.png)

- B+树特性
	- 每个节点的指针上限为2d而不是2d+1。
	- 内节点不存储data，只存储key
	- 叶子节点不存储指针

B+Tree中叶节点和内节点一般大小不同。这点与B-Tree不同，虽然B-Tree中不同节点存放的key和指针可能数量不一致，但是每个节点的域和上限是一致的。B+Tree比B-Tree更适合实现外存储索引结构。

B+Tree基础上，为相邻叶子节点添加指针，即可增加区间查询效率。

![B+Plu](/images/B+Plu.png)

##### B-Tree数据结构优势（相对于HashTable、BST、AVL、红黑树）

- 其他数据劣势

	- HashTable：hash碰撞问题，和数据无序问题导致不支持范围查找。memory引擎支持了hash索引，InnoDB支持`Adaptive Hash Index`，参见[InnoDB四大特性](https://www.cnblogs.com/zhs0/p/10528520.html)

	- BT | BST | AVL | 红黑树：都是二叉树，所以树高较高，查询复杂度较高；范围查询时，会出现自旋问题；BT | BST 二者不平衡，性能不均衡；BT 无序，同HashTable。

		| Name                    | CN Name    |
		| ----------------------- | ---------- |
		| BT-Binary Tree          | 二叉树     |
		| BST-Binary Search Tree  | 二叉搜索树 |
		| AVT-Adelson-Velsky Tree | 二叉查找树 |
		| RBT-Red Black Tree      | 红黑树     |

- B-Tree 优势

  数据库系统的设计者巧妙利用了磁盘预读原理，将一个节点的大小设为等于一个页，这样每个节点只需要一次I/O就可以完全载入。为了达到这个目的，在实际实现B-Tree还需要使用如下技巧：

  每次新建节点时，直接申请一个页的空间，这样就保证一个节点物理上也存储在一个页里，加之计算机存储分配都是按页对齐的，就实现了一个node只需一次I/O。

  B-Tree中一次检索最多需要h-1次I/O（根节点常驻内存），渐进复杂度为$ O(h)=O(log_dN)$

  
    一般实际应用中，出度d是非常大的数字，通常超过100，因此h非常小（通常不超过3，**3-4层即可支持超过千万级别数据查找**）
  
- B+Tree优势

  B+Tree更适合外存索引，原因和内节点出度d有关。从上面分析可以看到，d越大索引的性能越好，而出度的上限取决于节点内key和data的大小：
  $$
  d_{max}=floor(pagesize/(keysize+datasize+pointsize))
  $$
  
  
  floor表示向下取整。由于B+Tree内节点去掉了data域，因此可以拥有更大的出度，拥有更好的性能。

#### InnoDB中的B+Tree实现

InnoDB也使用B+Tree作为索引结构，但具体实现方式却与MyISAM截然不同。

- 聚簇索引与非聚簇索引

	聚簇索引，是指索引与数据存放在一起的索引方式。非聚簇索引，是指索引同数据分开存储的索引方式。MyISAM仅包含非聚簇索引，InnoDB既包含聚簇索引，也包含非聚簇索引。

- 数据存放方式不同

	第一个重大区别是InnoDB的数据文件本身就是索引文件。MyISAM索引文件和数据文件是分离的，索引文件仅保存数据记录的地址。而在InnoDB中，表数据文件本身就是按B+Tree组织的一个索引结构，这棵树的叶节点data域保存了完整的数据记录。这个索引的key是数据表的主键，因此InnoDB表数据文件本身就是主索引。

	因为InnoDB的数据文件本身要按主键聚集，所以InnoDB要求表必须有主键（MyISAM可以没有），如果没有显式指定，则MySQL系统会自动选择一个可以唯一标识数据记录的列作为主键，如果不存在这种列，则MySQL自动为InnoDB表生成一个隐含字段作为主键，这个字段长度为6个字节，类型为长整形。

- 辅助索引存放data不同

	第二个与MyISAM索引的不同是InnoDB的辅助索引data域存储相应记录主键的值而不是地址。换句话说，InnoDB的所有辅助索引都引用主键作为data域。例如，下图为定义在Col3上的一个辅助索引

	![InnoDB_B+Tree](/images/InnoDB_B+Tree.png)

	因而，InnoDB中辅助索引搜索需要检索两遍索引（此时即为InnoDB的非聚簇索引）：首先检索辅助索引获得主键，然后用主键到主索引中检索获得记录，这种两次查找的现象，也称作 **回表**。

- InnoDB的索引优化

	- 不建议使用过长的字段作为主键

		因为所有辅助索引都引用主索引，过长的主索引会令辅助索引变得过大

	- 用非单调的字段作为主键在InnoDB中不是个好主意

		因为InnoDB数据文件本身是一颗B+Tree，非单调的主键会造成在插入新记录时数据文件为了维持B+Tree的特性而频繁的分裂调整，十分低效，而使用自增字段作为主键则是一个很好的选择

#### 四种索引查询现象

- 回表查询：在搜索`Column A`的索引时，根据匹配到叶子节点，查询到叶子节点中数据的id，然后根据id回到id的B+Tree中再去查找数据，两次查找的过程即为 **回表查询** 。
- [索引覆盖](https://www.cnblogs.com/myseries/p/11265849.html)【Covering index】：在搜索`Column A`的索引时，根据匹配到叶子节点，查询到叶子节点中数据的id与`Column A`的值，二者刚好满足要查询的内容，此时无需再回到id索引进行查询其他列数据，一次查找的过程即为 **索引覆盖** 。
- 最左匹配
- [索引下推](https://zhuanlan.zhihu.com/p/121084592)【Index Condition Pushdown】：当查询中，存在对多个Column限定条件时，ICP条件下，当回表搜索id时，引擎会将多个Column限定条件一同进行判断，仅需一次回表即可完成。非ICP条件下，回表过程，对于每个条件，MySQL都会到id表里进行一次条件查询，每次查询，引擎都会把本次查询结果返回MySQL服务器，而非最终结果，最终会产生多次回表。MySQL5.6版本正式引入ICP，并默认开启。

#### 索引使用策略及优化

- 优化种类
	- Scheme optimization 结构优化
	- Query optimization 查询优化

- 优化原则

	- 视频内容

		- 索引不是越多越好
		- 不要对经常变动的列加索引
		- 小数据量的表不要对做索引
		- 索引一般加在经常查询的字段上

	- 最左前缀原理与相关优化

	- 索引选择性与前缀索引

	  因为索引虽然加快了查询速度，但索引也是有代价的：索引文件本身要消耗存储空间，同时索引会加重插入、删除和修改记录时的负担，另外，MySQL在运行时也要消耗资源维护索引，因此索引并不是越多越好。一般两种情况下不建议建索引。

	  第一种情况是**表记录比较少**，例如一两千条甚至只有几百条记录的表，没必要建索引，让查询做全表扫描就好了。至于多少条记录才算多，这个主要根据个人的看法，我个人的经验是以2000作为分界线，记录数不超过 2000可以考虑不建索引，超过2000条可以酌情考虑索引。

	  另一种情况是**索引的选择性较低**。所谓索引的选择性（Selectivity），是指不重复的索引值（也叫基数，Cardinality）与表记录数（#T）的比值：
	  $$
	  Index\ Selectivity = Cardinality / \#T
	  $$
	  **选择性越高的索引价值越大**，可用如下方式（Hyperloglog算法）计算某一列的*`Index Selectivity`*：

	  ```sql
	  SELECT count(DISTINCT(first_name))/count(*) AS Selectivity FROM employees.employees;
	  ```

	  有一种与索引选择性有关的索引优化策略叫做 **前缀索引** ，就是用列的前缀代替整个列作为索引key，当前缀长度合适时，可以做到既使得前缀索引的选择性接近全列索引，同时因为索引key变短而减少了索引文件的大小和维护开销。（优化实例参见原博客）

	  前缀索引兼顾索引大小和查询速度，但是其缺点是不能用于ORDER BY和GROUP BY操作，也不能用于Covering index（即当索引本身包含查询所需全部数据时，不再访问数据文件本身）。

	- 优先使用自增主键

		如果表使用自增主键，那么每次插入新的记录，记录就会顺序添加到当前索引节点的后续位置，当一页写满，就会自动开辟一个新的页。这样就会形成一个紧凑的索引结构，近似顺序填满。由于每次插入时也不需要移动已有数据，因此效率很高，也不会增加很多开销在维护索引上。

		如果使用非自增主键（如果身份证号或学号等），由于每次插入主键的值近似于随机，因此每次新纪录都要被插到现有索引页得中间某个位置。

		此时MySQL不得不为了将新记录插到合适位置而移动数据，甚至目标页面可能已经被回写到磁盘上而从缓存中清掉，此时又要从磁盘上读回来，这增加了很多开销，同时频繁的移动、分页操作造成了大量的碎片，得到了不够紧凑的索引结构，后续不得不通过OPTIMIZE TABLE来重建表并优化填充页面。

### 7.3 插入测试数据（100W）

```sql
-- 插入100万数据
-- 写函数之前必须要写DELIMITER，标志
DELIMITER $$
CREATE FUNCTION mock_data ()
RETURNS INT
BEGIN
	DECLARE num INT DEFAULT 1000000;
	DECLARE i INT DEFAULT 0;
	WHILE i < num DO
		INSERT INTO `app_user`(`name`,`eamil`,`phone`,`gender`)
		VALUES(CONCAT(用户,i),19224305@qq.com,123456789,FLOOR(RAND()*2));
		SET i=i+1;
	END WHILE;
	RETURN i;
END;

SELECT mock_data(); -- 执行此函数 生成一百万条数据
```

## 8 权限管理和备份

### 8.1 用户管理

```sql
-- 创建用户
CREATE USER username IDERNTIFIED BY '123456'
-- 修改密码
SET PASSWORD = PASSWORD ('new password')
SET PASSWORD FOR username = PASSWORD ('new password')
-- 重命名
RENAME USER username TO new_username
-- 授权
-- 对所有表都有所有权限，但是不能给其他用户授权
GRANT ALL PRIVILEGES ON *.* TO username 
-- 查看指定用户权限
SHOW GRANTS FOR username
SHOW GRANTS FOR username@localhost
-- 撤销权限
REVOKE ALL PRIVILEGES ON *.* FROM username
-- 删除用户
DROP USER username
```

### 8.2 数据库备份

- 物理文件拷贝

- 导出为SQL文件

- `mysqldump`工具

	```shell
	mysqldump -h主机名 -u用户名 -p密码 库名 表名 > 物理存储位置
	```

	导入时，可以通过MySQL内`source`命令或者`mysql`工具导入

	```sql
	SOURCE SQLFileName
	```

	```shell
	mysql -u用户名 -p密码 库名 < 备份文件
	```

## 9 数据库设计

设计流程：分析需求->概要设计（含关系图，ER图）

### 9.2 三大范式

通俗理解(https://www.cnblogs.com/wsg25/p/9615100.html)

- 1NF：保证每一列不可再分
- 2NF：符合1NF，每个表只描述一个事情（例如订单detail和产品号）
- 3NF：符合1NF&2NF，每一列的数据必须和主键相关，不能间接相关（学生ID为主键下，老师姓名不应出现）

实际过程中，应当综合考虑规范性和性能问题：

> 【阿里设计规范】每次查询，不应关联超过三张表