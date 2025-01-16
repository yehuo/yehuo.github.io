---
title: "Pagination in PHP"
date: 2018-09-09
categories:
    - Backend
tags:
    - PHP
---



## 实现查询结果分页

```php
$_SERVER
    REQUETST_URI    请求参数
    SERVER_PORT     服务器端口
    SERVER_NAME     服务器地址
    REQUEST_SCHEME  http协议版本
parse_url()
    // 输出$path和$query
    $uriArray=parse_url($uri);
    $path=$uriArray['path'];
    $query=$uriArray['query'];
parse_str()
    // 拆解query部分的字符串
    parse_str($uriArray['query'],$array);
    unset($array['page'])
http_build_query()
    // 拼接之前str_prase的结果
    $query=http_build_query($array);
    $path=$path.'?'.$query;

    return $scheme.'://'.$host.':'.$port.$path;
```
