---
title: "Implement of image insertion in Bootstrap"
date: 2018-09-30
categories:
  - Frontend
tags:
  - Bootstrap
---


# 0x01 HTML 中的图片插入有什么不一样？

Bootstrap 是一个强大的前端框架，提供了多种方式来处理图片。无论是普通图片、响应式图片，还是圆形、缩略图或其他特殊形状的 icon，Bootstrap 都能帮助你快速实现。本篇 Blog 介绍如何在 Bootstrap 中插入不同类型的图片，并重点介绍如何切割 icon 以形成不同的形状。

# 0x02 基本图片插入

## 1. 响应式图片

为了让图片在不同屏幕尺寸下自适应，可以使用 `img-fluid` 类，它会确保图片的最大宽度为 100%，并根据父容器调整高度。

```html
<img src="image.jpg" class="img-fluid" alt="Responsive image">
```

也可以使用 `.img-responsive` 让图片适应父元素的大小：

```html
<img src="image.jpg" class="img-responsive" alt="Responsive image">
```

## 2. 头像与圆形图片

如果需要显示圆形图片，可以使用 `rounded-circle` 类：

```html
<img src="avatar.jpg" class="rounded-circle" alt="Circular image">
```

或者使用 `border-radius: 50%` 手动设置：

```html
<img src="avatar.jpg" style="border-radius: 50%;" alt="Circular image">
```

## 3. 缩略图与圆角图片

使用 `img-thumbnail` 类可以给图片添加边框，使其看起来像一个缩略图。

```html
<img src="thumb.jpg" class="img-thumbnail" alt="Thumbnail image">
```

如果想要图片带有圆角效果，可以使用 `border-radius:6px`：

```html
<img src="image.jpg" style="border-radius: 6px;" alt="Rounded image">
```

# 0x03 图标 (`.icon`) 处理与切割

Bootstrap 并未内置 icon 处理，但我们可以结合 CSS 和 Bootstrap 工具类来自定义 icon 的形状。

## 1. 使用 Font Awesome 或 Bootstrap Icons

可以使用 `Bootstrap Icons` 或 `Font Awesome` 直接插入矢量图标：

```html
<i class="bi bi-alarm" style="font-size: 2rem; color: red;"></i>
```

## 2. 使用 CSS `clip-path` 进行切割

可以使用 `clip-path` 来剪切 icon 形状。例如，将 icon 剪裁成三角形：

```html
<img src="icon.png" class="custom-icon" alt="Triangle icon">
<style>
.custom-icon {
    width: 100px;
    height: 100px;
    clip-path: polygon(50% 0%, 0% 100%, 100% 100%);
}
</style>
```

## 3. 圆形剪裁

除了 `rounded-circle`，我们还可以使用 `clip-path: circle()` 直接剪裁：

```html
<img src="icon.png" class="circle-icon" alt="Circular icon">
<style>
.circle-icon {
    width: 80px;
    height: 80px;
    clip-path: circle(40% at center);
}
</style>
```

## 4. 斜角剪裁

如果想让图片呈现斜切的效果，可以这样实现：

```html
<img src="icon.png" class="angled-icon" alt="Angled icon">
<style>
.angled-icon {
    width: 100px;
    height: 100px;
    clip-path: polygon(0% 0%, 80% 0%, 100% 100%, 20% 100%);
}
</style>
```

# 0x04 背景图片裁剪

如果你的 icon 是背景图片，而不是 `img` 标签，可以使用 `background-image` 配合 `clip-path` 或 `mask-image` 进行处理。

```html
<div class="bg-icon"></div>
<style>
.bg-icon {
    width: 100px;
    height: 100px;
    background-image: url('icon.png');
    background-size: cover;
    clip-path: ellipse(50% 40%);
}
</style>
```

# 0x05 结论

在 Bootstrap 中，除了使用 `rounded-circle`、`img-fluid`、`.img-responsive` 等默认类，我们还可以结合 `clip-path`、`mask-image` 进行更高级的 icon 形状处理。这样不仅可以实现响应式设计，还能让图片更加多样化，适应不同的 UI 需求。

| 类名 | 作用 |
|------|------|
| `.img-fluid` | 让图片宽度自适应父容器 |
| `.img-responsive` | 让图片适应父元素大小 |
| `.img-thumbnail` | 给图片添加边框，形成缩略图效果 |
| `.rounded-circle` | 让图片变成圆形 |
| `border-radius: 6px` | 让图片带有圆角 |
| `border-radius: 50%` | 让图片变成完全的圆形 |
