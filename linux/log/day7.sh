#!/bin/bash
#
while true
do
    # 每天检查一次
    sleep 24h
    # 定位到日志文件目录
    log_dir=/var/log
    # 删除文件
    find $log_dir -mtime +7 -exec rm -rf {} \;
done