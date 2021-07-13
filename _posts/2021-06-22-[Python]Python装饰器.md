---
title: Python装饰器
date: 2021-06-22
excerpt: ""
categories: Blog
tags: [Python, Decorator]
---

# Python装饰器

## 主要作用

装饰函数，增强函数功能，抽象各类函数共同要运行的一些功能，避免重复编写。原理在于Python中函数是一等公民，函数也是对象。

## 使用场景

计算程序运算时间，Flask中检验用户是否登录，例如利用装饰器计算函数时间

```python
import time
def time_calc(func):
	def wrapper(*args,**kargs):
        start_time=time.time()
        f=func(*args,**kargs)
        exec_time=time.time()-start_time
       	return f
    return wrapper

@time_calc
def add(a,b):
    return a+b
@time_calc
def sub(a,b):
    return a-b
```

## 使用方法

```python
# 不使用@语法糖
func=decorator(func_name)	# 不传入装饰器参数
func=(decorator(args))(func_time)	# 传入参数，装饰器的装饰器

# 使用@
@decorator
def func():			# 装饰器不传参
    pass

@decorator(args)	# 传参装饰器
def func():
	pass
func()	# 之后即可执行使用装饰过的函数
```

为装饰器传入参数时，装饰器写法（三层函数定义装饰器）

```python
def login(text):
	def decorator(func):
		def wrapper(*args,**kargs):
			print(text)
		return func(*args,**kargs)
	return decorator

@login('args of decorator is added')
def f():
    print('basic func')
```

## 内置装饰器

### @property

用于类中的函数，使函数可以被当作类的一个属性来使用，并获取函数返回值。

```python
class XiaoMing:
    first_name = 'Ming'
    last_name = 'Little'

    @property
    def full_name(self):
        return self.last_name + self.first_name

xiaoming = XiaoMing()
print(xiaoming.full_name)
```



### @staticmethod

静态方法，不需要传入self和cls参数，可以直接使用。在不需要用到与类相关的属性和方法时，就可以用静态方法。

### @classmethod

类方法，不需要传入self参数，但是第一个参数需要为cls。**需要用到与类相关的属性或方法，然后又想表明这个方法是整个类通用的**，而**不是对象特异的**。

## wraps装饰器

在使用wrapper函数编写装饰器后，被装饰后的函数所有的\_\_doc\_\_和\_\_name\_\_等属性就变成了wrapper函数的\_\_doc\_\_和\_\_name\_\_，而原有函数的属性就没有了。

编写装饰器时，对wrapper函数使用wraps装饰器即可恢复原有函数的属性，例如：

```python
from functools import wraps

def decorator(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        """doc of wrapper"""
        print('123')
        return func(*args, **kwargs)

    return wrapper

@decorator
def say_hello():
    """doc of say hello"""
    print('Hi,mates')

print(say_hello.__name__)
print(say_hello.__doc__)
# 输出"say_hello"
# 输出"doc of say hello"
```

