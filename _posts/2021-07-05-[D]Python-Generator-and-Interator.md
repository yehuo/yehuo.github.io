---
title: Python Generator and Iterator
date: 2021-07-05
excerpt: ""
categories:
  - Language
tags:
  - Python
---



# 0x01 生成器 Generator

## 什么是生成器

如果列表元素可以通过某种算法动态生成，那是否可以边循环边计算后续的元素，而不需要预先创建完整的列表呢？

在 Python 中，这种 **边循环边计算** 的机制被称为 **生成器 (Generator)**。它能节省大量内存空间，是处理大规模数据或无限序列的强大工具。

## 如何编写一个生成器

### 1. 使用 `()` 语法

最简单的创建生成器的方法是将 **列表生成式** 的 `[]` 替换为 `()`。

```python
# 列表生成式
list_cal = [x * x for x in range(10)]

# 生成器
list_gen = (x * x for x in range(10))
```

### 2. 使用 `yield` 编写更复杂的生成器

当生成逻辑更复杂时，可以通过 **生成器函数** 和 **`yield`** 关键字实现。`yield` 允许函数在每次调用 `next()` 时暂停执行，并返回一个值。下一次调用时，函数会从上次暂停的位置继续执行。

示例代码：生成斐波那契数列

```python
def fib(max):
	n, a, b = 0, 0, 1
	while n < max:
    	yield b
        a, b = b, a + b
        n = n + 1
    return 'done'
```
## 如何调用生成器

### 1. 使用 `next` 获取下一个元素

调用 `next()` 函数逐步获取生成器的下一个值。当生成器耗尽时，会抛出 `StopIteration` 异常。

```python
f = fib(5)
for i in range(6):  # 注意：range(6) 超出生成器范围
    x = next(f)
    print(x)
```

### 2. 使用 `for` 循环调用

`for` 循环会自动处理 `StopIteration` 异常，并在生成器耗尽时结束循环。

```python
for n in list_gen:
    print(n)
```

# 0x02 迭代器 Iterator

## 什么是迭代器

- **可迭代对象 (Iterable)**: 可以直接作用于 `for` 循环的对象，比如 `list`、`dict`、`str` 等。
- **迭代器 (Iterator)**: 可以被 `next()` 函数调用并逐步返回下一个值的对象。

简单来说，迭代器是一种支持惰性计算的数据流，能够在需要时动态生成数据。

## 如何区分可迭代对象与迭代器？
以下代码可以区分一个对象是否是可迭代对象或迭代器：

```python
from collections.abc import Iterator, Iterable

# 判断是否是迭代器
print(isinstance((x for x in range(10)), Iterator))  # True

# 判断是否是可迭代对象
print(isinstance([], Iterable))  # True
```

### 生成器（Iterator）的特殊性

- 生成器是迭代器 (Iterator)。
- 像 list、dict、str 虽然是可迭代对象 (Iterable)，但不是迭代器。如果需要将它们转化为迭代器，可以使用 iter() 函数。

```python
itSamp = iter([1, 2, 3])
print(next(itSamp))  # 输出: 1
```

### 迭代器（Genertor）的特性

- **惰性计算**: 迭代器不会预先生成所有数据，而是按需动态计算下一个数据。
- **无限数据流**: 迭代器可以表示无限大的序列，例如全体自然数，而列表只能表示有限的数据。

```python
def infinite_natural_numbers():
    n = 0
    while True:
        yield n
        n += 1
```
