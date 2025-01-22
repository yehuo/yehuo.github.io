---
title: NetBox Installation Process
date: 2021-11-01
excerpt: "How to setup NetBox service from zero..."
categories: 
  - Notes
tags:
  - NetBox

---



# 0x01 [Netbox 是什么](https://github.com/netbox-community/netbox)

NetBox的存在是为了增强网络工程师的能力。自2016年发布以来，它已经成为全球数千个组织建模和记录网络基础设施的首选解决方案。作为遗留IPAM和DCIM应用程序的继承者，NetBox为所有联网的事物提供了一个内聚的、广泛的和可访问的数据模型。通过为从电缆映射到设备配置的一切提供单一的健壮的用户界面和可编程的api， NetBox成为现代网络的核心来源。

# 0x02 构建一个 Netbox 服务的demo

构建数据库PostGreSQL和缓存Redis集群

## 1. 构建后端数据库 PostgreSQL

目前仅支持PostgreSQL，版本要求大于9.6

```shell
sudo apt update
sudo apt install -y postgresql
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo -u postgres psql
```

创建数据库

```sql
CREATE DATABASE netbox;
CREATE USER netbox WITH PASSWORD 'J5brHrAXFLQSif0K';
GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox;
```

检验数据库

```shell
psql --username netbox --password --host localhost netbox
\conninfo
```

## 2. 构建 KV 缓存 Redis

NetBox v2.9.0 and later require Redis v4.0 or higher.

```shell
sudo apt install -y redis-server
redis-cli ping
```

## 3. 部署 NetBox 服务

NetBox v3.0 需要 Python3 的支持

```shell
# 安装依赖
sudo apt install -y python3 python3-pip python3-venv python3-dev build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev libssl-dev zlib1g-dev
sudo pip3 install --upgrade pip

# 下载NetBox

# Option A：for stable release
sudo wget https://github.com/netbox-community/netbox/archive/vX.Y.Z.tar.gz
sudo tar -xzf vX.Y.Z.tar.gz -C /opt
sudo ln -s /opt/netbox-X.Y.Z/ /opt/netbox

# Option B: for latest release
sudo git clone -b master --depth 1 https://github.com/netbox-community/netbox.git
# add user, configure the WSGI and HTTP services to run under this account
sudo adduser --system --group netbox
sudo chown --recursive netbox /opt/netbox/netbox/media/

# 更改本地配置
cd /opt/netbox/netbox/netbox/
sudo cp configuration.example.py configuration.py
```

### 设置主要修改项

需要注意的是，NetBox 需要两个独立的 Redis 数据库：`tasks` 和 `caching`。这些都可以由相同的Redis服务提供，但是每个都应该有一个唯一的数字数据库ID。

这个参数必须被分配一个随机生成的密钥，作为散列和相关加密函数的备用密钥。（但请注意，它从来不会直接用于加密秘密数据。） 此密钥必须是唯一的，并且建议至少50个字符长。

```python
ALLOWED_HOSTS = ['netbox.example.com', '192.0.2.123']
DATABASE = {
    'NAME': 'netbox',               # Database name
    'USER': 'netbox',               # PostgreSQL username
    'PASSWORD': 'J5brHrAXFLQSif0K', # PostgreSQL password
    'HOST': 'localhost',            # Database server
    'PORT': '',                     # Database port (leave blank for default)
    'CONN_MAX_AGE': 300,            # Max database connection age (seconds)
}
REDIS = {
    'tasks': {
        'HOST': 'localhost',      # Redis server
        'PORT': 6379,             # Redis port
        'PASSWORD': '',           # Redis password (optional)
        'DATABASE': 0,            # Database ID
        'SSL': False,             # Use SSL (optional)
    },
    'caching': {
        'HOST': 'localhost',
        'PORT': 6379,
        'PASSWORD': '',
        'DATABASE': 1,            # Unique ID for second database
        'SSL': False,
    }
}
```


```shell
# 生成Secret
python3 ../generate_secret_key.py
```

### 设定扩展模块

All Python packages required by NetBox are listed in `requirements.txt` and will be installed automatically. NetBox also supports some optional packages. If desired, these packages must be listed in `local_requirements.txt` within the NetBox root directory.

- napalm: 用于通过RESTAPI借口获得设备信息
- django-storages: 支持django使用远程存储设备

```shell
sudo sh -c "echo 'napalm' >> /opt/netbox/local_requirements.txt"sudo sh -c "echo 'django-storages' >> /opt/netbox/local_requirements.txt"
```

### 生效配置

- upgrade功能
	- Create a Python virtual environment
	- Installs all required Python packages
	- Run database schema migrations
	- Builds the documentation locally (for offline use)
	- Aggregate static resource files on disk
- housekeeping功能
	- handles some recurring cleanup tasks, such as clearing out old sessions and expired change records
	- sh shell can be copied to or linked from your system's daily cron task directory

```shell
sudo /opt/netbox/upgrade.sh

# enter venv created by upgrade
source /opt/netbox/venv/bin/activate

# create super user
cd /opt/netbox/netbox
python3 manage.py createsuperuser

# schedule hosekeeping task
ln -s /opt/netbox/contrib/netbox-housekeeping.sh /etc/cron.daily/netbox-housekeeping

# test application
python3 manage.py runserver 0.0.0.0:8000 --insecure
```

# 0x03 构建一个后端可视化

## 1. 使用 Gunicorn

NetBox附带了gunicorn的默认配置文件。要使用它，请将`/opt/netbox/contrib/gunicorn.py`复制到`/opt/netbox/gunicorn.py`。

```shell
sudo cp /opt/netbox/contrib/gunicorn.py /opt/netbox/gunicorn.py
```

We'll use systemd to control both gunicorn and NetBox's background worker process.

```shell
sudo cp -v /opt/netbox/contrib/*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl start netbox netbox-rq
sudo systemctl enable netbox netbox-rq
systemctl status netbox.service
```

> p.s. If the NetBox service fails to start, issue the command `journalctl -eu netbox` to check for log messages.

## 2. HTTP Server

### Obtain SSL Certificate

To enable HTTPS access to NetBox, you'll need a valid SSL certificate. You can purchase one from a trusted commercial provider, obtain one for free from [Let's Encrypt](https://letsencrypt.org/getting-started/), or generate your own (although self-signed certificates are generally untrusted). Both the public certificate and private key files need to be installed on your NetBox server in a location that is readable by the `netbox` user.

```shell
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/netbox.key \
    -out /etc/ssl/certs/netbox.crt

# Option A Nginx
## 需要修改config文件中`netbox.example.com`为自己的域名，需要和netbox配置文件中ALLOWED_HOSTS相匹配
sudo apt install -y nginx
sudo cp /opt/netbox/contrib/nginx.conf /etc/nginx/sites-available/netbox
sudo cp /etc/nginx/sites-enabled/default /etc/n.bkpginx/site-f s-enabled/default.bkp
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/netbox /etc/nginx/sites-enabled/netbox
sudo systemctl restart nginx

# Option B Apache
## 同样需要修改配置文件中的ServerName
sudo apt install -y apache2
sudo cp /opt/netbox/contrib/apache.conf /etc/apache2/sites-available/netbox.conf
sudo a2enmod ssl proxy proxy_http headers
sudo a2ensite netbox
sudo systemctl restart apache2
```

# 0x04 权限管理：引入LDAP(options)

```shell
sudo apt install -y libldap2-dev libsasl2-dev libssl-dev
source /opt/netbox/venv/bin/activate
pip3 install django-auth-ldap
sudo sh -c "echo 'django-auth-ldap' >> /opt/netbox/local_requirements.txt"
```

修改NetBox配置文件`REMOTE_AUTH_BACKEND = 'netbox.authentication.LDAPBackend'`