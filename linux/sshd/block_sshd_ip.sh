#! /bin/bash
lastb | grep "ssh:notty" | awk '{print $(NF-7)}' |sort|uniq -c | awk '{print $2"="$1;}' > /tmp/black.list
for i in `cat /tmp/black.list`
do
  IP=`echo $i |awk -F= '{print $1}'`
  NUM=`echo $i|awk -F= '{print $2}'`
  if [ ${NUM} -gt 10 ]; then
    grep $IP /etc/hosts.deny > /dev/null
    if [ $? -gt 0 ];then
      echo "sshd:$IP:deny" >> /etc/hosts.deny
    fi
  fi
done

cat /etc/hosts.deny