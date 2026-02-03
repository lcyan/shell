#!/bin/bash

# apt -y install unzip

# install nexttrace
if [ ! -f "/usr/local/bin/nexttrace" ]; then
    curl nxtrace.org/nt | bash
fi

## start to use nexttrace

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

clear
next

ip_list=(219.141.147.210 202.106.50.1)
ip_addr=(北京电信 北京联通)
# ip_len=${#ip_list[@]}

for i in {0..1}
do
	echo ${ip_addr[$i]}
	nexttrace -M ${ip_list[$i]}
	next
done
