## sshd

策略：

1. 修改默认端口并增强密码强度
2. 对登录失败的 N 次的 ip 进行屏蔽处理

linux 安全日志在 `/var/log/secure` 里面可以查看

这几个 ip 几万次了，一个强密码还是很有必要

```
139.59.x.x=27944
167.71.x.x=42241
194.163.x.x=55148
```

### 安装

```
wget https://raw.githubusercontent.com/cute-angelia/security_shell_script/master/linux/sshd/block_sshd_ip.sh

chmod +x block_sshd_ip.sh
```

定时任务

```
crontab -e

# 屏蔽 sshd 登录失败用户
* */3 * * *  sh /root/block_sshd_ip.sh

```

查看是否生效

```
cat /etc/hosts.deny
```


### 不使用默认的22端口
ssh登陆默认的端口是22 修改 `/etc/ssh/sshd_config` 文件，将其中的Port 22 改为随意的端口比如 Port 47832，port的取值范围是 0 – 65535(即2的16次方)，0到1024是众所周知的端口（知名端口，常用于系统服务等，例如http服务的端口号是80)。

###  禁止使用密码登陆，使用RSA私钥登陆

```
把本机的 id_rsa.pub 拷贝到 服务器的 .ssh/authorized_keys ， 并将权限改为400

cat id_rsa.pub >> authorized_keys


# vi /etc/ssh/sshd_config
RSAAuthentication yes #RSA认证
PubkeyAuthentication yes #开启公钥验证
AuthorizedKeysFile .ssh/authorized_keys #验证文件路径
PasswordAuthentication no #禁止密码认证
PermitEmptyPasswords no #禁止空密码
# 最后保存，重启sshd服务
sudo service sshd restart
```


### fail2ban 使用

本脚本是最为方便快捷，还有种方式，你也可以用 [fail2ban](https://github.com/fail2ban/fail2ban) 来实现

默认配置文件一般在/etc/fail2ban/jail.conf。现在你已经准备好了通过配置 fail2ban 来加强你的SSH服务器。你需要编辑其配置文件 /etc/fail2ban/jail.conf。 在配置文件的“[DEFAULT]”区，你可以在此定义所有受监控的服务的默认参数，另外在特定服务的配置部分，你可以为每个服务（例如SSH，Apache等）设置特定的配置来覆盖默认的参数配置。

在针对服务的监狱区（在[DEFAULT]区后面的地方），你需要定义一个[ssh-iptables]区，这里用来定义SSH相关的监狱配置。真正的禁止IP地址的操作是通过iptables完成的。

```
[DEFAULT]
# 以空格分隔的列表，可以是 IP 地址、CIDR 前缀或者 DNS 主机名
# 用于指定哪些地址可以忽略 fail2ban 防御
ignoreip = 127.0.0.1 172.31.0.0/24 10.10.0.0/24 192.168.0.0/24
# 客户端主机被禁止的时长（秒）
bantime = 86400
# 客户端主机被禁止前允许失败的次数 
maxretry = 5
# 查找失败次数的时长（秒）
findtime = 600
mta = sendmail
[ssh-iptables]
enabled = true
filter = sshd
action = iptables[name=SSH, port=ssh, protocol=tcp]
sendmail-whois[name=SSH, dest=your@email.com, sender=fail2ban@email.com]
# Debian 系的发行版 
logpath = /var/log/auth.log
# Red Hat 系的发行版
logpath = /var/log/secure
# ssh 服务的最大尝试次数 
maxretry = 3
```

启动方式：

```
service fail2ban restart

systemctl restart fail2ban

// 开机启动
systemctl enable fail2ban

// 启动是否成功
fail2ban-client pingServer replied: pong

// 查看状态
fail2ban-client status

// 特定的iptables
fail2ban-client status ssh-iptables

// 解锁某个 ip
fail2ban-client set ssh-iptables unbanip 192.168.1.8
```






