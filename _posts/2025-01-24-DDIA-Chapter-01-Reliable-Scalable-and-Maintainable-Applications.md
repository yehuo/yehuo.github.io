---
title: "DDIA Chapter 01 Reliable, Scalable and Maintainable Applications"
date: 2025-01-24
excerpt: Notes from Designing Data-Intensive Applications Chapter 1, covering reliability, scalability, and maintainability in data systems. Key topics include handling hardware/software faults, human errors, load and performance analysis, operability, simplicity, and evolvability. Highlights include Twitter's architecture evolution and techniques like abstraction, monitoring, and testing to build robust, efficient, and adaptive systems.
categories:
  - Architect Design
tags:
  - DDIA
---



# Reliability可靠性

## Hardware Faults

首先通过MTTF一类指标去评估硬件故障发生概率，对于一些小的节点、集群，做好RAID、热备电源，可以热切换的CPU甚至于柴油发电机就够了。{: .notice--success}

> Hard disks are reported as having a **mean time to failure (MTTF)** of about 10 to 50 years. Thus, on a storage cluster with 10,000 disks, we should expect on average one disk to die per day.

> Our first response is usually to add redundancy to the individual hardware components in order to reduce the failure rate of the system. Disks may be set up in a RAID configuration, servers may have dual power supplies and hot-swappable CPUs, and datacenters may have batteries and diesel generators for backup power.

从系统层面看，出现故障的往往并非某个硬件配件，所以需要去做一些备用的节点和主机。同时，支持备用主机的系统也更方便去滚动升级。

> However, as data volumes and applications' computing demands have increased, more applications have begun using larger numbers of machines, which proportionally increases the rate of hardware faults.

> Hence there is a move toward systems that can tolerate **the loss of entire machines**, by using software fault-tolerance techniques in preference or in addition to hardware redundancy.

## Software Errors

软件错误更加具有系统性，一个错误会引发系统内所有节点的故障。

软件错误的产生，往往是因为开发者对软件运行环境做了一些错误的assumption。

> The bugs that cause these kinds of software faults often lie dormant for a long time until they are triggered by an unusual set of circumstances.

软件错误可以通过仔细论证系统内的假设与交互问题，开展测试、解耦、考虑程序的故障和重启问题；度量、检测、分析系统在生产环境中运行状态。

> There is no quick solution to the problem of systematic faults in software. Lots of small things can help: carefully thinking about assumptions and interactions in the system; thorough testing; process isolation; allowing processes to crash and restart; measuring, monitoring, and analyzing system behavior in production. 

> If a system is expected to provide some guarantee (for example, in a message queue, that the number of incoming messages equals the number of outgoing messages), it can constantly check itself while it is running and raise an alert if a discrepancy is found.

## Human Errors

- Design systems in a way that minimizes opportunities for error.
- Decouple the places where people make the most mistakes from the places where they can cause failures.
- Test thoroughly at all levels, from unit tests to whole-system integration tests and manual tests.
- Allow quick and easy recovery from human errors, to minimize the impact in the case of a failure.
- Set up detailed and clear monitoring, such as performance metrics and error rates.

# Scalability可扩展性

## Describing Load

形容负载，首先就要确定 *load parameters*， load parameters的最佳选项需要根据系统予以决定

> Perhaps the average case is what matters for you, or perhaps your bottleneck is dominated by a small number of extreme cases.

此处以推特为例：

- Post tweet: A user can publish a new message to their followers (4.6k requests/sec on average, over 12k requests/sec at peak).
- Home timeline: A user can view tweets posted by the people they follow (300k requests/sec).

对于tweet提出两种架构，联表查询方案和订阅表方案：

1. Posting a tweet simply inserts the new tweet into a global collection of tweets. When a user requests their home timeline, look up all the people they follow, find all the tweets for each of those users, and merge them (sorted by time). In a relational database like in Figure 1-2, you could write a query such as: 

```sql
SELECT tweets.*, users.* FROM tweets 
JOIN users ON tweets.sender_id = users.id
JOIN follows ON follows.followee_id = users.id 
WHERE follows.follower_id = current_user
```

2. Maintain a cache for each user’s home timeline—like a mailbox of tweets for each recipient user (see Figure 1-3). When a user posts a tweet, look up all the people who follow that user, and insert the new tweet into each of their home timeline caches. The request to read the home timeline is then cheap, because its result has been computed ahead of time.

![DDIA1-1](\images\DDIA1-1.png)

> **This works better because the average rate of published tweets is almost two orders of magnitude lower than the rate of home timeline reads, and so in this case it’s preferable to do more work at write time and less at read time.**

> The final twist of the Twitter anecdote: now that approach 2 is robustly implemented, **Twitter is moving to a hybrid of both approaches**. Most users' tweets continue to be fanned out to home timelines at the time when they are posted, but a small number of users with a very large number of followers (i.e., celebrities) are excepted from this fan-out. 
>
> Tweets from any celebrities that a user may follow are fetched separately and merged with that user's home timeline when it is read, like in approach 1. This hybrid approach is able to deliver consistently good performance.

## Describing Performance

延迟和相应时间的区别（latency and response time）

> Latency and response time are often used synonymously, but they are not the same. The response time is what the client sees: besides the actual time to process the request (the service time), it includes network delays and queueing delays. Latency is the duration that a request is waiting to be handled during which it is latent, awaiting service.

SLA和SLO中对于相应时间百分数的实际应用

> An SLA may state that the service is considered to be up if it has **a median response time of less than 200ms and a 99th percentile under 1 s** (if the response time is longer, it might as well be down), and the service may be required to be up at least 99.9% of the time. These metrics set expectations for clients of the service and allow customers to demand a refund if the SLA is not met.

**【压力测试中容易出现的误区】**：测试中的模拟客户端，不应该串行发包。如果客户端不能独立于响应时间地发送测试请求，那服务端的请求队列其实是被人为的缩短了，就不能模拟真实环境中，服务端所面临的请求压力。关于测试环境无法模拟真实环境的更多问题参见：[Everything You Know About Latency Is Wrong – Brave New Geek](https://bravenewgeek.com/everything-you-know-about-latency-is-wrong/)

> When generating load artificially in order to test the scalability of a system, the load generating client needs to keep sending requests independently of the response time. If the client waits for the previous request to complete before sending the next one, that behavior has the effect of artificially keeping the queues shorter in the test than they would be in reality, which skews the measurements. 

现实中，一个用户端程序往往会并行请求多个服务端的服务，而客户端的总延迟是由那个延迟最长的服务来决定的。此时在服务端来测算延迟，几百个请求中，可能只有一两个延迟会超标，但是客户端的体验依然会十分差，这种情况往往被称作 **尾部延迟放大**（**tail latency amplification**）效应，内容参见文章 [The Tail at Scale \| February 2013 \| Communications of the ACM](https://cacm.acm.org/magazines/2013/2/160173-the-tail-at-scale/fulltext)。

## Approaches for Coping with Load

横向扩展vs纵向扩展 & 人工操作vs弹性伸缩

- scaling up: vertical scaling, moving to a more powerful machine

- scaling out: horizontal scaling, distributing the load across multiple smaller machines
- elastic system: they can automatically add computing resources when they detect a load increase, whereas other systems are scaled manually (a human analyzes the capacity and decides to add more machines to the system).

没有银弹

> The architecture of systems that operate at large scale is usually highly specific to the application—there is no such thing as a generic, one-size-fits-all scalable architecture (informally known as magic scaling sauce). The problem may be the volume of reads, the volume of writes, the volume of data to store, the complexity of the data, the response time requirements, the access patterns, or (usually) some mixture of all of these plus many more issues.

# Maintainability可维护性

- **Operability**

	Make it easy for operations teams to keep the system running smoothly.

- **Simplicity** 

	Make it easy for new engineers to understand the system, by removing as much complexity as possible from the system. (Note this is not the same as simplicity of the user interface.)

- **Evolvability**

	Make it easy for engineers to make changes to the system in the future, adapting it for unanticipated use cases as requirements change. Also known as extensibility, modifiability, or plasticity.

## Operability 让运维活得更开心

> 有人认为，“良好的运维经常可以绕开垃圾（或不完整）软件的局限性，而再好的软件摊上垃圾运维也没法可靠运行”。尽管运维的某些方面可以，而且应该是自动化的，但在最初建立正确运作的自动化机制仍然取决于人。

## 运维的职责

- 监控系统的运行状况，并在服务状态不佳时快速恢复服务
- 跟踪问题的原因，例如系统故障或性能下降
- 及时更新软件和平台，比如安全补丁
- 了解系统间的相互作用，以便在异常变更造成损失前进行规避
- 预测未来的问题，并在问题出现之前加以解决（例如，容量规划）
- 建立部署，配置、管理方面的良好实践，编写相应工具
- 执行复杂的维护任务，例如将应用程序从一个平台迁移到另一个平台
- 当配置变更时，维持系统的安全性
- 定义工作流程，使运维操作可预测，并保持生产环境稳定
- 铁打的营盘流水的兵，维持组织对系统的了解

## How to make routine task easy?

- 通过良好的监控，提供对系统内部状态和运行时行为的**可见性（visibility）**
- 为自动化提供良好支持，将系统与标准化工具相集成
- 避免依赖单台机器（在整个系统继续不间断运行的情况下允许机器停机维护）
- 提供良好的文档和易于理解的操作模型（“如果做X，会发生Y”）
- 提供良好的默认行为，但需要时也允许管理员自由覆盖默认值
- 有条件时进行自我修复，但需要时也允许管理员手动控制系统状态
- 行为可预测，最大限度减少意外

## Simplicity 处理复杂性

“屎山的来源与分析”参见：[Big Ball of Mud](http://www.laputan.org/pub/foote/mud.pdf)

## 复杂性的来源分析

> There are various possible symptoms of complexity: explosion of the state space, tight coupling of modules, tangled dependencies, inconsistent naming and terminology, hacks aimed at solving performance problems, special-casing to work around issues elsewhere, and many more.

## 关于复杂性分析的三个讨论材料

- 书籍《没有银弹》：[No Silver Bullet](http://worrydream.com/refs/Brooks-NoSilverBullet.pdf)
- 文章《走出屎坑》：[CiteSeerX — Out of the Tar Pit (psu.edu)](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.93.8928)
- 视频《简而易行》：[Simple Made Easy (infoq.com)](https://www.infoq.com/presentations/Simple-Made-Easy/)

## 复杂性的最终解决方案：Abstraction

解决系统复杂性最好的办法还是抽象，SQL对于数据系统是一种抽象，高级语言对于计算机硬件是一种抽象。好的抽象虽然难于发现，但是可以真正从根上解决系统复杂性问题。

> One of the best tools we have for removing accidental complexity is abstraction. A good abstraction can hide a great deal of implementation detail behind a clean, simple-to-understand façade. A good abstraction can also be used for a wide range of different applications. Not only is this reuse more efficient than reimplementing a similar thing multiple times, but it also leads to higher-quality software, as quality improvements in the abstracted component benefit all applications that use it.

## Evolvability 让二次开发更简单

对于一个小系统，你修改内部文件、添加功能的复杂性往往被称作软件的敏捷性（Agility），而对于一个更大的系统，这样的性质往往被称作可进化性（Evolvability）。

> The ease with which you can modify a data system, and adapt it to changing requirements, is closely linked to its simplicity and its abstractions: simple and easy-to-understand systems are usually easier to modify than complex ones. But since this is such an important idea, we will use a different word to refer to agility on a data system level: evolvability. 

# Summary

- **功能需求（functional requirements）**

	它应该做什么，比如允许以各种方式存储，检索，搜索和处理数据

- **非功能性需求（nonfunctional ）**

	通用属性，例如安全性，可靠性，合规性，可扩展性，兼容性和可维护性

  - 可靠性 Reliability

		抵抗来自于硬件（通常是随机的和不相关的），软件（通常是系统性的Bug，很难处理），和人类（不可避免地时不时出错）的故障的影响

  - 可扩展性 Scalability

		定量描述负载和性能，通过添加处理容量（processing capacity） 以在高负载下保持可靠

  - 可维护性 Maintainability

		良好的可操作性意味着对系统的健康状态具有良好的可见性，并拥有有效的管理手段
