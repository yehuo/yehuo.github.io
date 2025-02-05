---
title: Build RESTful API in PHP 
date: 2018-07-31
excerpt: "【转载】如何使用PHP调用API接口（如何POST一个JSON格式的数据给Restful服务）"
canonical_url: "https://blog.csdn.net/DavidFFFFFF/article/details/72828204"
categories: 
  - Backend
tags: 
  - PHP
---



[转载来源](https://blog.csdn.net/DavidFFFFFF/article/details/72828204)

## jQuery方法

使用ajax函数生成一个请求、填充参数后发送

```php
$.ajax({
  url:url,
  type:"POST",
  data:data,
  contentType:"application/json; charset=utf-8",
  dataType:"json",
  success: function(){
    ...
  }
})
```

## PHP Curl方法

使用`curl_setopt`方法来设定好`curl`对象需要传递的参数，然后直接执行`curl`对象，详细讲解参见[curl_setopt文档](http://www.runoob.com/php/func-curl_setopt.html)

```php
$data = array("name" => "Hagrid", "age" => "36");                                                                      
$data_string = json_encode($data);       
$ch = curl_init('http://api.local/rest/users');        
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "POST");                            
curl_setopt($ch, CURLOPT_POSTFIELDS, $data_string);  
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);  
curl_setopt($ch, CURLOPT_HTTPHEADER, array(                   
    'Content-Type: application/json',  
    'Content-Length: ' . strlen($data_string))           
);                                                                                                                     
$result = curl_exec($ch);  
```

## 公用写法【推荐】

```php
function CallAPI($method, $url, $data = false)
{
    $curl = curl_init();
    switch ($method)
    {
        case "POST":
            curl_setopt($curl, CURLOPT_POST, 1);
            if ($data)
                curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
            break;
        case "PUT":
            curl_setopt($curl, CURLOPT_PUT, 1);
            break;
        default:
            if ($data)
                $url = sprintf("%s?%s", $url, http_build_query($data));
    }

    // Optional Authentication:
    curl_setopt($curl, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
    curl_setopt($curl, CURLOPT_URL, $url);
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($curl, CURLOPT_HTTPHEADER, array( /*设置请求头*/               
        'Content-Type: application/json',  
        'Content-Length: ' . strlen($data))           
    );

    $result = curl_exec($curl);
    AddMessage2Log(print_r($result,true));
    curl_close($curl);
    return $result;
}   
```
