---
title: 【Bootstrap笔记】栅格布局
date: 2018-09-18
excerpt: "Bootstrap v4.0 栅格布局相关的学习"
categories: Notes
tags: Frontend, Bootstrap
---

内容来自Bootstrap v4中文[官方手册](https://v4.bootcss.com/docs/getting-started/introduction/)，适配于v4.6版本的Bootstrap库。

### 网格属性

`em`和`rem`在Bootstrap里，通常来定义大部分物体的尺寸。但是对于容器宽度和网格切分位置，通常用像素来定义，这样二者就不会因字体变化而发生调整。

- `em`：是相对长度单位。相对于当前对象内文本的字体尺寸。如当前对行内文本的字体尺寸未被人为设置，则相对于浏览器的默认字体尺寸。`em`的值并不是固定的，`em`会继承父级元素的字体大小。

	> 任意浏览器的默认字体高都是16px。所有未经调整的浏览器都符合: 1em=16px。那么12px=0.75em，10px=0.625em。
	>
	> 为了简化font-size的换算，需要在css中的body选择器中声明`Font-size=62.5%`，这就使em值变为 16px\*62.5%=10px, 这样12px=1.2em, 10px=1em。此时，只需要将原来的px数值除以10，然后换上em作为单位就可以定义元素所占像素的大小了。

- `rem`：是CSS3新增的一个相对单位，意指root em。`rem`与`em`的区别在于使用`rem`为元素设定字体大小时，仍然是相对大小，但相对的只是HTML根元素。这个单位可谓集相对大小`em`和绝对大小`px`的优点于一身，通过它既可以做到只修改根元素就成比例地调整所有字体大小，又可以避免字体大小逐层复合的连锁反应。

	> 目前，除了IE8及更早版本外，所有浏览器均已支持rem。对于不支持它的浏览器，应对方法也很简单，就是多写一个绝对单位的声明。这些浏览器会忽略用rem设定的字体大小。例如：
	>
	> ```css
	> p {font-size:14px; font-size:.875rem;}
	> ```

| 设备属性    | 类中缀 | 设备尺寸 | 最大容器宽度 | 类前缀     |
| ----------- | ------ | -------- | ------------ | ---------- |
| Extra small | None   | <576px   | None (auto)  | `.col-`    |
| Small       | `sm`   | ≥576px   | 540px        | `.col-sm-` |
| Medium      | `md`   | ≥768px   | 720px        | `.col-md-` |
| Large       | `lg`   | ≥992px   | 960px        | `.col-lg-` |
| Extra large | `xl`   | ≥1200px  | 1140px       | `.col-xl-` |

- 以上所有类的默认分割线宽度为30px，左右各15px

- 全都使用`col`标签时会自动均分`div`块宽度，可以使用`w-100`来划分出不同的行（Safari可能会有问题）
- `w-100`其实就是设定了一个宽度为100（高度为0）的块，来让其他块自动分配到下一行
- 设定一个`col`的宽度（如`col-6`），其他就会自动均分剩余宽度
- 可以使用`col-{breakpoint}-auto`来设定一个根据文本自适应宽度的`div`

### 响应式类

- 如果不需要根据屏幕大小设定页面配置，对于各种尺寸的屏幕都可以使用`col`和`col-n`类
- 使用两个`row`类叠加，就可以划分出有间距的两行div
- 如果希望在不同设备上使用不同的堆叠方式，就可以将多个`col`类写进同一个`class attr`，例如：`col-6 col-md-4`

### 垂直对齐

> Internet Explorer 10-11 do not support vertical alignment of flex items when the flex container has a `min-height` as shown below. [See Flexbugs #3 for more details.](https://github.com/philipwalton/flexbugs#flexbug-3)

如果需要定义`row`处于`container`中的上中下位置，可以使用如下三个标签定义`row`标签：

- `align-items-start`
- `align-items-center`
- `align-items-end`

如果希望不同的`col`占据`row`中不同的垂直位置（此时多个`col`不会有垂直堆叠效果），可以使用如下三个标签定义`col`：

- `align-self-start`
- `align-self-center`
- `align-self-end`

### 水平对齐

| 标签                      | 用途                                         |
| ------------------------- | -------------------------------------------- |
| `justify-content-start`   | 靠左                                         |
| `justify-content-center`  | 中间                                         |
| `justify-content-end`     | 靠右                                         |
| `justify-content-around`  | 空白宽度分配到各个块之间（最靠两边的是空白） |
| `justify-content-between` | 空白宽度集中到块之间（最靠两边的是块）       |

### 去除边框

`no-gutters`：去除col之间的左右边框`margin`和上下的边框`padding`，如果一行的宽度超过12个单位，超出的单位就会自动被放到新的一行。

### 重排序

同一行内所有设定了`order`标签的块会进行一次重排序，例如`order-1`的块会被放到`order-12`前面。

### 块偏移

使用`offset`标签可以将块偏移一定宽度，这种方式实际上是通过增加左侧`margin`来实现的。例如`col-md-4 offset-md-4`，如果`class`里有多个对应的宽度类，如`col`，`col-md`，那你也需要就每个类来设定相对应的`offset`。

