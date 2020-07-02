#!/bin/bash

# 输入参数
# -i 单次抓包持续的最大时长，单位为秒
# -k 抓包文件保存的最大时长，单位为秒，如果-i大于此值，-k指定的值会被设置为-i的2倍
# -p tcpdump的输入参数，需要被双引号括起来
# -d 抓包文件保存的目录
#
# 缺陷
# 1. 需要root权限
# 2. 检测运行进程时，会杀掉系统内所有的tcpdump进程
# 3. 没有对文件大小的控制

dumparam=""
interval=0
keeptime=0
directory=""
capturing=0
laststart=`date +%s`

prefix="capture-"

function help()
{
	echo -e "synopsis"
	echo -e "capton [-i interval] [-k keeptime] [-p tcpdump_param] [-d capture_directory]"
	echo -e "	-i	capture interval for single file, in seconds"
	echo -e "	-k	scroll capture files max keep time, should larger than -i, in seconds"
	echo -e "	-p	pass throught tcpdump parameters"
	echo -e "	-d	directory to save the captured files"
	echo -e "	-h	print this manual"
	echo -e "basic usage"
	echo -e "	capton -i 30 -k 600 -p \"-A host ope.tanx.com\""
}

while getopts 'i:k:p:d:h' opt; do
    case $opt in
        i)
            interval=$OPTARG;;
		k)
			keeptime=$OPTARG;;
        p)
            dumparam=$OPTARG;;
        d)
            directory=$OPTARG;;
		h)
			help
			exit 0;;
        ?)
            echo "unknown param"
			help
			exit 0
    esac
done

if [[ $interval == 0 || $keeptime == 0 ]];then
	echo "missing interval(-i) or keeptime(-k) param"
	help
	exit 0
fi

if [[ $dumparam == "" ]]; then
	echo "no param specified, capturing all packages"
	dumparam="-A"
fi

if [[ $directory == "" ]];then
	# using current directory to save captured files
	directory=`pwd`"/"
else
	if [[ ! -d $directory ]];then
		echo "specified dir not exist, exit..."
		exit 0
	fi
fi

if [[ $keeptime -lt $interval ]];then
	# at least keep one capture file
	keeptime=$((interval*2))
fi

# quit cleanup routine
function cleanup()
{
	echo "cleanup"
	exit 0
}

# cap stop on SIGTERM
trap 'cleanup' SIGTERM

#################################################
function kill_tcpdump()
{
	echo $1|xargs kill -15
}

function clean_expired()
{
	cnt=`ls $directory$prefix* 2>/dev/null`
	if [[ $? != 0 ]];then
		# captured file no found
		return
	fi

	capfiles=`stat -f '%N %B' $directory$prefix*|awk '{print $1","$2}'`
	now=`date +%s`

	idx=0
	for f in ${capfiles[@]}; do
		name=`echo $f|awk -F"," '{print $1}'`
		tm=`echo $f|awk -F"," '{print $2}'`

		gap=`expr $now - $tm`
		if [[ $gap -gt $keeptime ]];then
			# remove expired file
			echo "$idx, $gap, $keeptime, $name"
			rm -rf $name
		fi
		idx=`expr $idx + 1`
	done
}

while :
do
	if [[ $capturing == 0 ]];then
		previous=`ps aux|grep tcpdump|grep -v grep|awk '{print $2}'`

		# update start capture timestamp
		laststart=`date +%s`

		# prepare capture file suffix
		suffix=`date +%s`

		# startup tcpdump
		nohup tcpdump $dumparam -w $prefix$suffix 1>/dev/null 2>&1 &

		# kill previous tcpdump
		if [[ $previous != "" ]];then
			kill_tcpdump $previous
			echo "kill $privious"
		else
			echo "nothing to kill"
		fi

		# set capturing flag
		capturing=1
	else
		# calculate time duration from last capture start
		now=`date +%s`
		gap=`expr $now - $laststart`

		if [[ $gap -gt $interval ]];then
			# kill previous tcpdump
			capturing=0
		fi

		clean_expired
	fi
	sleep 0.1
done