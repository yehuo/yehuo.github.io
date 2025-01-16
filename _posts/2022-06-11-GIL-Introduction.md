---
title: GIL Introduction
date: 2022-06-11
excerpt: "What is GIL and Why we have to bare the GIL in Python?"
categories:
    - Language
tags:
    - Python
---



# 0x01 什么是 GIL？

**​Python 全局解释器锁**，又称为 GIL (Global Interpreter Lock)，本质上是一个互斥量。用于保证在同一个时间点，只有一个线程可以调用 Python 解释器。这也意味着，Python 解释器也同一时间节点上只可以在一个线程中运行。

对于单线程程序来说，GIL 是不可见的。但是对于 CPU 依赖的多线程程序，GIL 就有可能成为 Python 的性能瓶颈。鉴于现在大部分计算机都有多核 CPU 的配置，只支持单线程运行的 GIL 就成为 Python 解释器最为“臭名昭著”的语言特性。

# 0x02 **Python** 为什么要用 GIL？

在处理内存管理问题时，Python 解释器使用了**引用计数**的方式来管理变量，即每个由 Python 解释器创建的对象，都会构建一个**引用数**属性来跟踪代码中对于该对象的引用次数。当引用数变为 0 时，对象占用的内存空间就会被释放。

下面举个例子来看这种计数方式：

```python
import sys
a = []
b = a
print(sys.getrefcount(a))
```

代码中对最开始声明的 `[]` 对象的引用计数是 3，这个对象同时在变量 a，b 和 GetRefCount 的函数参数三个位置所调用。

**但引用计数的功能只能在单线程调用时实现，当多线程出现后，引用计数变量的管理上就会出现抢占现象。**在不添加 GIL 的情况下，解释器中部分变量所占用的内存可能永远不被释放，又或者在变量仍然在用情况下，解释器就提前释放了变量所在的内存。

# 0x03 GIL 成为解决方案的原因

在 Python 社区知名贡献者Larry Hastings的[采访](https://www.youtube.com/watch?v=fgWUwQVoLHo)中，他说实际上正是GIL这个设计的应用才保证了 Python 得以如此流行。Python 实际早在线程这一个概念还没出现的时候就已经在酝酿之中了。**Python 的设计思路也是优先变得尽简单易用，保证尽可能多的开发者能获得更好的开发效率。**

鉴于 Python 的许多扩展功能都需要兼容一些 C 语言编写的库，为了避免出现不稳定的不变更，这些 C 语言扩展需要一个线程安全的内存管理方案。

而 GIL 正好提供了这一可能。GIL 易于实现，且易于添加到添加到 Python 当中。此外，由于只有一个线程锁需要管理，GIL 反而为单线程的程序提供了一定的性能提升。

为了更大程度上与硬件的集成，C 语言库本身是不提供线程安全保证的，而这些 C 语言扩展的使用正式 Python 可以被诸多社区轻松接受的原因之一。正如上文所说，GIL 其实就是一个朴素但是有效的解决方案，为早期 CPython 变得易用，且能支持线程安全。

# 0x04 多线程对于 Python 程序的影响

​现实中大部分程序被分为 **CPU 依赖型程序**和 **IO 依赖型程序**，二者是有一定区别的。

CPU 依赖型程序往往会把CPU的占用率提升到极限，包括一些进行数学计算的程序，例如矩阵乘法，目录搜索，图像处理等。

IO 依赖型程序则是将大部分 CPU 时间用于等待来自于用户、文件系统、数据库、网络的 IO 中断。IO 依赖型程序会将大量的运行时间用于等待数据源输入，例如用户打字、数据库检索程序分析索引等。

​下面编写一个简单的 CPU 依赖型程序：

```python
# single_threaded.py
import time


def countdown(n):
    while n > 0:
        n -= 1


COUNT = 50000000
start = time.time()
countdown(COUNT)
end = time.time()
print('Time taken in seconds -', end - start)
```

在一台4核 CPU 的计算机上运行这个程序，耗时 **6.2s**。

```shell
$ python single_threaded.py
# Time taken in seconds - 6.20024037361145
```

现在使用多线程对这个程序进行优化：

```shell
# multi_threaded.py
import time
from threading import Thread


def countdown(n):
    while n > 0:
        n -= 1


COUNT = 50000000
t1 = Thread(target=countdown, args=(COUNT // 2,))
t2 = Thread(target=countdown, args=(COUNT // 2,))
start = time.time()
t1.start()
t2.start()
t1.join()
t2.join()
end = time.time()

print('Time taken in seconds -', end - start)
```

再次执行时，多线程版本程序时间不减反增，达到了 **6.9s**

```shell
$ python multi_threaded.py
# Time taken in seconds - 6.924342632293701
```

两个程序的运行时间十分相近，因为多线程版本的程序中，Python 解释器的运行会被 GIL 锁住，并不会真正开启额外的线程。

对于一个 CPU 依赖型程序（例如处理图片），在 GIL 的影响下，Python 程序不仅会变为单线程运行，甚至还比单线程运行的程序效率更低。因为在不同线程上获取、释放 GIL 往往会对解释器造成的开销。

不过上面的执行结果是基于 Python2 的，通过 Python3.6.9 执行时，多线程版本又比单线程版本快了 **0.2s**，因为 Python3 实际上对 GIL 锁做一些优化，在后文中会提到。

```shell
$ python3 single_threaded.py 
# Time taken in seconds - 3.01605224609375
$ python3 multi_threaded.py 
# Time taken in seconds - 2.8165364265441895
```

# 0x05 GIL 无法移除的原因

从技术角度看，GIL 绝对是可以移除的，但 Python 必须要承担额外的代价。

事实上，Python 社区的很多开发者都尝试过移除 GIL，但他们无一例外地都破坏了已有的一些 C 语言组件，这些组件都是依赖 GIL 所提供的线程安全特性才能工作。

这时候开发者不得不引入其他解决方案来实现原来由 GIL 提供的线程安全特性，但这些方案都是以牺牲单线程程序和 IO 依赖型多线程程序的性能为代价的。没人会想让自己之前开发过的程序在升级 Python 版本后反而越跑越慢，所以这些方案最终都被废弃了。

Python 的创始人 Guido van Rossum，也是 Python3 最主要的开发者，在 Artima 社区写了一片 [Blog](https://www.artima.com/weblogs/viewpost.jsp?thread=214235) 来回复开发者要求清除 GIL 的请求。

> “I’d welcome a set of patches into Py3k only if the performance for a single-threaded program (and for a multi-threaded but I/O-bound program) does not decrease.”

而他所提到的**不牺牲单线程性能**这一标准，到 Python3 发布时仍未有方案可以达成。

# 0x06 Python3 不移除GIL的原因

Python3 确实是一个重新开始的机会，但这个过程中， feature 的更新往往需要变更一些 C 扩展库，原有 Python2 的代码就需要通过额外的适配过程才能运行的Python3中，这就导致了 Python3 的一些早期版本被开发者接受得非常缓慢。

但 GIL 在 Python3 中却被保留了下来，因为移除 GIL 将会导致 Python3 运行单线程程序比 Python2 更慢，这种性能降低是不能被开发者所接受的。GIL 对于单线程程序执行效率的支持毋庸置疑。

虽然没有移除 GIL，但 Python3 为 GIL 的执行效率带来了巨大的提升。上面我们讨论过 GIL 对 CPU 依赖型程序和 IO 依赖型程序的影响，但是没有谈到同时受 CPU 和 IO 影响的一类程序。

这类程序中，Python 解释器的性能降低主要来源于执行 IO 依赖型程序的线程无法从执行 CPU 依赖型的线程那里获得 GIL 锁而导致的饿死（stave）现象。再追溯期根源则在于 Python 解释器内部对 GIL 轮换管理机制，**Python 解释器内部会强制线程在获得的 CPU 时间片耗尽时强制释放 GIL，当没有其他线程请求 GIL 时，原来的线程方可继续使用 GIL。**

```python
import sys


# The interval is set to 100 instructions:
sys.getcheckinterval()
```

这种 GIL 轮换机制的问题在于，大多数时间里 CPU 依赖型线程会比其他线程更快获得 GIL。在 David Beazely 的 [Blog](http://www.dabeaz.com/blog/2010/01/python-gil-visualized.html) 中对这种现象还有一个可视化展示。

![Starve_Demo](\images\20220611\starve_demo.png)

这个问题在 Python 3.2 中被 Antoine Pitrou 修复了，在他编写的 [GIL 返工方案](https://mail.python.org/pipermail/python-dev/2009-October/093321.html)中，解释器会先查看目前系统中因未获得 GIL 而挂起的线程数，然后限制原有线程获得 GIL，以保证其他线程有更多机会优先获得 GIL。

# 0x07 如何在编程中避免 GIL 对性能的限制

## 1. 多进程代替多线程

目前最常用的解决方案就是使用多进程来代替多线程，每个 Python 解释器进程都会有独立的内存空间，Python 中 **multiprocessing 模块**就是为此而生的，这里使用多进程模块来重写之前的多线程功能。

```python
from multiprocessing import Pool
import time

COUNT = 50000000


def countdown(n):
    while n > 0:
        n -= 1


if __name__ == '__main__':
    pool = Pool(processes=2)
    start = time.time()
    r1 = pool.apply_async(countdown, [COUNT // 2])
    r2 = pool.apply_async(countdown, [COUNT // 2])
    pool.close()
    pool.join()
    end = time.time()
    print('Time taken in seconds -', end - start)
```

多进程版本的计数程序耗费时间为 **4.06s**

```shell
$ python multiprocess.py
# Time taken in seconds - 4.060242414474487
```

相比于多线程版本，新版本获得了 2 秒多的提升。不过双进程版本也并未达到耗时减半的效果，因为进程管理也会有时间损耗，而且进程间切换的耗费比线程间切换要更大，所以某些情况下使用多进程反而会降低程序的执行效率。

## 2. 使用 CPython 以外的解释器

Python 解释器实际上并非只有 CPython 一个版本，常见的还有由 Java 编写的 Jython，C# 编写的 IronPython，Python 编写的 PyPy。

GIL 只存在于 CPython 这种原生的 Python 实现，如果程序和所需的 Library 能在其他版本的解释器中运行，那 GIL 就不是必须接受的限制。

## 3. 等待社区的优化

尽管许多 Python 用户依赖着由 GIL 带来的单线程程序的性能提升，多线程用户无需为此烦恼，许多聪明的开发者目前已经在致力于移除 CPython 中的 GIL，其中一个比较有名的解决方案就是 [Gilectomy](https://translate.google.com/website?sl=auto&tl=en&hl=en&u=https://github.com/larryhastings/gilectomy)。

# Conclusion

Python 解释器中 GIL 的存在一直都被当做 Python 语言的问题。但实际上只有在开发 C 语言组件或者编写 CPU 依赖型的多线程程序才会受影响。

如果希望从更底层角度去理解 GIL 内部工作原理，推荐阅读 David Beazley 的 [Understading the Python GIL](https://translate.google.com/website?sl=auto&tl=en&hl=en&u=https://youtu.be/Obt-vMVdM8s)。

---

## Reference

- [What Is the Python Global Interpreter Lock (GIL)?](https://realpython.com/python-gil/#the-impact-on-multi-threaded-python-programs)
- [It isn't Easy to Remove the GIL](https://www.artima.com/weblogs/viewpost.jsp?thread=214235)
- [The Python GIL Visualized](https://www.dabeaz.com/blog/2010/01/python-gil-visualized.html)
- [[Python-Dev] Reworking the GIL](https://mail.python.org/pipermail/python-dev/2009-October/093321.html)
- [Understading the Python GIL](https://translate.google.com/website?sl=auto&tl=en&hl=en&u=https://youtu.be/Obt-vMVdM8s)