---
title: "从零开始设计一个全文检索系统"
date: 2018-08-10
categories: Experience
tags: [Elasticsearch, PHP]
excerpt: "故事要从boss吃了安利，有一天忽然心血来潮想要搞一个内部全文检索系统开始说起..."
---



## 0x00 Background

这个项目的背景是由于公司的老板突然受到某兄弟部门的推销，决定引入NoSQL技术来推动公司的工作，并要求对所有整理进Nosql的数据实现全文检索功能。

具体到技术栈，老大较为朴素地提出了一个架构设计：“就是用MongoDB+Elasticsearch+PHP搭建一个检索终端……”。并以通俗易懂的方式补充道：“NoSQL就是将数据以JSON格式存储在数据库中，你懂吧(^-^)”

于是……老大先把任务下达到运营部门，要求他们手动将所有的MySQL中的txt格式的content数据（对应大概几百份Doc文件）转换为JSON文件并发送给我

（不幸地是他们真的只会手工写JSON

（幸运的是，运营部门的负责人是个比较礼貌的人

再然后，几个月之后，重担到了我这里，对着运营部门发来的几百份尚未经过语法校验的JSON文件，我大概花了一天来平复心情

然后，我需要从一堆屎山JSON文件开始，构建一个完整支持全文检索的文件搜索系统……

# 0x01 将json文件批量导入MongoDB

# 0x02 使用bulk API将json批量导入Elasticsearch

# 0x03 设定从MongoDB到Elasticsearch集群的定期同步

# 0x04 使用PHP-Elasticsearch组件调用Elasticsearch全文检索功能

# 0x05 设计前端页面以获取PHP发送的JSON格式数据

# 0x06 设计前端跳转逻辑

# 0x07 在前端页面中添加CRUD操作端口以直接操作MongoDB
