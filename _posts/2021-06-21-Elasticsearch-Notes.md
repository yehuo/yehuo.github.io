---
title: Elasticsearch Notes
date: 2021-06-21
categories:
  - Backend
tags:
  - Elasticsearch
---



# 0x02 什么是Elasticsearch

## 什么是搜索？

通用搜索：百度；互联网搜索（垂直搜索-站内搜索）：电商，招聘，新闻网站，APP；IT系统内部搜索（垂直搜索-站内搜索）：OA软件内部搜索

## 如果用数据库搜索会怎样？

数据搜索太慢：需要处理所有表项的所有文本

无法实现特殊格式搜索：拆开搜索，非全字搜索

## 什么是全文检索和Lucene？

全文检索（倒排索引）：将关键词拆分以分开存储

Lucene：一个jar包用于支持java开发全文检索功能

## 什么是Elasticsearch：

Lucene在分布式环境下的解决方案（底层封装Lucene）

统一接口，高可用性，比Lucene更多的高级功能

# 0x03 Elasticsearch的功能、使用场景、特点介绍

## ES功能

作为分布式搜索引擎和数据分析，实现全文检索、结构化检索、数据分析：

- 全文检索：如搜索包含某名称的商品

- 结构化检索：搜索分类为日化用品的商品

- 数据分析：某类别下的商品数目

对海量数据近实时处理，在秒级别实现检索。

## ES使用场景

wiki百科，Guardian，StarkOverflow，Github，电商网站，商品价格监控，BI（Business Intelligence）系统，ES数据分析挖掘，Kibana做可视化

## ES特点

- 分布式集群，可以支撑PB数据
- 开箱即用，部署迅速（尤其对于中小集群）
- 数据库的功能补充

# 0x04 Elastic核心概念——NRT，索引，分片，副本

1. 发展历程：Lucene -> Compass -> Elasticsearch

2. Elasticsearch核心概念

  - Near Realtime：写入后存在一定延迟（秒级）后，才可以访问到

  - Cluster Node

  - Document：一条数据，最小数据单元，里面有field，对应数据字段，常用JSON格式

		```json
		product document{
		    "product_id" : "1",
		    "product_name" : "高露洁牙膏",
		    "category_id" : "2",
		    "category_name" : "日化用品"
		}
		```

  - Index：具有相似结构的文档数据，例如客户索引，订单索引，一个index对应很多document

  - Type： **Index逻辑上的数据分类**。一个Index中包含很多type，一个Type对应多个document实例。例如由于很多商品的field字段数目种类不同，每个type对应一种不同的document的结构。例如：

	  - **日化商品type** "product_id","product_name","category_id","category_name"
	  - **电器商品type** "product_id","product_name","category_id","category_name","service_period"
	  - **生鲜商品type**："product_id","product_name","category_id","category_name","eat_period"

  - Shard： **Index会被拆成多个Shard**。放到多个服务器上。以便横向扩展，所有操作在服务器上多个服务器执行提升吞吐量，可以建立副本Shard提升安全性。**Replica Shard**，也被称作副本分片，与之对应的是Primary Shard。

		> ES规定Replica Shard和Primary Shard不可以存放于同一个节点上，最简单的模式中，通常是分到两个节点，分别放一部分Primary和Replica Shard。

3. Elasticsearch核心概念vs数据库核心概念

	| Elasticsearch | database |
	| ------------- | -------- |
	| document      | row      |
	| type          | table    |
	| index         | database |

# 0x05 ES on Windows

1. 安装JDK

2. 下载解压ES安装包

3. 启动`\bin\elasticsearch.bat`

4. 利用`http://localhost:9200/?pretty`验证是否启动成功

5. config目录下`elasticsearch.yml`中修改集群名称

  ```
  localhost:9200
  cluster.name
  ```

6. 下载、解压Kibana安装包

7. 执行`\bin\kibana.bat`

8. Kibana的`devtool`界面

  ```json
  localhost:5601
  GET _cluster/health
  ```


# 0x06 集群健康检查，文档CRUD

document数据格式：JSON格式，面向对象，区别关系型数据库

## 电商网站商品管理背景介绍

1.对商品进行CRUD操作

2.执行简单的结构化查询

3.可以执行简单的全文检索，以及复杂的phrase检索

4.对全文检索结果的高亮显示

5.对数据进行简单的聚合分析

## 简单的集群管理操作

1. 检查集群健康状况

  - `cat`方法

    ```http
    GET /_cat/health?
    ```

  - `curl request`

    - `-X`指定http的请求方法有 HEAD \| GET \| POST \| PUT \| DELETE
    - `-d`指定要传输的数据
    - `-H`指定http请求头信息

    ```http
    GET /_cluster/health/<target>
    ```

    > One of the main benefits of the API is the ability to wait until the cluster reaches a certain high water-mark health level. For example, the following will wait for 50 seconds for the cluster to reach the `yellow` level (if it reaches the `green` or `yellow` status before 50 seconds elapse, it will return at that point):
    >
    > ```shell
    > curl -X GET "localhost:9200/_cluster/health?wait_for_status=yellow&timeout=50s&pretty"
    > ```

  - 运行状态分析

  	| Status | Description                                                  |
  	| ------ | ------------------------------------------------------------ |
  	| Green  | 所有primary shard和replica shard都是active状态***All shards are allocated*** |
  	| Yellow | 所有primary shard处于active状态。部分replica shard处于不可用状态（如果只有一台机器，statue一定是黄色，因为没办法备份）***The primary shard is allocated but replicas are not.*** |
  	| Red    | 不是所有index的primary shard都处于active状态，部分所有数据丢失。***The specific shard is not allocated in the cluster***. |

  

2. 快速检查集群中有哪些索引

	```http
	GET /_cat/indices?v
	```

3. 简单的索引操作

  - 添加索引

  ```http
  PUT /test_index?pretty
  ```

  - 删除索引

  ```http
  DELETE /test_index?pretty
  ```

## document的CRUD操作

1. Create

  ```json
  PUT /index/type/id
  { 
  	"json data" 
  }
  ```

  index和type都由Elasticsearch引擎自动创建，不需要提前创建

  ```JSON
  PUT /ecommerce/product/1
  {
  	"name" : "gaolujie yagao",
  	"desc" : "gaoxiao meibai",
  	"price" : 30,
  	"producer" : "gaolujie producer",
  	"tags" : ["meibai","fangzhu"]
  }
  ```

2. Select

  ```json
  GET /index/type/id
  GET /ecommerce/product/1
  ```

3. Update

  PUT / POST两种更新方式

  - PUT方式（替换方式）：替换数据，存在必须加上所有field才能有效修改信息，否则会用空白覆盖掉未填写的field，写法参见Create

  - POST方法（更新方式）：可以只更新一部分值

  	```http
  	POST /index/type/id/_update
  	{
  	    "doc" : {
  	        "name" : "jiaqiangban gaolujie yagao"
  	    }
  	}
  	```

4. Delete

	```http
	DELETE /ecommerce/product/1
	```

# 0x07 快速入门案例之商品管理——多种搜索方式

- query string research

  ```http
  GET /ecommerce/product/_search
  ```

  返回结果分析：

  | Keys        | Description     |
  | ----------- | --------------- |
  | took        | 查询所用时间    |
  | time_out    | 是否超时        |
  | shards      | primary分片数目 |
  | hits.totals | 命中数目        |
  | max_score   | 匹配相关度(<1)  |
  | hits.hits   | 匹配到的数据    |

  获取搜索结果中最低价商品：

  ```http
  GET /ecommerce/product/_search?q=name:yagao&sort=price:desc
  ```

  参数分析：

  | name              | sort                  |
  | ----------------- | --------------------- |
  | 查询`yagao`的字段 | 按照price字段降序输出 |

- query DSL(Domain Search Language)

	```json
	# 查询所有商品
	GET /ecommerce/product/_search
	{
	    "query": {"match_all":{}}
	}
	
	# 按降序查询包含"yagao"的商品
	GET /ecommerce/product/_search
	{
	    "query": {
	        "match": {
	            "name" : "yagao"
	        }
	    },
	    "sort" : [
	        {"price" : "desc"}
	    ]
	}
	
	# 分页查询商品：从第二个商品开始查（from=1,第一个商品是0）
	GET /ecommerce/product/_search
	{
	    "query":{"match_all":{}},
	    "from":1,
	    "size":2
	}
	
	# 指定要查询的部分，例如价格、名称
	GET /ecommerce/product/_search
	{
	    "query": {
	        "march_all": {}
	    },
	    "_source": {"name": "price"}
	}
	```

- query filter

	```json
	# 查询售价大于25的牙膏商品
	GET /ecommerce/product/_search
	{
	    "query": {
	        "bool":{
	            "must":{
	                "match":{
	                    "name":"yagao"
	                }
	            },
	            "filter":{
	                "range":{
	                    "price":{
	                        "gt":25
	                    }
	                }
	            }
	        }
	    }
	}
	```

- full-text search

	全文检索，会将搜索串拆开去倒排索引中逐一匹配，只要匹配了拆解后的任意单词就会作为结果返回

	```json
	GET /ecommerce/product/_search
	{
	    "query" : {
	        "match" : {
	            "producer" : "yagao producer"
	        }
	    }
	}
	```

- phrase search

	phrase search只有在搜索串完全匹配时才会返回

	```json
	GET /ecommerce/product/_search
	{
	    "query" : {
	        "match_phrase" : {
	            "producer" : "yagao producer"
	        }
	    }
	}
	```

- highlight search

	```json
	GET /ecommerce/product/_searrch
	{
	    "query": {
	        "match": {
	            "producer": "producer"
	        }
	    },
	    "highlight": {
	        "fields": {
	            "producer": {}
	        }
	    }
	}
	```

# 0x08 group by | avg | sort等聚合分析

## 1.计算每个tag下的商品数量

```json
GET /ecommerce/product/_search		
{
    "aggs": {
        "group_by_tags": {
            "terms": {
                "field": "tags"
            }
        }
    }
}
```

p.s.将field文本`fieddata`设置为true

```json
PUT /ecommerce/_mapping/product
{
    "properties" :{
        "tags": {
            "type": "text",
            "fielddata": true
        }
    }
}
```

## 2.对特定名称计算tags下分组（先搜索再分组）

```json
GET /ecommerce/product/_search
{
    "size": 0,
    "query": {
        "match": {
            "name": "yagao"
        }
    },
    "aggs": {
        "all_tags": {
            "terms": {
                "field": "tags"
            }
        }
    }
}
```

## 3.先分组再算平均值，在每个tags计算商品平均价格

```json
GET /ecommerce/product/_search
{
    "size": 0,
    "aggs": {
        "group_by_tags": {
            "terms": {
                "field": "tags"
            },
            "aggs": {
                "avg_price": {
                    "avg": {
                        "field": "price"
                    }
                }
            }
        }
    }
}
```

## 4.按平均价格降序排序

```json
GET /ecommerce/product/_search
{
    "size": 0,
    "aggs": {
        "all_tags": {
            "terms": { 
                "field":"tags",
                "order":{
                    "avg_price":"desc"
                }
            },
            "aggs": {
                "avg_price": {
                    "avg": {
                        "field":"price"
                    }
                }
            }
        }
    }
}
```

## 5.先按价格区间分类，然后按tags分类，最后聚合

```json
GET /ecommerce/product/_search
{
    "size": 0,
    "aggs": {
        "get_by_price": {
            "rangs": {
                "field": "price",
                "rangs": [
                    "from":0
                    "to"
                ]
            }
            "all_tags": {
            "terms": { 
            "field":"tags",
            "order":{
            "avg_price":"desc"
        }
    },
    "aggs": {
        "avg_price": {
            "avg": {
                "field":"price"
            }
        }
    }
}
```

# 0x09 剖析Elasticsearch的基础分布式架构

- 复杂的分布式机制隐藏：分片，副本，负载均衡，请求路由，集群扩容，shard重分配
- 垂直扩容与水平扩容
  - 垂直扩容，数量不变，以新换旧——可能会导致瓶颈
  - 水平扩容，质量不变，数量增加——业界常用
  - rebalance：总有个别服务器负载会重一些
- master节点
  - 管理集群的meta数据，默认情况下，会自动选择出一条作为master节点
  - 负载很轻，不承载所有请求
  - 主要功能为创建删除索引，增加删除节点
  - 节点对等的分布式架构

# 0x0A shard&replica梳理以及单点环境中创建index图解

- shard和replica
  - index被分为多个shard
  - 每个shard只承载部分数据
  - 每个document只存在一个primary shard，不会在另一个primary shard做备份
  - Primary shard在创建集群时候确定，replica shard后续可以更改
  - Primary shard和自己的replica shard不能放在同一个节点上 

- 单node的index分析

  - 单node情况下，所有primary shard都被放到一个node中，无法分配replica shard

	```json
	PUT /test_index
	{
	    "settings" : {
	        "number_of_shard" : 3,
	        "number_of_replicas" : 1
	    }
	}
	```