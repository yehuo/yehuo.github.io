---
title: File Upload Function in PHP
date: 2018-09-09
categories:
  - Backend
tags:
  - PHP
---



# 实现图形验证码

## 预设变量
- `$number` 验证码个数
- `$codeType` 验证码类型
  - `0` 纯数字
  - `1` 纯字母
  - `2` 数字字母混合
- `$width` 验证码宽度
- `$height` 验证码高度
- `$code` 验证码
- `$image` 图像资源

### 实现步骤

- 生成验证码
- 创建画布
- 填充背景色
- 验证码画到画布上
- 添加干扰元素
- 输出显示

```php
// Init attribute of class member
// Generate $code content randomly
public function __construct($number,$codeType,$width,$height)
    
// Magic method to code getter
public function __get($name)
    

protected function createCode()
    // 0: getNumberCode()
    // 1: getCharCode()
    // 2: getNumCharCode()

protected function getNumberCode()
    $str=join('',range(0,9))
    return substr(str_shuffle($str),0,$this->number);

protected function getCharCode()
    $str=join('',range('a','z'));
    $str=$str.strtoupper($str);
    return substr(str_shuffle($str),0,$this->number);

protected function getNumCharCode()

public function outImage()
    $this->createImage();
    $this->fillBack()

protected function createImage()
    $this->image=imagecreatetruecolor($this->width,$this->height);

protected function fillBack()
    imagefill()
    imagecolorallocate()
    mt_rand()

protected function drawChar()
    $x=mt_rand($i*$width+5,($i+1)*width-10);
    $y=mt_rand(0,$this->height-15);
    imagechar($this->image,5,$x,$y,$this->code[$i],$this->darkColor());

protected function drawDistrub()
    imagesetpixel($this->image,$x,$y,$this->lightColor());

protected function show()
    header('Content-Type:image/png');
    imagepng($this->image);

public function _destruct()
    imagedestory($this->image)
```
