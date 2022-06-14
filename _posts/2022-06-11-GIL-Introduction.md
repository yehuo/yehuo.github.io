---
title: GIL Introduction
date: 2022-06-11
excerpt: "读到一篇把GIL解释得很清楚得博客，翻译记录一下..."
categories:
    - Language
tags:
    - Python
    - GIL
---


Python全局解释器锁，又叫GIL(Global Interpreter Lock)，实际就是一个互斥量，用于保证在同一个时间点，只有一个线程可以管控Python解释器。这就意味着在任何时间点，Python中只有一个线程可以处于运行状态。GIL对于开发单线程程序的开发者是不可见的，但是对于CPU相关的多线程程序，GIL就有可能成为Python的性能瓶颈。

而现鉴于如今大部分计算机都有多核CPU以支持多线程处理功能，只允许单线程运行的GIL就成为了Python最为“臭名昭著”的语言特性。而在这篇文章，你会知道GIL是如何影响着Python程序的性能，以及如何避免其导致的程序性能瓶颈。

# 0x01 GIL到底为Python解决了什么问题

Python在内存管理中，使用了引用计数的方式来管理变量。这种管理方式中，对于每个由Python解释器所创建的对象，都会有一个引用数来跟踪对于对象的引用次数，当这个数值变为0，对象所占用的内存空间就会被释放。

下面可以通过一段简单的用例来展示这种计数方式的运作：

```python
import sys
a = []
b = a
print(sys.getrefcount(a))
```

上面这段用例中，对于空数组的对象的引用计数是3，这个数组对象同时在变量a,b和getrefcount的函数参数三个位置所调用。

说回GIL，这种引用计数的设计用途，其实是为了避免两个进程同时操作同一个变量所引发的竞态现象。如果不添加GIL，这种情况下，就有可能导致一部分Python变量所占用的内存永远不被释放，或者更糟糕，会导致在变量仍然存在情况下，提前释放了内存占用。这种情况下程序崩溃和或是一些比较诡异和不可稳定复现的bug就会出现在Python程序运行过程中。

# 0x02 GIL为啥被选为解决方案

# 0x03 多线程对于Python程序的影响

# 0x04 GIL为啥一直没被移除

# 0x05 Python3中GIL为啥还在

# 0x06 怎么解决Python GIL的影响

## Reference

- [What Is the Python Global Interpreter Lock (GIL)?](https://realpython.com/python-gil/#the-impact-on-multi-threaded-python-programs)