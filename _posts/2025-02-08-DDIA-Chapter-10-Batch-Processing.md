---
title: "DDIA Chapter 10 Batch Processing"
date: 2025-02-08
categories:
  - Architect Desgin
tags:
  - DDIA
excerpt: "The blog excerpt discusses the evolution of data models, comparing relational and document models, highlighting the limitations of each, and exploring the rise of NoSQL and graph data models for handling complex relationships like many-to-many."
---



# 0x01 根据实时性点系统分类

- 服务：实时，响应时间通常是服务性能的主要衡量指标。
- 批处理系统：离线，批处理作业的主要性能衡量标准通常是吞吐量（处理特定大小的输入所需的时间）。
- 流处理系统：准实时。

**Example：批处理-MapReduce[2-6]**

> practice-1:Unix自定义工具批处理Mysql日志(/var/log/nginx/access.log)

> practice-2:测试练习一的处理性能

> practice-3:awk,sed,grep,sort,uniq,xargs的组合应用[8]

# Unix准则[12-13]

1. 让每个程序都做好一件事。要做一件新的工作，写一个新程序，而不是通过添加“功能”让老程序复杂化。
2. 期待每个程序的输出成为另一个程序的输入。不要将无关信息混入输出。避免使用严格的列数据或二进制输入格式。不要坚持交互式输入。
3. 设计和构建软件，甚至是操作系统，要尽早尝试，最好在几周内完成。不要犹豫，扔掉笨拙的部分，重建它们。
4. 优先使用工具来减轻编程任务，即使必须曲线救国编写工具，且在用完后很可能要扔掉大部分。
summary:自动化，快速原型设计，增量式迭代，对实验友好，将大型项目分解成可管理的块。

# Unix方案

- 统一的接口：在Unix中，这种接口是一个文件（file）（更准确地说，是一个文件描述符）。
- 逻辑与布线相分离：将输入/输出布线与程序逻辑分开，可以将小工具组合成更大的系统。
- 透明度和实验：
  - 输入安全性：输入文件通常被视为不可变的。这意味着你可以随意运行命令，尝试各种命令行选项，而不会损坏输入文件。
  - 中断调试性：可以在任何时候结束管道，将管道输出到less，然后查看它是否具有预期的形式。这种检查能力对调试非常有用。
  - 文件持久性：可以将一个流水线阶段的输出写入文件，并将该文件用作下一阶段的输入。这使你可以重新启动后面的阶段，而无需重新运行整个管道。

> practice-4:shell编写IP转换地区工具

# Unix解决方案：分布式文件系统（MapReduce为例）

*example:HDFS（Hadoop分布式文件系统），一个Google文件系统（GFS）的开源实现[19]。​除HDFS外，还有各种其他分布式文件系统，如GlusterFS和Quantcast File System（QFS）[20]。诸如Amazon S3，Azure Blob存储和OpenStack Swift [21]等对象存储服务在很多方面都是相似的。*

## Advantage
- 非共享:无共享方法不需要特殊的硬件，只需要通过传统数据中心网络连接的计算机。
- 同等安全性：它允许以比完全复制更低的存储开销以恢复丢失的数据[20,22]

## Components
- Mapper：`Mapper` 会在每条输入记录上调用一次，其工作是从输入记录中提取键值。
- Reducer：`MapReduce` 框架拉取由Mapper生成的键值对，收集属于同一个键的所有值，并使用在这组值列表上迭代调用Reducer。
- 在MapReduce中，如果你需要访问IP排序阶段，则可以通过编写第二个MapReduce作业并将第一个作业的输出用作第二个作业的输入来实现它。这样看来，Mapper的作用是将数据放入一个适合排序的表单中，并且Reducer的作用是处理已排序的数据。

## Details

- 分布性：MapReduce调度器试图在其中一台存储输入文件副本的机器上运行每个Mapper，只要该机器有足够的备用RAM和CPU资源来运行Mapper任务[26]。这个原则被称为将计算放在数据附近[27]（它节省了通过网络复制输入文件的开销，减少网络负载并增加局部性）。
- 工作流依赖：工作流中的一项作业只有在先前的作业 —— 即生产其输入的作业 —— 成功完成后才能开始。为了处理这些作业之间的依赖，有很多针对Hadoop的工作流调度器被开发出来，包括Oozie，Azkaban，Luigi，Airflow和Pinball [28]。
- 连接与分组：关系模型中的外键，文档模型中的文档引用或图模型中的边。为了在批处理过程中实现良好的吞吐量，计算必须（尽可能）限于单台机器上进行。为待处理的每条记录发起随机访问的网络请求实在是太慢了。而且，查询远程数据库意味着批处理作业变为非确定的（nondeterministic），因为远程数据库中的数据可能会改变。在排序合并连接中，Mapper和排序过程确保了所有对特定用户ID执行连接操作的必须数据都被放在同一个地方：单次调用Reducer的地方。预先排好了所有需要的数据，Reducer可以是相当简单的单线程代码，能够以高吞吐量和与低内存开销扫过这些记录。
---
--处理倾斜-MapReduce之后
--数据流引擎
