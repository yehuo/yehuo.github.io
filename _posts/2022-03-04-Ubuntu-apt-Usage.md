---
title: "Ubuntu apt Usage"
date: 2022-03-04
excerpt: "关于Ubuntu下包管理软件apt的相关资料"
categories:
    - System
tags:
    - Tool
---



# [Wikipedia](https://en.wikipedia.org/wiki/APT_(software))

**Advanced package tool**, or **APT**, is a free-software user interface that works with core libraries to handle the installation and removal of software on Debian, and Debian-based Linux distributions. APT simplifies the process of managing software on Unix-like computer systems by automating the retrieval, configuration and installation of [software packages](https://en.wikipedia.org/wiki/Package_manager), either from precompiled files or by compiling source code.

# [Man Page](https://manpages.debian.org/unstable/apt/apt-get.8.en.html)

**apt-get** is the command-line tool for handling packages, and may be considered the user's "back-end" to other tools using the APT library. Several "front-end" interfaces exist, such as [aptitude(8)](https://manpages.debian.org/unstable/aptitude/aptitude.8.en.html), [synaptic(8)](https://manpages.debian.org/unstable/synaptic/synaptic.8.en.html) and **wajig**(1).

## Description 可选操作

## update

- 默认从`/etc/apt/sources.list`目录中去扫描Package.gz文件
- 在`upgrade`和`dist-upgrade`最好都执行下`update`
- 对于`the overall progress meter`选项，如果不能提前设定全部文件大小，就无法正确显示

## upgrade

- `apt-get`的`upgrade`操作回比`apt`和`aptitude`更严格，它不会安装事先未安装过得包
- 当Debian主版本升级，需要使用`apt full-upgrade`来升级，对应的apt-get工具下，这个命令的名称为`apt-get dist-upgrade`
- `upgrade`的所有日志将存储在`/var/log/apt/history.log`和`/var/log/apt/term.log`文件中，dpkg的日志则存储在`/var/log/dpkg.log`中

## install

- 如果在package name后添加一个`-`，就执行`remove`而非`install`

## remove & purge & autoremove

- `remove`使用方法与`install`相同，但是不会移除配置文件
- 如果在package name后添加一个`+`，就执行`install`而非`remove`
- `purge`会在`remove`后删除所有配置文件
- `autoremove`将会删掉曾经用于支持其他packages使用而自动安装，目前不再使用的Packages

## clean & autoclean

- 所有apt下载的deb包，都会在`/var/cache/apt/archives/`下存一份copy，不会自动删除
- 在频繁`update`的情况下，备份目录将会变得十分庞大，每个包都会有许多版本存放其中
- `clean`将会清除该目录下所有的deb文件，抹除这个目录
- `autoclean`只会清除已经过期（无法再下载到）的deb包
- 修改配置文件中`APT::Clean-Installed`参数，可以避免`autoclean`清理到已经安装的deb文件

## source

- 用于下载源码包，要求`/etc/apt/source.list`文件中，必须有`deb-src`开头定义的软件源代码库
- 使用`--complie`参数，就可以将在下载后使用`--host-architecture`定义的`dpkg-buildpackage`编译源码包
- 使用`--download-only`将只下载不编译
- 下载后的源码将不会加入`dpkg database`，而是作为一个源代码压缩包下载到当前目录下

## Options 命令参数

All command line options may be set using the configuration file, the descriptions indicate the configuration option to set. 
For boolean options you can override the config file by using something like **-f-**,**--no-f**, **-f=no** or several other variations.

| 特殊参数                                | 解析                                                         |
| --------------------------------------- | ------------------------------------------------------------ |
| `-f` `--fix-broken`                     | Fix; attempt to correct a system with broken dependencies in place. This option, when used with install/remove, can omit any packages to permit APT to deduce a likely solution. |
| `-m` `--ignore-missing` `--fix-missing` | Ignore missing packages; if packages cannot be retrieved or fail the integrity check after retrieval (corrupted package files), hold back those packages and handle the result. |
| `-a` `--host-architecture`              | This option controls the architecture packages are built for by **apt-get source --compile** and how cross-builddependencies are satisfied. |
| `-s` `--simulate` `--dry-run`           | No action; perform a simulation of events that would occur based on the current system state but do not actually change the system. |

## Files 配置文件

- `/etc/apt/sources.list`: Locations to fetch packages from.
- `/etc/apt/sources.list.d/`: Additional source list fragments.
- `/etc/apt/apt.conf`: APT configuration file.
- `/etc/apt/apt.conf.d/`: APT configuration file fragments.
- `/etc/apt/preferences.d/`: Directory with version preferences files. This is where you would specify "pinning", i.e. a preference to get certain packages from a separate source or from a different version of a distribution.
- `/var/cache/apt/archives/`: Storage area for retrieved package files.
- `/var/cache/apt/archives/partial/`: Storage area for package files in transit.
- `/var/lib/apt/lists/`: Storage area for state information for each package resource specified in `sources.list`
- `/var/lib/apt/lists/partial/`: Storage area for state information in transit.

# [Debian官方文档](https://www.debian.org/doc/manuals/debian-handbook/apt.zh-cn.html)

## sources.list语法

每个软件源的定义通常使用如下三部分定义

```shell
deb url distribution component1 component2 component3 [..] componentX
deb-src url distribution component1 component2 component3 [..] componentX
```

- 第一部分：deb为binary文件，deb-src为源代码文件
- 第二部分：要写完整url，可以是`file://`，`https://`，`ftps://`等定义的资源
- 第三部分：取决于repo的结构，最简单的情况下，是子目录路径，例如`.\`。对于较为复杂的repos，通常需要写入对应的发布版，"suite name"以及需要enable的组件类别，一个常见的Debian镜像源通常根据license提供以下三类组件：
  - main: 完全满足[Debian Free Software Guidelines](https://www.debian.org/social_contract.html#guidelines)
  - non-free: 不完全满足Debian Free Software Guidelines，但是可以不受限制分发的软件。通常用于提供对特定硬件的支持。
  - contrib: 是指需要non-free软件支持才可以正常工作的一类软件，同时也包括一些使用免费，但是需要使用特定编译工具生成的软件

## Stable版本的软件库

```shell
# Security updates
deb http://security.debian.org/ buster/updates main contrib non-free
deb-src http://security.debian.org/ buster/updates main contrib non-free

# Debian mirror

# Base repository
deb https://deb.debian.org/debian buster main contrib non-free
deb-src https://deb.debian.org/debian buster main contrib non-free

# Stable updates
deb https://deb.debian.org/debian buster-updates main contrib non-free
deb-src https://deb.debian.org/debian buster-updates main contrib non-free

# Stable backports
deb https://deb.debian.org/debian buster-backports main contrib non-free
deb-src https://deb.debian.org/debian buster-backports main contrib non-free
```

# Related Reading:

- [apt与apt-get的区别](https://juejin.cn/post/6997060031229198350)
- [Ubuntu Basic Skill](https://samwhelp.github.io/book-ubuntu-basic-skill/book/index.html)