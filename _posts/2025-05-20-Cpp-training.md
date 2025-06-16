---
title: "C++ 常见语法面试题复习手册"
date: 2025-05-20
categories:
  - Language
tags:
  - Cpp
excerpt: "一些常见的cpp面试问题"
---



# C++ 常见语法面试题复习手册

## 🌟 基础语法与语言特性

### static 变量的作用

* **函数内**：生命周期扩展至程序结束，作用域仅限函数。
* **类内**：类变量，所有实例共享。
* **文件作用域**：限制符号仅在当前编译单元可见。

### const vs #define

* `const`：类型安全，编译期常量，有作用域。
* `#define`：预处理阶段替换，无类型检查。

### 引用 vs 指针

* 引用不可为 null，不可重绑定，更安全。
* 指针可为 null，可重新赋值。

### namespace 命名空间

* 作用：防止命名冲突。
* 推荐使用别名或在函数内局部使用 `using`。

### 类型转换

* C 风格：`(int)x`（不推荐）
* C++ 风格：`static_cast`, `dynamic_cast`, `const_cast`, `reinterpret_cast`

### auto 类型推导

* 自动根据初始化推导类型。
* 无法用作函数参数类型。

### decltype 推导表达式类型

* `decltype(expr)` 不会计算 `expr`，仅提取其类型。

---

## 🧠 面向对象语法

### struct vs class

* `struct` 默认 public，`class` 默认 private。
* 用法一致，语义上 `struct` 常用于数据结构。

### 构造函数类型

* 默认构造：无参或默认值。
* 拷贝构造：值传递或返回。
* 移动构造：转移资源（`T&&` + `std::move`）。

### 虚析构函数

* 必须为虚，确保 delete 派生类时调用完整析构流程。

### 多继承 & 虚继承

* 多继承可能产生菱形继承问题。
* 虚继承使用 `virtual` 保证共享唯一基类实例。

### 虚函数 & vtable

* 支持运行时多态。
* 每个多态类对象通过 `vptr` 访问虚函数表。

### 重载 vs 重写

* 重载（overload）：同作用域、同名、不同参数。
* 重写（override）：继承中重新定义虚函数，签名必须完全匹配。

### 抽象类 & 纯虚函数

* 抽象类不能实例化，用作接口。
* `virtual void foo() = 0;`

---

## 🚀 高级语法和特性

### 模板

* 支持泛型编程。
* 特化：为特定类型提供不同实现。

### 智能指针

* `unique_ptr`：独占所有权，不能拷贝。
* `shared_ptr`：引用计数。
* `weak_ptr`：观察者，解决循环引用问题。

### 右值引用 & 移动语义

* `T&&`：绑定右值对象。
* `std::move(x)`：将变量转换为右值引用，允许移动。

### Lambda 表达式

```cpp
[=] 捕获全部外部变量（值）
[&] 捕获全部外部变量（引用）
[x, &y] 捕获特定变量
[this] 捕获当前对象
```

### STL 容器

* `vector`：动态数组，随机访问快。
* `list`：双向链表，插入删除快，访问慢。
* `map`：红黑树；`unordered_map`：哈希表。

### 异常处理

```cpp
try { throw ...; } catch (...) { ... }
noexcept: 声明函数不抛异常，可优化性能。
```

### 多线程与同步

```cpp
std::thread t(func);
t.join();
std::mutex mtx;
std::lock_guard<std::mutex> lock(mtx);
```
