---
title: "Ubuntu 20.04中的Autoinstall"
date: 2022-09-01
excerpt: "用了好多年的preseed终于可以换一个能看懂的版本了..."
categories: 
   - Experience
tags:
   - Ubuntu

---



# Auto Install for Ubuntu 20.04

## Introduction

### New feature

官方定义为无人接管的preseeded installation，和传统preseed流程区别主要是以下两点：

- auto install的配置文件格式采用cloud-init配置方法，通常是yaml文件，而不是是原来的`debconf-set-selections`格式
- preseed流程中将不会有question的出现，以往`d-i`遇到`unanswered question`会停止安装流程，询问用户，但是auto install将会采用默认值，如未设置默认则失败
  - 不过在auto install配置文件中，你同样可以使用`interactive`来指定需要交互的配置，这样遇到对应部分，auto install就会停下来寻求用户输入

### 关于netboot的温馨提示

虽然auto-install配置过程理论是无人参与的，但是在开始写入磁盘之前installer仍需用户确认，除非在内核命令行中设置了`autoinstall`参数。这主要是为了防止在系统创建过程中USB意外插入的情况，这种情况下可能导致机器被格式化。

而大部分netboot流程中内核命令通常可以在netboot的配置文件中设置，记得将`autoinstall`放入其中。

## Configuration

### 应答文件的存放位置

在装机完成后，会在`/var/log/installer/autoinstall-user-data`创建一个autoinstall文件便于重复安装

### 应答文件翻译问题

对于已有的preseed配置文件，可以使用[autoinstall-generator](https://snapcraft.io/autoinstall-generator?_ga=2.67775633.1267827802.1661936839-27790731.1649741711)来翻译生成对应的autoinstall文件。

### 应答文件标准格式

```yaml
version: 1
reporting:
    hook:
        type: webhook
        endpoint: http://example.com/endpoint/path
early-commands:
    - ping -c1 198.162.1.1
locale: en_US
keyboard:
    layout: gb
    variant: dvorak
network:
    network:
        version: 2
        ethernets:
            enp0s25:
               dhcp4: yes
            enp3s0: {}
            enp4s0: {}
        bonds:
            bond0:
                dhcp4: yes
                interfaces:
                    - enp3s0
                    - enp4s0
                parameters:
                    mode: active-backup
                    primary: enp3s0
proxy: http://squid.internal:3128/
apt:
    primary:
        - arches: [default]
          uri: http://repo.internal/
    sources:
        my-ppa.list:
            source: "deb http://ppa.launchpad.net/curtin-dev/test-archive/ubuntu $RELEASE main"
            keyid: B59D 5F15 97A5 04B7 E230  6DCA 0620 BBCF 0368 3F77
storage:
    layout:
        name: lvm
identity:
    hostname: hostname
    username: username
    password: $crypted_pass
ssh:
    install-server: yes
    authorized-keys:
      - $key
    allow-pw: no
snaps:
    - name: go
      channel: 1.14/stable
      classic: true
debconf-selections: |
    bind9      bind9/run-resolvconf    boolean false
packages:
    - libreoffice
    - dns-server^
user-data:
    disable_root: false
late-commands:
    - sed -ie 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=30/' /target/etc/default/grub
error-commands:
    - tar c /var/log/installer | nc 192.168.0.1 1000
```

## Quick Start

### 准备阶段

确认网络情况，确认Python3安装

```shell
# download image files
wget http://releases.ubuntu.com/20.04/ubuntu-20.04.4-live-server-amd64.iso

# mount image disk
sudo mount -r ~/Downloads/ubuntu-20.04-live-server-amd64.iso /mnt

# create config files
# The crypted password is just “ubuntu”
mkdir -p ~/www
cd ~/www
cat > user-data << 'EOF'
#cloud-config
autoinstall:
  version: 1
  identity:
    hostname: ubuntu-server
    password: "$6$exDY1mhS4KUYCE/2$zmn9ToZwTKLhCw.b4/b.ZRTIZM30JZ4QrOQ2aOXJ8yk96xpcCof0kxKwuX1kqLG/ygbJ1f8wxED22bTL4F46P0"
    username: ubuntu
EOF
touch meta-data

# start http service
cd ~/www
python3 -m http.server 3003
```

### 开始安装

本次安装默认是为一台vm进行安装，这里使用kvm来操作安装流程

```shell
# create target disk for the vm
truncate -s 10G image.img

# install with no reboot
kvm -no-reboot -m 1024 \
    -drive file=image.img,format=raw,cache=none,if=virtio \
    -cdrom ~/Downloads/ubuntu-20.04-live-server-amd64.iso \
    -kernel /mnt/casper/vmlinuz \
    -initrd /mnt/casper/initrd \
    -append 'autoinstall ds=nocloud-net;s=http://_gateway:3003/'

# boot the installed system
kvm -no-reboot -m 1024 \
    -drive file=image.img,format=raw,cache=none,if=virtio
```

### U盘安装操作

前面准备工作同普通安装流程，唯一这里不同的是，需要在创建`user-data`和`meta-data`后使用下面命令来创建ISO文件作为`cloud-init`数据源，注意`cloud-localds`主要用途就是为`cloud-init`创建一个iso文件，来利用`nocloud`模式启动。

```shell
sudo apt install cloud-image-utils
cloud-localds ~/seed.iso user-data meta-data
```

之后安装流程如下，注意这里第二份drive参数指定通过iso获取`user-data`而不是前面的append参数。

```shell
# create disk for vm
truncate -s 10G image.img

# install system for vm
kvm -no-reboot -m 1024 \
    -drive file=image.img,format=raw,cache=none,if=virtio \
    -drive file=~/seed.iso,format=raw,cache=none,if=virtio \
    -cdrom ~/Downloads/ubuntu-20.04-live-server-amd64.iso

# start system
kvm -no-reboot -m 1024 \
    -drive file=image.img,format=raw,cache=none,if=virtio
```

## Options in Config

基本格式参照上面的Config Example，这里放几个比较新的选项

### Version

这个是一个后续才拓展的选项，目前必须使用`1`

### interactive-sections

用于选择仍用UI展示的配置项，设置方法如下：

```yaml
version: 1
interactive-sections:
 - network
identity:
 username: ubuntu
 password: $crypted_pass
```

关于interactive-sections有两点需要注意：

- 可以使用通配符`*`来代指所有选项，这种情况下，autoinstall流程将退化为手工安装
- 在配置为interactive section后，`reporting`设置将会被忽略掉

### Storage/Disk selection extensions

磁盘选择可以通过以下五种方式选择

- model：通过ID_VENDOR来选择
- path：通过DEVPATH来选择
- serial：通过ID_SERIAL来选择
- ssd：bool值，来通过是否为ssd来选择
- size：枚举值，只能是largest或者smallest，如果多个同样尺寸，则会任意选择（*但是对smallest的支持是在20.06.1的系统中添加的*）

具体使用方式，参考以下几种

```yaml
- type: disk
  id: disk0
  
- type: disk
  id: data-disk
  match:
    model: Seagate

- type: disk
  id: big-fast-disk
  match:
    ssd: yes
    size: largest
```

### Storage/partition/logical volume extensions

用于指定分区和逻辑盘的大小，可以使用1G或512M这种可以被UI识别的数字，或者50%这种百分数，同样也可以使用-1来代指分区应占满磁盘剩余空间。具体分区样例，参照下面

```yaml
- type: partition
  id: boot-partition
  device: root-disk
  size: 10%
- type: partition
  id: root-partition
  size: 20G
- type: partition
  id: data-partition
  device: root-disk
  size: -1
```

### ssh/authorized-keys

A list of SSH public keys to install in the initial user’s account，保证可以通过key登录初始服务器

### reporting

将安装流程信息反馈到一个输出渠道，包括以下几种选项：

- **print**: print progress information on tty1 and any configured serial console. There is no other configuration.
- **rsyslog**: report progress via rsyslog. The **destination** key specifies where to send output.
- **webhook**: report progress via POSTing JSON reports to a URL. Accepts the same configuration as [curtin](https://curtin.readthedocs.io/en/latest/topics/reporting.html#webhook-reporter).
- **none**: do not report progress. Only useful to inhibit the default output.

其中比较有趣的是webhook的方式，配置方法参考下面

```shell
reporting:
 hook:
  type: webhook
  endpoint: http://example.com/endpoint/path
  consumer_key: "ck_foo"
  consumer_secret: "cs_foo"
  token_key: "tk_foo"
  token_secret: "tk_secret"
  level: INFO
```

## Schema Check

在安装过程中一部分配置需要同JSON Schema来校对，但是校对过程实际上是发生在运行过程中的，具体流程可以参考下面几项

- reporting模块最先被load-validate-apply
- error-commands模块开始load-validate
- early-commands模块开始load-validate
- 运行early-commands
- load整个config，然后被load-validate

## Reference

- [Introduction](https://ubuntu.com/server/docs/virtualization-introduction)
- [Quick Start](https://ubuntu.com/server/docs/install/autoinstall-quickstart)
- [Autoinstall Reference](https://ubuntu.com/server/docs/install/autoinstall-reference)

