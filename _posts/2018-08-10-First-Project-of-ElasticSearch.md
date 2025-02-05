---
title: First Project of ElastiSearch
date: 2018-08-10
excerpt: "故事要从boss吃了安利，有一天忽然心血来潮想要搞一个内部全文检索系统开始说起..."
categories:
  - Backend
tags:
  - Elasticsearch
---



# 0x01 Why Elasticsearch

这个项目的背景是由于 Manager 受到某兄弟部门的推销，决定引入 NoSQL 来推动公司的工作，并要求对所有存入 NoSQL 的数据提供全文检索功能。

具体到技术栈，Manager 较为朴素地提出了一个架构设计：

> ”就是用 MongoDB + Elasticsearch + PHP搭建一个检索终端”

并以较为朴素的方式补充解释了下他对 ElasticSearch 的理解：

> “NoSQL就是将数据以JSON格式存储在数据库中，你懂的对吧...”

同时 Manager 先把任务下达到研报部门，要求他们手动将所有的 MySQL 中原来以 txt 格式存储的博客内容数据导出为大概几百份Word文档，然后手工转换为 JSON 文件并发送给我。

幸运的是研报组组长是个脾气很好的人，不幸地是他们真的只会手工写 JSON，完全不会用脚本偷懒。

最终，经过研报组几个月的艰苦努力，他们给我发来的 500 个充满语法错误的 JSON 文件，看着 Viscode 里近乎所有文件都标红的状态，感觉有点迷茫...

下面，我需要从一堆屎山 JSON 文件开始，构建一个完整支持全文检索的文件搜索系统，这里用一份梳理好莎士比亚文集作为模版

![Architecture](\images\20180810\architecture.png)

# 0x02 将 JSON 文件批量导入 MongoDB

```python
import json
import os
from pymongo import MongoClient

def batch_import_json_to_mongodb(folder_path, db_name, collection_name, mongo_uri="mongodb://localhost:27017/"):
    """
    批量导入JSON文件到MongoDB集合中
    :param folder_path: 存放JSON文件的文件夹路径
    :param db_name: MongoDB数据库名
    :param collection_name: MongoDB集合名
    :param mongo_uri: MongoDB连接URI，默认为本地
    """
    try:
        # 连接MongoDB
        client = MongoClient(mongo_uri)
        db = client[db_name]
        collection = db[collection_name]

        # 遍历文件夹中的所有JSON文件
        for file_name in os.listdir(folder_path):
            if file_name.endswith(".json"):
                file_path = os.path.join(folder_path, file_name)
                print(f"正在导入文件: {file_path}")

                # 打开并读取JSON文件
                with open(file_path, "r", encoding="utf-8") as file:
                    data = json.load(file)

                    # 检查数据类型并插入
                    if isinstance(data, list):
                        collection.insert_many(data)
                        print(f"文件 {file_name} 中的数据已批量导入到集合 {collection_name}")
                    elif isinstance(data, dict):
                        collection.insert_one(data)
                        print(f"文件 {file_name} 中的数据已插入到集合 {collection_name}")
                    else:
                        print(f"文件 {file_name} 格式不支持，跳过")

        print("所有JSON文件导入完成！")
    except Exception as e:
        print(f"发生错误: {e}")
    finally:
        client.close()


# 示例调用
if __name__ == "__main__":
    folder_path = "./json_files"  # JSON文件夹路径
    db_name = "my_database"       # 数据库名称
    collection_name = "my_collection"  # 集合名称
    mongo_uri = "mongodb://localhost:27017/"  # MongoDB连接URI

    batch_import_json_to_mongodb(folder_path, db_name, collection_name, mongo_uri)
```

# 0x02 使用bulk API将json批量导入Elasticsearch

# 0x03 设定从 MongoDB 到 Elasticsearch 集群的定期同步

# 0x04 使用 PHP-Elasticsearch 组件调用 Elasticsearch 全文检索功能

# 0x05 设计前端页面以获取PHP发送的 JSON 格式数据

# 0x06 设计前端跳转逻辑

# 0x07 在前端页面中添加 CRUD 操作端口以直接操作 MongoDB
