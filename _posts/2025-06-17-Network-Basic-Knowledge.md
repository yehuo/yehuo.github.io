title: "计算机网络基础"
date: 2025-06-17
categories:

  - Network
    tags:
  - Basic
    excerpt: "一些常见的计算机网络面试问题"

---



# 计算机网络基础

## 网络基础

### Q1. TCP 三次握手与四次挥手

三次握手建立连接：
Client → SYN
Server → SYN-ACK
Client → ACK

> 确保双方都能收发数据，防止旧连接干扰。

四次挥手关闭连接：

Client → FIN
Server → ACK（半关闭）
Server → FIN
Client → ACK

> TCP是全双工，双方需各自释放连接

### Q2. TCP vs UDP 特点和适用场景

协议  是否连接    是否可靠    适用场景
TCP 有连接（三次握手）   有序+重传+拥塞控制  Web、文件传输
UDP 无连接 不可靠，无重传 视频、语音、DNS、DHCP

### Q3. 什么是MTU, MSS, Window Scaling, Nagle's algorithm

MTU（最大传输单元）：以太网一般为 1500 bytes。
MSS（最大报文段）：TCP 层的数据大小，约为 MTU - 40。
Window Scaling：TCP窗口放大，支持高带宽延迟网络。
Nagle 算法：合并小包发送，降低拥塞，延迟更高。

### Q4. 简述 DNS 原理，递归 vs 迭代查询

递归查询：客户端 → 本地DNS 一口气查到最终IP（递归帮你走完）。
迭代查询：本地DNS 向根、TLD、权威DNS一跳一跳查（DNS服务器负责迭代）。

### Q5. 什么是 ARP, DHCP, NAT, VLAN, 子网划分

ARP：IP → MAC 映射，二层通信。
DHCP：动态分配IP地址。
NAT：私网 → 公网地址转换。
VLAN：逻辑隔离二层广播域。
子网划分：CIDR 记法（如 192.168.1.0/24）控制主机数与网络规模。

## 网络性能与调优

### Q6. Linux 下如何查看网络连接和延迟（如 `ss`, `netstat`, `ping`, `traceroute`, `iperf`, `tcpdump`）

- `ss -tuna` / `netstat -anp`：查看TCP/UDP连接
- `ping`：ICMP往返延迟（RTT）
- `traceroute`：每一跳延迟
- `iperf3`：TCP/UDP 吞吐测试
- `tcpdump`：抓包分析（过滤如 `tcp port 80`）

### Q7. 如何排查高 RTT、丢包、网络拥塞

`ping` 看波动 & 丢包

`traceroute` 定位在哪一跳异常

`iperf` 对端吞吐是否正常

`tcpdump` 看是否有重传、窗口小

**指标关注**：

- RTT 大 → 拥塞或链路延迟
- 丢包高 → 链路质量差 or buffer 溢出
- 窗口小 → 滞后于 BDP，需 window scaling

### Q8. TCP 拥塞控制四阶段（慢启动、拥塞避免、快重传、快恢复）

**慢启动（Slow Start）**：初期指数增长 cwnd，收到一个ack增加一个新窗口。初始拥塞窗口（cwnd）一般为 1~10 个 MSS，每收到一个 ACK，**窗口加倍**（指数增长），快速探测带宽，但风险高。

**拥塞避免**：线性增长 cwnd。当 cwnd ≥ ssthresh（慢启动阈值）时，进入拥塞避免。每 RTT 增长**线性**（每轮 +1 MSS），稳健但增长慢。

**快重传**：收到3个重复ACK，立即重传。不等超时，若收到接收方**三个重复 ACK**（说明某个包丢了）。立即重发丢失的数据包。

**快恢复**：减半 cwnd，进入拥塞避免而非重头来。快重传后，说明网络可用，但有拥塞。避免 cwnd 退回 1，减少性能损失。调整策略：

- ssthresh = cwnd / 2
- cwnd = ssthresh（或 ssthresh + 3）
- 进入**拥塞避免阶段**而不是重回慢启动

## 高频下的网络优化思路

### Q9. busy-polling、DPDK 简介

**busy-polling**：CPU轮询收包，跳过中断，提高低延迟能力（可用 `SO_BUSY_POLL`）

**DPDK（Data Plane Development Kit）**：

- 用户态绕过内核协议栈
- 零拷贝 + 多核并发 + 高吞吐
- 适用于高频交易、SDN

### Q10. 网络延迟的精细拆解（用户空间 → 内核 → 网卡 → 光纤延迟）

1. **用户空间 → 系统调用延迟**
2. **内核协议栈处理**（TCP/IP）
3. **驱动层 → 网卡（NIC）**
4. **物理传输**：
   - 光纤延迟约 5 μs/km
   - 交换/路由器处理 + 排队延迟（Bufferbloat）

> 高频系统中，每个阶段都要优化，如：
>
> - **绑定 CPU core**
> - **关闭 Nagle**
> - **用 `SO_RCVBUF` / `SO_SNDBUF` 调整 buffer**