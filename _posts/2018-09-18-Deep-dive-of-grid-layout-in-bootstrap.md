---
title: "Deep dive of grid layout in Bootstrap"
date: 2018-09-18
categories:
  - Frontend
tags:
  - Bootstrap
---



# 0x01 引言

在现代 Web 开发中，响应式设计已经成为标配，而 Bootstrap 作为最流行的前端框架之一，提供了一套强大的栅格系统，让开发者可以轻松构建灵活的响应式页面。本文将详细介绍 Bootstrap 栅格系统的核心概念、使用方法及最佳实践。

# 0x02 栅格系统的基础概念

Bootstrap 的栅格系统是基于 **Flexbox** 实现的，它使用一个 12 列布局，并通过 **行（row）** 和 **列（col）** 来组织内容。

## 1. 栅格结构

一个基本的 Bootstrap 栅格结构通常包含以下三层：

- `.container`：用于包裹所有内容，有 `.container`（固定宽度） 和 `.container-fluid`（全屏宽度）两种模式。
- `.row`：每个栅格布局必须放在 `.row` 中，保证列的正确对齐。
- `.col`：每个 `.col` 都占据相等的宽度，默认情况下所有列平均分配空间。

```html
<div class="container">
  <div class="row">
    <div class="col">Col 1</div>
    <div class="col">Col 2</div>
    <div class="col">Col 3</div>
  </div>
</div>
```

# 0x03 响应式栅格

Bootstrap 提供了 6 种不同的屏幕尺寸断点，每个断点都可以设置不同的列宽：

| 断点名称 | 类名前缀 | 适用范围 |
|----------|------------|----------------|
| Extra small | `col-` | <576px |
| Small | `col-sm-` | ≥576px |
| Medium | `col-md-` | ≥768px |
| Large | `col-lg-` | ≥992px |
| Extra large | `col-xl-` | ≥1200px |
| Extra extra large | `col-xxl-` | ≥1400px |

示例代码：

```html
<div class="container">
  <div class="row">
    <div class="col-sm-6 col-md-4 col-lg-3">列 1</div>
    <div class="col-sm-6 col-md-4 col-lg-3">列 2</div>
    <div class="col-sm-6 col-md-4 col-lg-3">列 3</div>
    <div class="col-sm-6 col-md-4 col-lg-3">列 4</div>
  </div>
</div>
```

在小屏幕（`col-sm-6`）时每行最多两列，在中等屏幕（`col-md-4`）时每行三列，在大屏幕（`col-lg-3`）时每行四列。

# 0x04 列宽控制

## 1. 固定列宽

如果希望指定某列宽度，可以直接在 `.col-{size}-{number}` 中设置，例如：

```html
<div class="row">
  <div class="col-md-8">列 1（占 8 列）</div>
  <div class="col-md-4">列 2（占 4 列）</div>
</div>
```

## 2. 自动列宽

如果不指定列宽，Bootstrap 会自动平均分配空间：

```html
<div class="row">
  <div class="col">列 1</div>
  <div class="col">列 2</div>
</div>
```

# 0x05 栅格对齐方式

## 1. 垂直对齐

使用 `align-items-*` 调整 `.row` 中的列对齐方式：

```html
<div class="row align-items-center">
  <div class="col">列 1</div>
  <div class="col">列 2</div>
</div>
```

对齐方式包括：

- `align-items-start`（顶部对齐）
- `align-items-center`（居中对齐）
- `align-items-end`（底部对齐）

## 2. 水平对齐

使用 `justify-content-*` 来调整 `.row` 中的列的水平排列方式：

```html
<div class="row justify-content-center">
  <div class="col-md-4">Col 1</div>
  <div class="col-md-4">Col 2</div>
</div>
```

可用的水平对齐方式包括：

- `justify-content-start`（左对齐，默认）
- `justify-content-center`（居中对齐）
- `justify-content-end`（右对齐）
- `justify-content-around`（两侧均匀分布）
- `justify-content-between`（两端对齐）

# 0x06 元素自适应：`em` 和 `rem` 单位

在 Bootstrap 中，`em` 和 `rem` 是常见的相对单位，用于定义尺寸、间距等样式。

- `em`：相对于父元素的字体大小。例如，若父元素的 `font-size` 是 `16px`，则 `1.5em` 相当于 `24px`。
- `rem`：相对于根元素（`html` 标签）的 `font-size`。通常浏览器默认 `font-size` 为 `16px`，因此 `1rem` 通常等于 `16px`。

示例：

```css
.element {
  font-size: 1.5em; /* 相对于父元素的字体大小 */
  padding: 1rem; /* 相对于根元素字体大小 */
}
```

使用 `rem` 可以确保不同组件在不同的上下文中保持一致的比例，而 `em` 更适用于局部调整。

# 0x07 总结

Bootstrap 的栅格系统提供了一种简单、高效的方式来构建响应式网页布局。掌握栅格系统的使用，能够大幅提升开发效率，使页面在不同设备上都能完美适配。如果你正在使用 Bootstrap 进行 Web 开发，不妨尝试更多高级功能，比如嵌套栅格、偏移列、顺序控制等，让你的布局更加灵活多变！

---

## Reference

- [Bootstrap Doc](https://getbootstrap.com/docs/4.6/getting-started/introduction/)