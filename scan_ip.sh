#!/bin/bash
cd "$(dirname $0)"
hostname=www.abc.xyz #your hostname

ipv6s="
2400:cb00::/32
2606:4700::/32
2803:f800::/32
2405:b500::/32
2405:8100::/32
2a06:98c0::/29
2c0f:f248::/32
"
#from https://www.cloudflare.com/ips-v6
ip4s="
173.245.48.0/20
103.21.244.0/22
103.22.200.0/22
103.31.4.0/22
141.101.64.0/18
108.162.192.0/18
190.93.240.0/20
188.114.96.0/20
197.234.240.0/22
198.41.128.0/17
162.158.0.0/15
104.16.0.0/12
172.64.0.0/13
131.0.72.0/22
"
#from https://www.cloudflare.com/ips-v4
random_num()
{
	echo ${RANDOM}${RANDOM}${RANDOM}
}


hex2bin()
{
	hex=$1
	case $hex in
	"0")echo 0000;;
	"1")echo 0001;;
	"2")echo 0010;;
	"3")echo 0011;;
	"4")echo 0100;;
	"5")echo 0101;;
	"6")echo 0110;;
	"7")echo 0111;;
	"8")echo 1000;;
	"9")echo 1001;;
	"a")echo 1010;;
	"b")echo 1011;;
	"c")echo 1100;;
	"d")echo 1101;;
	"e")echo 1110;;
	"f")echo 1111;;
	
	*)echo "error"
	esac
}

bin2hex()
{
	bin=$1
	case $bin in
	"0000")echo 0 ;;
	"0001")echo 1 ;;
	"0010")echo 2 ;;
	"0011")echo 3 ;;
	"0100")echo 4 ;;
	"0101")echo 5 ;;
	"0110")echo 6 ;;
	"0111")echo 7 ;;
	"1000")echo 8 ;;
	"1001")echo 9 ;;
	"1010")echo a ;;
	"1011")echo b ;;
	"1100")echo c ;;
	"1101")echo d ;;
	"1110")echo e ;;
	"1111")echo f ;;
	*)echo "error"
	esac
}

random_ipv6_from_range()
{
	segment=$1
	pre=$(echo $segment|cut -d '/' -f 1|sed 's/://g')
	mask=$(echo $segment|cut -d '/' -f 2)
	ip_bin=""
	while [ -n "$pre" ]
	do
		ip_bin=$ip_bin$(hex2bin ${pre:0:1})
		pre=${pre:1}
	done
	
	ip_bin=${ip_bin:0:mask}


	ip_hex=$(echo ${RANDOM}${RANDOM}${RANDOM}|md5sum|awk '{print $1}')
	
	while [ -n "$ip_hex" ]
	do
		ip_bin=$ip_bin$(hex2bin ${ip_hex:0:1})
		ip_hex=${ip_hex:1}
	done

	ip_bin=${ip_bin:0:128}
	
	
	ip_hex=""
	
	while [ -n "$ip_bin" ]
	do
		ip_hex=$ip_hex$(bin2hex ${ip_bin:0:4})
		ip_bin=${ip_bin:4}
	done
	
	
	echo ${ip_hex:0:4}:${ip_hex:4:4}:${ip_hex:8:4}:${ip_hex:12:4}:${ip_hex:16:4}:${ip_hex:20:4}:${ip_hex:24:4}:${ip_hex:28:4}
	#echo ${ip_hex:0:4}:${ip_hex:4:4}:${ip_hex:8:4}::${ip_hex:12:4}:${ip_hex:16:4}
	#echo ${ip_hex:0:4}:${ip_hex:4:4}:${ip_hex:8:4}::681b:aa1a
}



sort_ip6()
{
	cnt=0
	for range in $ipv6s
	do
		mask=${range##*/}
		total=$((2**(32-mask)))
		cnt=$((cnt+total))
		echo "$range $cnt"
	done
}



ip2num()
{
	ip=$1
	num=0
	for x in ${ip//./ }
	do
		num=$((num*256+x))
	done
	echo $num
}

num2ip()
{
	num=$1
	d=$((num%256))
	num=$((num/256))
	c=$((num%256))
	num=$((num/256))
	b=$((num%256))
	num=$((num/256))
	a=$((num%256))
	echo $a.$b.$c.$d
}


sort_ip_range4()
{
	cnt=0
	for range in $ip4s
	do
		start_ip=${range%%/*}
		mask=${range##*/}
		start_num=$(ip2num $start_ip)
		total=$((2**(32-mask)))
		cnt=$((cnt+total))
		end_num=$((start_num+total-1))
		echo "$start_num	$end_num	$total	$cnt"
	done
}

get_rand_ip4()
{
	rand=$(random_num)
	temp=$((rand%total4))
	echo "$sorted_range4"|while read record
	do
		end=$(echo "$record"|awk '{print $4}')
		if [ $temp -le $end ] ; then
			end_ip=$(echo "$record"|awk '{print $2}')
			ip=$((end_ip+temp-end))
			num2ip $ip
			exit
		fi
	done
}

get_rand_ip6()
{
	rand=$(random_num)
	temp=$((rand%total6))
	echo "$sorted_range6"|while read record
	do

		end=$(echo "$record"|awk '{print $2}')
		if [ $temp -le $end ] ; then
			range=$(echo "$record"|awk '{print $1}')
			random_ipv6_from_range $range
			break
		fi
	done
}


check_speed()
{
	ip=$1

	size=2048
	
	SPEED=$(curl -o /dev/null --max-time 100  --resolve ${hostname}:443:$ip "https://${hostname}/test.php?size=${size}" 2>&1 |sed 's/\r/\n/g'|tail -n 1|awk '{print $7}'|sed 's/k/*1024/g') 
	speed=$(($SPEED))

	echo -e "\033[33m		${ip} speed: ${speed} \033[0m"  >&2
	echo "$speed	$ip" >>ip.txt


}



check_ip()
{
	ip=$1

	
	r=$(date +"%s")
	response=$(curl -s --max-time 10 "https://${hostname}/test.php?r=${r}" --resolve ${hostname}:443:$ip)

	curl_res=$?		
	if [ "$curl_res" == "0" ] && [ "$response" == "$r" ] ; then
		echo -e "\033[32m	$ip http success \033[0m"  >&2
		echo $ip


	else
		echo -e "\033[31m	$ip http failed \033[0m"  >&2

	fi


}

generate_random_ips()
{
	while true
	do
		get_rand_ip6
		get_rand_ip4
	done
	
}


scan_ip()
{
	export sorted_range6="$(sort_ip6)"
	export total6=$(echo "$sorted_range6"|tail -n 1|awk '{print $2}')
	export sorted_range4="$(sort_ip_range4)"
	export total4=$(echo "$sorted_range4"|tail -n 1|awk '{print $4}')
	generate_random_ips |xargs -P 10 -I {} $0 check_ip {} |xargs -P 1 -I {} $0 check_speed {}
}

recheck()
{
	ips="$(cat ip.txt |awk '{print $2}'|sort -u)"
	rm ip.txt
	echo "$ips" |xargs -P 10 -I {} $0 check_ip {} |xargs -P 1 -I {} $0 check_speed {}
	sort_ip
}

sort_ip()
{
	temp="$(cat ip.txt |sort -n -r)"
	echo "$temp" >ip.txt
	echo "success"
}

if [ "$1" == "check_ip" ]; then
         shift
         check_ip $*
         exit $?
fi

if [ "$1" == "check_speed" ]; then
         shift
         check_speed $*
         exit $?
fi

if [ "$1" == "scan" ]; then
         shift
         scan_ip $*
         exit $?
fi

if [ "$1" == "check" ]; then
         shift
         recheck $*
         exit $?
fi

if [ "$1" == "sort" ]; then
         shift
         sort_ip $*
         exit $?
fi


echo "usage $0 cmd
available cmds
scan:	scan ip and write results into ip.txt , press control + C to stop
check:	recheck ips in ip.txt, remove unaccessable ips
sort:	sort ips in ip.txt by speed
"


exit

#attachment :test.php

<?php
if(isset($_GET['size']))
{
	$size=$_GET['size'];
	// Disable Compression
	@ini_set('zlib.output_compression', 'Off');
	@ini_set('output_buffering', 'Off');
	@ini_set('output_handler', '');
	// Headers
	header('HTTP/1.1 200 OK');
	// Download follows...
	header('Content-Description: File Transfer');
	header('Content-Type: application/octet-stream');
	header('Content-Disposition: attachment; filename=random_'.$size.'k.dat');
	header('Content-Transfer-Encoding: binary');
	// Never cache me
	header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
	header('Cache-Control: post-check=0, pre-check=0', false);
	header('Pragma: no-cache');
	// Generate data
	$data_1k=openssl_random_pseudo_bytes(1024*1024);
	
	$size_sended=$size%1024;
	echo openssl_random_pseudo_bytes($size_sended*1024);
	flush();
	while ( $size_sended < $size )
	{
		echo $data_1k;
		flush();
		$size_sended=$size_sended+1024;
	}
	

	exit();
}
if(isset($_GET['r']))
{
	print $_GET['r'];
	exit();
}
print_r($_SERVER);
?>

#attachment nginx configure

server {
	listen 80;
	listen 443 ssl http2;
        ssl_certificate       *.crt;  #your certs
        ssl_certificate_key   *.key;
        ssl_protocols         TLSv1.2 TLSv1.3;
        ssl_ciphers           TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;
	server_name rn.kkzam.xyz;
        index index.html index.htm;
        root  /home/wwwroot/;  #your dic where test.php located in


	location ~ .php$ {
		fastcgi_buffer_size 2k;
		fastcgi_buffers 256 2k;
		fastcgi_pass unix:/run/php/php7.0-fpm.sock;  #you php-fpm socket
		fastcgi_index  index.php;
		fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
		include        fastcgi_params;
    }

	location /proxy  #your v2ray listen path
        {
        proxy_redirect off;
	proxy_pass http://127.0.0.1:6789;  #your v2rat listen port
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        }
}

