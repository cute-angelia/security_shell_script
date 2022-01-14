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
