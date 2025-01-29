---
title: How-to-install-JAVA-under-CentOS
date: 2021-07-08
excerpt: ""
categories:
    - Language
tags:
    - JAVA
---



# CentOS7下安装Java1.8

[安装Java参考来源](https://www.cnblogs.com/stulzq/p/9286878.html)

`wget`获取[Java官网](https://www.oracle.com/java/technologies/javase/javase-jdk8-downloads.html)安装包，并检测安装包大小

```shell
ls -lht
```

创建安装目录（推荐使用`/usr/local/java/`），并将安装包解压进去

```shell
tar -zxvf jdk-8uxxx-linux-x64.tar.gz -C /usr/local/java/
```

修改环境变量：修改`/etc/profile`文件

```shell
export JAVA_HOME=/usr/local/java/jdk1.8.0_xxx
export JRE_HOME=${JAVA_HOME}/jre 
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib 
export PATH=${JAVA_HOME}/bin:$PATH
```

生效新的环境变量并添加软连接

```shell
source /etc/profile
ln -s /usr/local/java/jdk1.8.0_xxx/bin/java /usr/bin/java
```

