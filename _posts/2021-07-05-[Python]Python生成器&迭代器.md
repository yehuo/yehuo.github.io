---
title: Python生成器 & 迭代器
date: 2021-07-05
excerpt: "Generator & Iterator"
categories: Blog
tags: [Python, Generator, Iterator]
---



## 生成器 Generator

### 定义

如果列表元素可以按照某种算法推算出来，那我们是否可以在循环的过程中不断推算出后续的元素呢？这样就不必创建完整的list，从而节省大量的空间。在Python中，这种一边循环一边计算的机制，称为生成器：generator

### 使用()编写

要创建一个generator，有很多种方法。第一种方法很简单，只要把一个列表生成式的`[]`改成`()`，就创建了一个generator

```python
L = [x * x for x in range(10)]
g = (x * x for x in range(10))
```

### 使用yield编写

函数是顺序执行，遇到`return`语句或者最后一行函数语句就返回。而变成generator的函数，在每次调用`next()`的时候执行，遇到`yield`语句返回，再次执行时从上次返回的`yield`语句处继续执行。

```python
def fib(max):
	n, a, b = 0, 0, 1
	while n < max:
    	yield b
        a, b = b, a + b
        n = n + 1
    return 'done'
```

### 调用方法

- next方法

  当使用`()`语法编写的生成器生成最后一个元素后，再次调用next方法会产生`StopIteration`错误。使用`yield`编写的生成器，当执行到`return`语句时，一样会产生`StopIteration`错误，并退出。

  ```python
  f= fib(5)
  for i in range(6):
      x=next(f)
      print(x)
  ```

- for循环调用

	当使用`()`语法编写的生成器生成最后一个元素后，循环会自动结束。对于`yield`编写的生成器，当执行到`return`语句时，循环会自动退出。

	```python
	for n in g:
	    print(n)
	```

## 迭代器 Iterator

### 定义

- 可以直接作用于`for`循环的对象统称为可迭代对象：`Iterable`。

- 可以被`next()`函数调用并不断返回下一个值的对象称为迭代器：`Iterator`。

### 区分可迭代对象与迭代器

```python
from collections.abc import Iterator
isinstance((x for x in range(10)), Iterator)
from collections.abc import Iterable
isinstance([], Iterable)
```

生成器都是`Iterator`对象，但`list`、`dict`、`str`虽然是`Iterable`，却不是`Iterator`。把`list`、`dict`、`str`等`Iterable`变成`Iterator`可以使用`iter()`函数。

Python的`Iterator`对象表示的是一个数据流，`Iterator`对象可以被`next()`函数调用并不断返回下一个数据，直到没有数据时抛出`StopIteration`错误。可以把这个数据流看做是一个有序序列，但我们却不能提前知道序列的长度，只能不断通过`next()`函数实现按需计算下一个数据，所以`Iterator`的计算是惰性的，只有在需要返回下一个数据时它才会计算。`Iterator`甚至可以表示一个无限大的数据流，例如全体自然数。而使用list是永远不可能存储全体自然数的。

