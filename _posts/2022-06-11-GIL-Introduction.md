---
title: GIL Introduction
date: 2022-06-11
excerpt: "[Real Python Tutorials] What Is the Python Global Interpreter Lock (GIL)?"
categories:
   - Language
tags:
   - Python
   - GIL

---



# Introduction

​Python全局解释器锁，又叫GIL(Global Interpreter Lock)，实际就是一个互斥量，用于保证在同一个时间点，只有一个线程可以管控Python解释器。这就意味着在任何时间点，Python中只有一个线程可以处于运行状态。GIL对于开发单线程程序的开发者是不可见的，但是对于CPU相关的多线程程序，GIL就有可能成为Python的性能瓶颈。

​        而现鉴于如今大部分计算机都有多核CPU以支持多线程处理功能，只允许单线程运行的GIL就成为了Python最为“臭名昭著”的语言特性。而在这篇文章，你会知道GIL是如何影响着Python程序的性能，以及如何避免其导致的程序性能瓶颈。

# 0x01 GIL到底为Python解决了什么问题

​        Python在内存管理中，使用了引用计数的方式来管理变量。这种管理方式中，对于每个由Python解释器所创建的对象，都会有一个引用数来跟踪对于对象的引用次数，当这个数值变为0，对象所占用的内存空间就会被释放。

​        下面可以通过一段简单的用例来展示这种计数方式的运作：

```python
import sys
a = []
b = a
print(sys.getrefcount(a))
```

​        上面这段用例中，对于空数组的对象的引用计数是3，这个数组对象同时在变量a,b和getrefcount的函数参数三个位置所调用。

​        说回GIL，这种引用计数的设计用途，其实是为了避免两个进程同时操作同一个变量所引发的竞态现象。如果不添加GIL，这种情况下，就有可能导致一部分Python变量所占用的内存永远不被释放，或者更糟糕，会导致在变量仍然存在情况下，提前释放了内存占用。这种情况下程序崩溃和或是一些比较诡异和不可稳定复现的bug就会出现在Python程序运行过程中。

# 0x02 GIL成为解决方案的原因

​        所以，GIL这样一个看起来有点别扭的解决方案，为什么在Python中得以运用，而Python开发者使用GIL作为解决方案，是否又是一个坏决定呢？Larry Hastings的采访中，他说实际上正是GIL这个设计的应用才保证了Python得以如此流行。Python实际早在线程这一个概念还没出现的时候就已经在酝酿之中了。Python的设计思路就是要尽可能得简单易用，从而保证越来越多的开发者能更快地进行开发。

​        而Python的许多扩展功能都需要兼容已有的一些由C语言编写的库，而为了避免出现不稳定的不变更，这些C语言扩展需要一个线程安全的内存管理方案，而GIL正好提供了这一可能。GIL易于实现，且易于添加到添加到Python当中。同时，由于只有一个线程锁需要管理，这一方式反而为单线程的程序提供了一定的性能提升。

​        为了便于integrate，C语言库本身是不提供线程安全的，而这些C语言扩展的使用正式Python可以被诸多社区轻松接受的原因之一。正如上文所说，GIL其实就是一个朴素但是有效的解决方案，为早期CPython的开发者们提供了兼容易用和线程安全两方面因素的解法。

# 0x03 多线程对于Python程序的影响

​        当你去查看一些经典的Python程序，或是任何其他语言的代码，就会发现CPU需求的程序和IO需求的程序，是由一定区别的。更CPU依赖型程序往往会把CPU的占用吃到极限，其中包括一些进行数学计算的程序，例如矩阵惩罚，搜索，图像处理等。而更IO依赖型程序则是将大部分时间用于等待来自于用户、文件、数据库、网络的IO中断。这些程序将大量的时间用于等待他们的数据源，因为数据源往往也需要完成其自身的处理才能开始IO。例如，用户在输入时，对输入内容的思考，或是数据库查询时查询程序的运行。

​        这里用一个简单的CPU依赖型的程序进行展示

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

​        在一台具有4核CPU的计算机上运行这个单线程程序，耗时6.2s

```shell
$ python single_threaded.py
# Time taken in seconds - 6.20024037361145
```

​        现在对程序稍作修改，使用两个并行线程进行计算

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

​        再次执行时，这个多线程程序时间不减反增，到了6.9s

```shell
$ python multi_threaded.py
# Time taken in seconds - 6.924342632293701
```

​        可以看到两个程序时间十分相近，因为多线程版本的程序，实际上会被GIL锁住，并不会真正并行运行。而对于IO依赖的程序，这种锁则影响很小。因为在大部分等待IO的时间里，GIL实际上是被多个线程共享的状态（没有线程独占GIL锁）。

​        此外，就像给出的例子那样，对于一个完全CPU依赖的程序（例如处理图片），在GIL的影响下，程序不仅会变为单线程运行，甚至还比直接按单线程编写的程序效率更低，时间更久。这种低效，正是线程获取、释放GIL锁造成的开销。

> p.s. 个人实验中，这两段程序在Python 3.6.9中执行结果还是差出了0.2s，应该是Python3对此做过一些优化

```shell
$ python3 single_threaded.py 
# Time taken in seconds - 3.01605224609375
$ python3 multi_threaded.py 
# Time taken in seconds - 2.8165364265441895
```

# 0x04 GIL无法移除的原因

​        尽快Python的开发者们收到了不少和GIL相关的抱怨，但是Python实在是过于流行，各种各样的开发者在此基础上开发了无数的程序，所以GIL移除也必然会带来兼容性问题（即使Python2和Python3的升级，都带来不少问题）。

​        而从技术角度看，GIL自然是可以移除的，很多开发者和研究者都尝试过移除GIL，但是也无一例外地都破坏了目前已有地一些C语言组件，这些组件都是很依赖GIL所提供的线程安全特性。当然，也有很多其他解决方案来提供GIL所支持的线程安全特性，但都是以牺牲单线程程序和多线程IO程序的性能为代价的。毕竟没人会想让自己之前开发过的程序在升级Python版本后反而越跑越慢，所以这些方案就都被毙掉了。

​        Python的创始人和BDFL(Benevolent Dictator For Life)，Guido van Rossum也在2007九月社区的一篇[文章](https://www.artima.com/weblogs/viewpost.jsp?thread=214235)中给出了他对这件事的看法。

> “I’d welcome a set of patches into Py3k **only if** the performance for a single-threaded program (and for a multi-threaded but I/O-bound program) **does not decrease**”

​        而他定下的这个性能标准至今仍未有方案可以达成。

# 0x05 Python3不移除GIL的原因

​        Python 3 确实是一个从头起步来更新语言特性的机会，从而逐步破除目前C扩展程序的限制。但这样的更新，就需要在用Python 3运行程序时，更新原有Python 2程序中的一些接口。这种程序更新，也导致了Python 3的一些早期版本被社区接受的比较慢。

​        但是GIL又为何没有被Python 3 更新呢？

​        移除GIL将会导致Python 3运行单线程程序的性能比Python 2更低，这种性能降低的结果自然是不能被大部分人接受的。同时不可否认的是，Python语言对于运行单线程程序的良好性能确实时受益于GIL的。所以，最终GIL在Python 3中依然保留了下来。

​        但Python 3还是为目前的GIL带来了一个巨大的提升。我们之前讨论了GIL对完全CPU依赖型和完全IO依赖型程序影响的讨论，但是我们没有谈到同时受CPU和IO影响的一类程序。这类程序中，Python的性能降低大都是由于IO程序因无法从CPU依赖型线程那里获得GIL而导致饿死（stave）。这种现象的起源则是由于Python内部对于GIL的管理机制造成的，Python内部会强制一个线程只有经过一个固定时间间隔才会强制释放GIL，而当没有其他线程请求GIL时，原来的线程方可继续使用GIL。

```python
import sys
# The interval is set to 100 instructions:
sys.getcheckinterval()
```

这种GIL释放机制的问题在于，大多数时间里CPU依赖型线程会比其他线程更快获得GIL。David Beazely的[博客](http://www.dabeaz.com/blog/2010/01/python-gil-visualized.html)中对这种现象还有一个可视化展示。在2009年，这个问题在Python 3.2中被Antoine Pitrou修复了，新的[GIL释放机制](http://www.dabeaz.com/blog/2010/01/python-gil-visualized.html)中，解释器会先查看目前系统中因未获得GIL而挂起的线程数，然后限制原有线程获得GIL，以保证其他线程有机会在原有线程之前获得GIL。

# 0x06 怎么解决GIL的影响

## Multi-processing vs multi-threading

​        目前最常用的解决方案就是使用多进程来代替多线程，诶个Python 进程都会有自己的Python解释器和独立的内存空间，Python中multiprocessing模块就是为此而生的，这里用multiprocessing模块做个例子

```python
from multiprocessing import Pool
import time

COUNT = 50000000
def countdown(n):
    while n>0:
        n -= 1

if __name__ == '__main__':
    pool = Pool(processes=2)
    start = time.time()
    r1 = pool.apply_async(countdown, [COUNT//2])
    r2 = pool.apply_async(countdown, [COUNT//2])
    pool.close()
    pool.join()
    end = time.time()
    print('Time taken in seconds -', end - start)
```

```shell
$ python multiprocess.py
# Time taken in seconds - 4.060242414474487
```

​        可以看到性能相比于multi-threaded版本有了2秒多的提升，但是这个时间也没有完全达到减半的效果，因为进程管理也会有自己的时间损耗，多进程比多线程的管理损耗要大，所以在使用多进程开发时，一定要对此有所准备。

## Alternative Python interpreters

​        Python的解释器实际上并非只有CPython一个版本，常见的还有由Java编写的Jython，C#编写的IronPython，Python编写的PyPy。GIL只存在于CPython这种原生的Python实现，如果你的程序和对应的library在其他版本的解释器中也能运行，那GIL就不再是不可避免的限制了。

## Just wait it out

​        尽管许多Python用户依赖着由GIL带来的单线程程序的性能提升，多线程用户无需为此烦恼，许多聪明的开发者目前已经在致力于移除CPython中的GIL，其中一个比较有名的解决方案就是[Gilectomy](https://translate.google.com/website?sl=auto&tl=en&hl=en&u=https://github.com/larryhastings/gilectomy)。

# 结语

​        Python中的GIL问题一直都被当做一个比较迷惑和复杂的问题，也被诸多面试官所喜爱，但是作为一个Pythonista，你只有在开发C语言组件或者编写CPU依赖型的多线程程序才会受影响。对于个人的编程开发，这篇文章基本覆盖了你所需知道GIL的所有事情，如果你希望从更底层角度去理解GIL内部工作原理，我会推荐你去看David Beazley的[Understading the Python GIL](https://translate.google.com/website?sl=auto&tl=en&hl=en&u=https://youtu.be/Obt-vMVdM8s)。

## Reference

- [What Is the Python Global Interpreter Lock (GIL)?](https://realpython.com/python-gil/#the-impact-on-multi-threaded-python-programs)