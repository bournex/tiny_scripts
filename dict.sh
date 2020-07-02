#!/bin/bash

# english dictionary file please modify 'dict' directly
# -a : add new word
# -e : english word
# -c : chinese translation word
# if no param provided, return with a random word pair

argc=$#
dict=${DICT}
#dict="/Users/bournex/code/script/en"


# 输出一条
function print_word()
{
	echo "$1 -> $2"
}

# 随机输出一条
function random()
{
	if [[ $# == 0 ]];then
		# no params assigned
		words=(`cat $dict`)

		# random index
		idx=`echo $RANDOM`

		# numerical it
		idx=`expr $idx`
		cnt=`expr ${#words[@]}`
		if [[ $cnt == 0 ]];then
			exit 0
		fi

		# calulate index
		idx=$(($idx%$cnt))
		k=`echo ${words[$idx]}|awk -F"\|" '{print $1}'`
		v=`echo ${words[$idx]}|awk -F"\|" '{print $2}'`
		print_word $k $v
		exit 0
	fi
}

query_var=""
function query()
{
	while read line
	do
		k=`echo $line|awk -F"\|" '{print $1}'`
		v=`echo $line|awk -F"\|" '{print $2}'`
		if [[ $k == $1 ]];then
			query_var=$v
			return 0
		fi
	done < $dict
	return 1
}

fuzzy_var=""
# $1 - word to fuzzy query
function fuzzy_query()
{
	ret=1
	while read line
	do
		k=`echo $line|awk -F"\|" '{print $1}'`
		v=`echo $line|awk -F"\|" '{print $2}'`
		tmp=`echo $k|grep -e "$1"`
		if [[ $? == 0 ]];then
			if [[ $ret == 1 ]];then
				fuzzy_var="$tmp -> $v"
			else
				fuzzy_var="$fuzzy_var\n$tmp -> $v"
			fi
			ret=0
		fi
	done < $dict
	return $ret
}

# $1 - word to be delete
function delete_word()
{
	dir=${dict%/*}
	tmp=$dir"/en.tmp"
	touch $tmp
	if [[ $? != 0 ]];then
		echo "create tmp file failed"
		exit 1
	fi

	flag=0
	while read line
	do
		k=`echo $line|awk -F"\|" '{print $1}'`
		v=`echo $line|awk -F"\|" '{print $2}'`
		if [[ $1 == $k ]];then
			flag=1
			continue
		fi
		echo "$k|$v" >> $tmp
	done < $dict

	if [[ $flag == 1 ]];then
		echo "$1 deleted"
	fi

	mv $tmp $dict
}

#
#	start execute from here
#

# input arguments
delflag=0
testing=0
eword=""
cword=""
dictsrc=""

# read arguments
while getopts 'e:c:f:dt' opt; do
	case $opt in
		e)
			eword=$OPTARG;;
		c)
			cword=$OPTARG;;
		f)
			dictsrc=$OPTARG;;
		d)
			delflag=1;;
		t)
			testing=1;;
		?)
			echo "unknown param"
	esac
done

# prepare dictionary file path
if [[ $dictsrc != "" ]];then
	dict=$dictsrc
fi

# 判断文件是否存在
if [[ ! -f "$dict" ]];then
	touch $dict
	echo "dict file '$dict' not exist, creating"
	exit 1
fi

if [[ $argc == 0 || ($dictsrc != "" && $argc == 2) ]];then
	# no arguments, random one
	random
elif [[ $argc == 1 ]];then
	# query one
	toquery=`echo $1 | tr 'A-Z' 'a-z'`

	fuzzy_query $toquery
	if [[ $? == 0 ]];then
		echo -e $fuzzy_var
	else
		# TODO
		# query from bing api
		# if no found, quit
		echo "$1 no found"
	fi
elif [[ $delflag == 1 ]];then
	if [[ $eword == "" ]];then
		echo "missing -e argument, nothing to delete"
		exit 1
	fi
	todel=`echo $eword | tr 'A-Z' 'a-z'`
	delete_word $todel
else
	# add one
	# determine adding arguments
	if [[ $eword == "" || $cword == "" ]];then
		echo "missing english or chinese words"
		exit 1
	fi

	toadd=`echo $eword | tr 'A-Z' 'a-z'`

	# filtering before adding
	query $toadd
	if [[ $? == 0 ]];then
		# found
		echo "'$eword' already exist, translation is $query_var"
		exit 0
	fi

	echo "adding [$eword -> $cword] to $dict..."
	# add to $dict
	echo "$toadd|$cword" >> $dict
fi

exit 0