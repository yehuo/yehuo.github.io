---
title: "从零开始设计一个全文检索系统"
date: 2018-08-10
categories: Experience
tags: [Elasticsearch, PHP]
excerpt: "故事要从boss吃了安利，有一天忽然心血来潮想要搞一个内部全文检索系统开始说起..."
---

### 0x00 Background

不知boss吃了谁家安利，有一天忽然心血来潮，要搞一波nosql来推进我司工作，还要求支持全文检索。

具体到技术栈，boss也做了很**具体**的要求

“就是MongoDB+Elasticsearch+PHP搞一个检索终端...”

然后 boss **通俗易懂**地补充道

“Nosql就是把数据以JSON格式存入数据库...”

于是...boss先给运营下达任务，要求把全部mysql数据手工转换为json文件发给了我...

~~还好数据量不大...运营部门lead也都很礼貌~~

然后一把梭的重任就落到了我肩上，看着运营发来的n份~~完全没做过正确性检验的~~json文件，我和运营大佬内心都感想万千...

下面开始，我就需要从一份json文件开始，扩展完整支持全文检索的文件搜索系统。

### 0x01 将json文件批量导入MongoDB

### 0x02 使用bulk API将json批量导入Elasticsearch

### 0x03 设定从MongoDB到Elasticsearch集群的定期同步

### 0x04 使用PHP-Elasticsearch组件调用Elasticsearch全文检索功能

### 0x05 设计前端页面以获取PHP发送的JSON格式数据

### 0x06 设计前端跳转逻辑

### 0x07 在前端页面中添加CRUD操作端口以直接操作MongoDB
