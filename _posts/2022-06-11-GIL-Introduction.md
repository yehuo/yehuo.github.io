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

# 0x02 GIL成为解决方案的原因

所以，GIL这样一个看起来有点别扭的解决方案，为什么在Python中得以运用，而Python开发者使用GIL作为解决方案，是否又是一个坏决定呢？Larry Hastings的采访中，他说实际上正是GIL这个设计的应用才保证了Python得以如此流行。Python实际早在线程这一个概念还没出现的时候就已经在酝酿之中了。Python的设计思路就是要尽可能得简单易用，从而保证越来越多的开发者能更快地进行开发。

而Python的许多扩展功能都需要兼容已有的一些由C语言编写的库，而为了避免出现不稳定的不变更，这些C语言扩展需要一个线程安全的内存管理方案，而GIL正好提供了这一可能。GIL易于实现，且易于添加到添加到Python当中。同时，由于只有一个线程锁需要管理，这一方式反而为单线程的程序提供了一定的性能提升。

为了便于integrate，C语言库本身是不提供线程安全的，而这些C语言扩展的使用正式Python可以被诸多社区轻松接受的原因之一。

所以，正如上文所说，GIL其实就是一个朴素但是有效的解决方案，为早期CPython的开发者们提供了兼容易用和线程安全两方面因素的解法。

# 0x03 多线程对于Python程序的影响

当你去查看一些经典的Python程序，或是任何其他语言的代码，就会发现CPU需求的程序和IO需求的程序，是由一定区别的。更依赖CPU的程序往往会把CPU的占用吃到极限，其中包括一些进行数学计算的程序，例如矩阵惩罚，搜索，图像处理等。而更依赖IO的程序则是将大部分时间用于等待来自于用户、文件、数据库、网络的IO中断。这些程序将大量的时间用于等待他们的数据源，因为数据源往往也需要完成其自身的处理才能开始IO。例如，用户在输入时，对输入内容的思考，或是数据库查询时查询程序的运行。

这里用一个简单的依赖CPU的程序进行展示
```python
# single_threaded.py
import time
from threading import Thread

COUNT = 50000000

def countdown(n):
    while n>0:
        n -= 1

start = time.time()
countdown(COUNT)
end = time.time()

print('Time taken in seconds -', end - start)
```

在一台具有4核CPU的计算机上的到如下结果

```
$ python single_threaded.py
Time taken in seconds - 6.20024037361145
```

现在对程序稍作修改，使用两个并行线程进行计算

```shell
# multi_threaded.py
import time
from threading import Thread

COUNT = 50000000

def countdown(n):
    while n>0:
        n -= 1

t1 = Thread(target=countdown, args=(COUNT//2,))
t2 = Thread(target=countdown, args=(COUNT//2,))

start = time.time()
t1.start()
t2.start()
t1.join()
t2.join()
end = time.time()

print('Time taken in seconds -', end - start)
```

再次执行时，可以得到如下结果：

```
$ python multi_threaded.py
Time taken in seconds - 6.924342632293701
```


> p.s. 个人实验中，这两段程序在Python 3.6.9中执行结果还是差出了0.2s

```shell
python3 single_threaded.py 
# Time taken in seconds - 3.01605224609375
python3 multi_threaded.py 
# Time taken in seconds - 2.8165364265441895
```

可以看到两个程序时间十分相近，因为多线程版本的程序，实际上会被GIL锁住，并不会真正并行运行。而对于IO依赖的程序，这种锁则影响很小。因为在大部分等待IO的时间里，GIL实际上是被多个线程共享的状态（没有线程独占GIL锁）。

此外，就像给出的例子那样，对于一个完全CPU依赖的程序（例如处理图片），在GIL的影响下，程序不仅会变为单线程运行，甚至还比直接按单线程编写的程序效率更低，时间更久。这种低效，正是线程获取、释放GIL锁造成的开销。

# 0x04 GIL为啥一直没被移除

# 0x05 Python3中GIL为啥还在

# 0x06 怎么解决Python GIL的影响

## Reference

- [What Is the Python Global Interpreter Lock (GIL)?](https://realpython.com/python-gil/#the-impact-on-multi-threaded-python-programs)