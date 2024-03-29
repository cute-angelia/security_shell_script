#!/bin/bash
# A Linux Shell Script with common rules for IPTABLES Firewall.
# By default this script only open port 80, 22, 53 (input)
# All outgoing traffic is allowed (default - output)
# -------------------------------------------------------------------------

IPT="/sbin/iptables"
SPAMLIST="blockedip"
SPAMDROPMSG="BLOCKED IP DROP"

echo "Starting IPv4 Wall..."
$IPT -F
$IPT -X
$IPT -t nat -F
$IPT -t nat -X
$IPT -t mangle -F
$IPT -t mangle -X
modprobe ip_conntrack

[ -f /root/scripts/blocked.ips.txt ] && BADIPS=$(egrep -v -E "^#|^$" /root/scripts/blocked.ips.txt)

PUB_IF="eth0"

#unlimited
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT

# DROP all incomming traffic
$IPT -P INPUT DROP
$IPT -P OUTPUT DROP
$IPT -P FORWARD DROP

if [ -f /root/scripts/blocked.ips.txt ];
then
# create a new iptables list
$IPT -N $SPAMLIST

for ipblock in $BADIPS
do
   $IPT -A $SPAMLIST -s $ipblock -j LOG --log-prefix "$SPAMDROPMSG"
   $IPT -A $SPAMLIST -s $ipblock -j DROP
done

$IPT -I INPUT -j $SPAMLIST
$IPT -I OUTPUT -j $SPAMLIST
$IPT -I FORWARD -j $SPAMLIST
fi

# 关闭邮件端口 某些漏洞通过转发滥发垃圾邮件
$IPT -A OUTPUT -p TCP --dport 25 -j DROP
$IPT -A OUTPUT -p TCP --dport 110 -j DROP
$IPT -A OUTPUT -p TCP --dport 465 -j DROP
$IPT -A OUTPUT -p TCP --dport 587 -j DROP
$IPT -A OUTPUT -p TCP --dport 993 -j DROP
$IPT -A OUTPUT -p TCP --dport 995 -j DROP
$IPT -A INPUT -p TCP --dport 25 -j DROP
$IPT -A INPUT -p TCP --dport 110 -j DROP
$IPT -A INPUT -p TCP --dport 465 -j DROP
$IPT -A INPUT -p TCP --dport 587 -j DROP
$IPT -A INPUT -p TCP --dport 993 -j DROP
$IPT -A INPUT -p TCP --dport 995 -j DROP

# Block sync
$IPT -A INPUT -i ${PUB_IF} -p tcp ! --syn -m state --state NEW  -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Drop Sync"
$IPT -A INPUT -i ${PUB_IF} -p tcp ! --syn -m state --state NEW -j DROP

# Block Fragments
$IPT -A INPUT -i ${PUB_IF} -f  -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Fragments Packets"
$IPT -A INPUT -i ${PUB_IF} -f -j DROP

# Block bad stuff
$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL ALL -j DROP

$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL NONE -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "NULL Packets"
$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL NONE -j DROP # NULL packets

$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,FIN SYN,FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "XMAS Packets"
$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP #XMAS

$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags FIN,ACK FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Fin Packets Scan"
$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags FIN,ACK FIN -j DROP # FIN packet scans

$IPT  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP


# Allow full outgoing connection but no incomming stuff
$IPT -A INPUT -i eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -o eth0 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

▽

# Allow ssh
$IPT -A INPUT -p tcp --destination-port 28202 -j ACCEPT
$IPT -A INPUT -p tcp --destination-port 22 -j ACCEPT

# allow incomming ICMP ping pong stuff
$IPT -A INPUT -p icmp --icmp-type 8 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -p icmp --icmp-type 0 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow port 53 tcp/udp (DNS Server)
$IPT -A INPUT -p udp --dport 53 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -p udp --sport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT

$IPT -A INPUT -p tcp --destination-port 53 -m state --state NEW,ESTABLISHED,RELATED  -j ACCEPT
$IPT -A OUTPUT -p tcp --sport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Open port 80
$IPT -A INPUT -p tcp --destination-port 80 -j ACCEPT
##### Add your rules below ######
$IPT -A INPUT -p tcp --destination-port 443 -j ACCEPT
$IPT -A INPUT -p tcp --destination-port 4433 -j ACCEPT
$IPT -A INPUT -p tcp --destination-port 50815 -j ACCEPT
$IPT -A INPUT -p tcp --destination-port 10800 -j ACCEPT

# open by ip
#IPT -A INPUT -p tcp --destination-port 8096 -j ACCEPT
$IPT -A INPUT -s 113.192.186.230/32 -p tcp -m tcp --dport 8096 -j ACCEPT
$IPT -A INPUT -s 113.231.102.85/32 -p tcp -m tcp --dport 8096 -j ACCEPT

##### END your rules ############

# Do not log smb/windows sharing packets - too much logging
$IPT -A INPUT -p tcp -i eth0 --dport 137:139 -j REJECT
$IPT -A INPUT -p udp -i eth0 --dport 137:139 -j REJECT

# log everything else and drop
$IPT -A INPUT -j LOG
$IPT -A FORWARD -j LOG
$IPT -A INPUT -j DROP

exit 0
