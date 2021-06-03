```php
<?php
    $data=array("name"=>"Hagrid","age"=>"36");
    $data_string=json_decode($data);

    $ch=curl_init();
    curl_setopt($ch,CURLOPT_CUSTOMREQUEST,"POST");
    curl_setopt($ch,CURLOPT_POSTFUELDS,$data_string);
    curl_setopt($ch,CURLOPT_RETURNTRANSFER,true);
    curl_setopt($ch,CURLOPT_HTTPHEADER,array(
        'Content-Type: application/json',
        'Content-Length: '.strlen($data_string)
    ));
    $result=curl_exec($ch)
    //http://www.runoob.com/php/php-ref-curl.html
    //https://blog.csdn.net/DavidFFFFFF/article/details/72828204
?>

```

