#!/usr/bin/env bash
#
# Description: Auto system info & I/O test & network to China script
#
# Copyright (C) 2017 - 2018 Oldking <oooldking@gmail.com>
#
# Thanks: Bench.sh <i@teddysun.com>
#
# URL: https://www.oldking.net/350.html
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
PLAIN='\033[0m'

about() {
	echo ""
	echo " ========================================================= "
	echo " \                 Superbench.sh  测试脚本               / "
	echo " \         系统基础信息, I/O 测试 以及 网络速度测试      / "
	echo " \                   v2.0.0 (6 Sep 2020)                 / "
	echo " \                   代码由 Oldking 编写                 / "
	echo " \              修改以及汉化由 qd201211 完成             / "
	echo " ========================================================= "
	echo ""
	echo " 作者文章: https://www.oldking.net/350.html"
	echo " Copyright (C) 2019 Oldking oooldking@gmail.com"
	echo ""
}

preinfo() {
	echo "                   Superbench 服务器性能测试                          "
	echo "       bash <(curl -Lso- https://git.io/superbench)"
	echo "       全部节点列表:  https://git.io/superspeedList"
	echo "       节点更新: 2020/04/09  | 脚本更新: 2020/09/06"
	echo "----------------------------------------------------------------------"
}

cancel() {
	echo ""
	next;
	echo " Abort ..."
	echo " Cleanup ..."
	cleanup;
	rm -rf speedtest*
	echo " Done"
	exit
}

trap cancel SIGINT

benchinit() {
	# check release
	if [ -f /etc/redhat-release ]; then
	    release="centos"
	elif cat /etc/issue | grep -Eqi "debian"; then
	    release="debian"
	elif cat /etc/issue | grep -Eqi "ubuntu"; then
	    release="ubuntu"
	elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
	    release="centos"
	elif cat /proc/version | grep -Eqi "debian"; then
	    release="debian"
	elif cat /proc/version | grep -Eqi "ubuntu"; then
	    release="ubuntu"
	elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
	    release="centos"
	fi

	# check root
	[[ $EUID -ne 0 ]] && echo -e "${RED}Error:${PLAIN} This script must be run as root!" && exit 1

	# check python
	if  [ ! -e '/usr/bin/python' ]; then
	        echo "正在安装 Python"
	            if [ "${release}" == "centos" ]; then
	            		yum update > /dev/null 2>&1
	                    yum -y install python > /dev/null 2>&1
	                else
	                	apt-get update > /dev/null 2>&1
	                    apt-get -y install python > /dev/null 2>&1
	                fi
	        #else
	        #    exit
	        #fi
	        
	fi

	# check curl
	if  [ ! -e '/usr/bin/curl' ]; then
	        echo "正在安装 Curl"
	            if [ "${release}" == "centos" ]; then
	                yum update > /dev/null 2>&1
	                yum -y install curl > /dev/null 2>&1
	            else
	                apt-get update > /dev/null 2>&1
	                apt-get -y install curl > /dev/null 2>&1
	            fi
	fi

	# check wget
	if  [ ! -e '/usr/bin/wget' ]; then
	        echo "正在安装 Wget"
	            if [ "${release}" == "centos" ]; then
	                yum update > /dev/null 2>&1
	                yum -y install wget > /dev/null 2>&1
	            else
	                apt-get update > /dev/null 2>&1
	                apt-get -y install wget > /dev/null 2>&1
	            fi
	fi
	
	# check speedtest
	if  [ ! -e './speedtest-cli/speedtest' ]; then
		echo "正在安装 Speedtest-cli"
	#	mkdir -p /root/speedtest-cli && wget --no-check-certificate -O /root/speedtest-cli/speedtest https://raw.githubusercontent.com/user1121114685/speedtest_cli/master/spd_cli/x86_64/speedtest  > /dev/null 2>&1
	#fi
	#	chmod a+rx ./speedtest-cli/speedtest
		wget --no-check-certificate -qO speedtest.tgz https://install.speedtest.net/app/cli/ookla-speedtest-1.0.0-$(uname -m)-linux.tgz
		#wget --no-check-certificate -qO speedtest.tgz https://bintray.com/ookla/download/download_file?file_path=ookla-speedtest-1.0.0-$(uname -m)-linux.tgz 
	fi
	mkdir -p speedtest-cli && tar zxvf speedtest.tgz -C ./speedtest-cli/ > /dev/null 2>&1 && chmod a+rx ./speedtest-cli/speedtest

	# install virt-what
	#if  [ ! -e '/usr/sbin/virt-what' ]; then
	#	echo "Installing Virt-what ..."
	#    if [ "${release}" == "centos" ]; then
	#    	yum update > /dev/null 2>&1
	#        yum -y install virt-what > /dev/null 2>&1
	#    else
	#    	apt-get update > /dev/null 2>&1
	#        apt-get -y install virt-what > /dev/null 2>&1
	#    fi      
	#fi

	# install jq
	#if  [ ! -e '/usr/bin/jq' ]; then
	# 	echo " Installing Jq ..."
    #		if [ "${release}" == "centos" ]; then
	#	    yum update > /dev/null 2>&1
	#	    yum -y install jq > /dev/null 2>&1
	#	else
	#	    apt-get update > /dev/null 2>&1
	#	    apt-get -y install jq > /dev/null 2>&1
	#	fi      
	#fi
	# install tools.py
	if  [ ! -e 'tools.py' ]; then
		echo "正在安装 tools.py ..."
		wget --no-check-certificate https://raw.githubusercontent.com/oooldking/script/master/tools.py > /dev/null 2>&1
	fi
	chmod a+rx tools.py

	
	sleep 5

	# start
	start=$(date +%s) 
}

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g' | tee -a $log
}

speed_test(){
	speedLog="./benchmark.log"
	true > $speedLog
		speedtest-cli/speedtest -p no -s $1 --accept-license > $speedLog 2>&1
		is_upload=$(cat $speedLog | grep 'Upload')
		if [[ ${is_upload} ]]; then
	        local REDownload=$(cat $speedLog | awk -F ' ' '/Download/{print $3}')
	        local reupload=$(cat $speedLog | awk -F ' ' '/Upload/{print $3}')
	        local relatency=$(cat $speedLog | awk -F ' ' '/Latency/{print $2}')
	        
			local nodeID=$1
			local nodeLocation=$2
			local nodeISP=$3
			
			strnodeLocation="${nodeLocation}　　　　　　"
			LANG=C
			#echo $LANG
			
			temp=$(echo "${REDownload}" | awk -F ' ' '{print $1}')
	        if [[ $(awk -v num1=${temp} -v num2=0 'BEGIN{print(num1>num2)?"1":"0"}') -eq 1 ]]; then
	        	printf "${RED}%-6s${YELLOW}%s%s${GREEN}%-24s${CYAN}%s%-10s${BLUE}%s%-10s${PURPLE}%-8s${PLAIN}\n" "${nodeID}"  "${nodeISP}" "|" "${strnodeLocation:0:24}" "↑ " "${reupload}" "↓ " "${REDownload}" "${relatency}" | tee -a $log
			fi
		else
	        local cerror="ERROR"
		fi
}

selecttest() {
	echo -e "  测速类型:    ${GREEN}1.${PLAIN} 三网测速    ${GREEN}2.${PLAIN} 取消测速"
	echo -ne "               ${GREEN}3.${PLAIN} 电信节点    ${GREEN}4.${PLAIN} 联通节点    ${GREEN}5.${PLAIN} 移动节点"
	while :; do echo
			read -p "  请输入数字选择测速类型: " selection
			if [[ ! $selection =~ ^[1-5]$ ]]; then
					echo -ne "  ${RED}输入错误${PLAIN}, 请输入正确的数字!"
			else
					break   
			fi
	done
}

runtest() {
	[[ ${selection} == 2 ]] && exit 1

	if [[ ${selection} == 1 ]]; then
		echo "----------------------------------------------------------------------"
		echo "ID    测速服务器信息       上传/Mbps   下载/Mbps   延迟/ms"
		start=$(date +%s) 

		 speed_test '3633' '上海' '电信'
		 speed_test '24012' '内蒙古呼和浩特' '电信'
		 speed_test '27377' '北京５Ｇ' '电信'
		 speed_test '29026' '四川成都' '电信'
		# speed_test '29071' '四川成都' '电信'
		 speed_test '17145' '安徽合肥５Ｇ' '电信'
		 speed_test '27594' '广东广州５Ｇ' '电信'
		# speed_test '27810' '广西南宁' '电信'
		 speed_test '27575' '新疆乌鲁木齐' '电信'
		# speed_test '26352' '江苏南京５Ｇ' '电信'
		 speed_test '5396' '江苏苏州５Ｇ' '电信'
		# speed_test '5317' '江苏连云港５Ｇ' '电信'
		# speed_test '7509' '浙江杭州' '电信'
		 speed_test '23844' '湖北武汉' '电信'
		 speed_test '29353' '湖北武汉５Ｇ' '电信'
		 speed_test '28225' '湖南长沙５Ｇ' '电信'
		 speed_test '3973' '甘肃兰州' '电信'
		# speed_test '19076' '重庆' '电信'
		#***
		# speed_test '21005' '上海' '联通'
		 speed_test '24447' '上海５Ｇ' '联通'
		# speed_test '5103' '云南昆明' '联通'
		 speed_test '5145' '北京' '联通'
		# speed_test '5505' '北京' '联通'
		# speed_test '9484' '吉林长春' '联通'
		 speed_test '2461' '四川成都' '联通'
		 speed_test '27154' '天津５Ｇ' '联通'
		# speed_test '5509' '宁夏银川' '联通'
		# speed_test '5724' '安徽合肥' '联通'
		# speed_test '5039' '山东济南' '联通'
		 speed_test '26180' '山东济南５Ｇ' '联通'
		 speed_test '26678' '广东广州５Ｇ' '联通'
		# speed_test '16192' '广东深圳' '联通'
		# speed_test '6144' '新疆乌鲁木齐' '联通'
		 speed_test '13704' '江苏南京' '联通'
		 speed_test '5485' '湖北武汉' '联通'
		# speed_test '26677' '湖南株洲' '联通'
		 speed_test '4870' '湖南长沙' '联通'
		# speed_test '4690' '甘肃兰州' '联通'
		# speed_test '4884' '福建福州' '联通'
		# speed_test '31985' '重庆' '联通'
		 speed_test '4863' '陕西西安' '联通'
		#***
		# speed_test '30154' '上海' '移动'
		# speed_test '25637' '上海５Ｇ' '移动'
		# speed_test '26728' '云南昆明' '移动'
		# speed_test '27019' '内蒙古呼和浩特' '移动'
		 speed_test '30232' '内蒙呼和浩特５Ｇ' '移动'
		# speed_test '30293' '内蒙古通辽５Ｇ' '移动'
		 speed_test '25858' '北京' '移动'
		 speed_test '16375' '吉林长春' '移动'
		# speed_test '24337' '四川成都' '移动'
		 speed_test '17184' '天津５Ｇ' '移动'
		# speed_test '26940' '宁夏银川' '移动'
		# speed_test '31815' '宁夏银川' '移动'
		# speed_test '26404' '安徽合肥５Ｇ' '移动'
		 speed_test '27151' '山东临沂５Ｇ' '移动'
		# speed_test '25881' '山东济南５Ｇ' '移动'
		# speed_test '27100' '山东青岛５Ｇ' '移动'
		# speed_test '26501' '山西太原５Ｇ' '移动'
		 speed_test '31520' '广东中山' '移动'
		# speed_test '6611' '广东广州' '移动'
		# speed_test '4515' '广东深圳' '移动'
		# speed_test '15863' '广西南宁' '移动'
		# speed_test '16858' '新疆乌鲁木齐' '移动'
		 speed_test '26938' '新疆乌鲁木齐５Ｇ' '移动'
		# speed_test '17227' '新疆和田' '移动'
		# speed_test '17245' '新疆喀什' '移动'
		# speed_test '17222' '新疆阿勒泰' '移动'
		# speed_test '27249' '江苏南京５Ｇ' '移动'
		# speed_test '21845' '江苏常州５Ｇ' '移动'
		# speed_test '26850' '江苏无锡５Ｇ' '移动'
		# speed_test '17320' '江苏镇江５Ｇ' '移动'
		 speed_test '25883' '江西南昌５Ｇ' '移动'
		# speed_test '17223' '河北石家庄' '移动'
		# speed_test '26331' '河南郑州５Ｇ' '移动'
		# speed_test '6715' '浙江宁波５Ｇ' '移动'
		# speed_test '4647' '浙江杭州' '移动'
		# speed_test '16503' '海南海口' '移动'
		# speed_test '28491' '湖南长沙５Ｇ' '移动'
		# speed_test '16145' '甘肃兰州' '移动'
		 speed_test '16171' '福建福州' '移动'
		# speed_test '18444' '西藏拉萨' '移动'
		 speed_test '16398' '贵州贵阳' '移动'
		 speed_test '25728' '辽宁大连' '移动'
		# speed_test '16167' '辽宁沈阳' '移动'
		# speed_test '17584' '重庆' '移动'
		# speed_test '26380' '陕西西安' '移动'
		# speed_test '29105' '陕西西安５Ｇ' '移动'
		# speed_test '29083' '青海西宁５Ｇ' '移动'
		# speed_test '26656' '黑龙江哈尔滨' '移动'

		end=$(date +%s)  
		rm -rf speedtest*
		echo "----------------------------------------------------------------------"
		time=$(( $end - $start ))
		if [[ $time -gt 60 ]]; then
			min=$(expr $time / 60)
			sec=$(expr $time % 60)
			echo -ne "  测试完成, 本次测速耗时: ${min} 分 ${sec} 秒"
		else
			echo -ne "  测试完成, 本次测速耗时: ${time} 秒"
		fi
		echo -ne "\n  当前时间: "
		echo $(date +%Y-%m-%d" "%H:%M:%S)
		echo -e "  ${GREEN}# 三网测速中为避免节点数不均及测试过久，每部分未使用所${PLAIN}"
		echo -e "  ${GREEN}# 有节点，如果需要使用全部节点，可分别选择三网节点检测${PLAIN}"
	fi

	if [[ ${selection} == 3 ]]; then
		echo "----------------------------------------------------------------------"
		echo "ID    测速服务器信息       上传/Mbps   下载/Mbps   延迟/ms"
		start=$(date +%s) 

		 speed_test '3633' '上海' '电信'
		 speed_test '24012' '内蒙古呼和浩特' '电信'
		 speed_test '27377' '北京５Ｇ' '电信'
		 speed_test '29026' '四川成都' '电信'
		 speed_test '29071' '四川成都' '电信'
		 speed_test '17145' '安徽合肥５Ｇ' '电信'
		 speed_test '27594' '广东广州５Ｇ' '电信'
		 speed_test '27810' '广西南宁' '电信'
		 speed_test '27575' '新疆乌鲁木齐' '电信'
		 speed_test '26352' '江苏南京５Ｇ' '电信'
		 speed_test '5396' '江苏苏州５Ｇ' '电信'
		 speed_test '5317' '江苏连云港５Ｇ' '电信'
		 speed_test '7509' '浙江杭州' '电信'
		 speed_test '23844' '湖北武汉' '电信'
		 speed_test '29353' '湖北武汉５Ｇ' '电信'
		 speed_test '28225' '湖南长沙５Ｇ' '电信'
		 speed_test '3973' '甘肃兰州' '电信'
		 speed_test '19076' '重庆' '电信'

		end=$(date +%s)  
		rm -rf speedtest*
		echo "----------------------------------------------------------------------"
	fi
	

	if [[ ${selection} == 4 ]]; then
		echo "----------------------------------------------------------------------"
		echo "ID    测速服务器信息       上传/Mbps   下载/Mbps   延迟/ms"
		start=$(date +%s) 

		 speed_test '21005' '上海' '联通'
		 speed_test '24447' '上海５Ｇ' '联通'
		 speed_test '5103' '云南昆明' '联通'
		 speed_test '5145' '北京' '联通'
		 speed_test '5505' '北京' '联通'
		 speed_test '9484' '吉林长春' '联通'
		 speed_test '2461' '四川成都' '联通'
		 speed_test '27154' '天津５Ｇ' '联通'
		 speed_test '5509' '宁夏银川' '联通'
		 speed_test '5724' '安徽合肥' '联通'
		 speed_test '5039' '山东济南' '联通'
		 speed_test '26180' '山东济南５Ｇ' '联通'
		 speed_test '26678' '广东广州５Ｇ' '联通'
		 speed_test '16192' '广东深圳' '联通'
		 speed_test '6144' '新疆乌鲁木齐' '联通'
		 speed_test '13704' '江苏南京' '联通'
		 speed_test '5485' '湖北武汉' '联通'
		 speed_test '26677' '湖南株洲' '联通'
		 speed_test '4870' '湖南长沙' '联通'
		 speed_test '4690' '甘肃兰州' '联通'
		 speed_test '4884' '福建福州' '联通'
		 speed_test '31985' '重庆' '联通'
		 speed_test '4863' '陕西西安' '联通'

		end=$(date +%s)  
		rm -rf speedtest*
		echo "----------------------------------------------------------------------"
	fi


	if [[ ${selection} == 5 ]]; then
		echo "----------------------------------------------------------------------"
		echo "ID    测速服务器信息       上传/Mbps   下载/Mbps   延迟/ms"
		start=$(date +%s) 

		 speed_test '30154' '上海' '移动'
		 speed_test '25637' '上海５Ｇ' '移动'
		 speed_test '26728' '云南昆明' '移动'
		 speed_test '27019' '内蒙古呼和浩特' '移动'
		 speed_test '30232' '内蒙呼和浩特５Ｇ' '移动'
		 speed_test '30293' '内蒙古通辽５Ｇ' '移动'
		 speed_test '25858' '北京' '移动'
		 speed_test '16375' '吉林长春' '移动'
		 speed_test '24337' '四川成都' '移动'
		 speed_test '17184' '天津５Ｇ' '移动'
		 speed_test '26940' '宁夏银川' '移动'
		 speed_test '31815' '宁夏银川' '移动'
		 speed_test '26404' '安徽合肥５Ｇ' '移动'
		 speed_test '27151' '山东临沂５Ｇ' '移动'
		 speed_test '25881' '山东济南５Ｇ' '移动'
		 speed_test '27100' '山东青岛５Ｇ' '移动'
		 speed_test '26501' '山西太原５Ｇ' '移动'
		 speed_test '31520' '广东中山' '移动'
		 speed_test '6611' '广东广州' '移动'
		 speed_test '4515' '广东深圳' '移动'
		 speed_test '15863' '广西南宁' '移动'
		 speed_test '16858' '新疆乌鲁木齐' '移动'
		 speed_test '26938' '新疆乌鲁木齐５Ｇ' '移动'
		 speed_test '17227' '新疆和田' '移动'
		 speed_test '17245' '新疆喀什' '移动'
		 speed_test '17222' '新疆阿勒泰' '移动'
		 speed_test '27249' '江苏南京５Ｇ' '移动'
		 speed_test '21845' '江苏常州５Ｇ' '移动'
		 speed_test '26850' '江苏无锡５Ｇ' '移动'
		 speed_test '17320' '江苏镇江５Ｇ' '移动'
		 speed_test '25883' '江西南昌５Ｇ' '移动'
		 speed_test '17223' '河北石家庄' '移动'
		 speed_test '26331' '河南郑州５Ｇ' '移动'
		 speed_test '6715' '浙江宁波５Ｇ' '移动'
		 speed_test '4647' '浙江杭州' '移动'
		 speed_test '16503' '海南海口' '移动'
		 speed_test '28491' '湖南长沙５Ｇ' '移动'
		 speed_test '16145' '甘肃兰州' '移动'
		 speed_test '16171' '福建福州' '移动'
		 speed_test '18444' '西藏拉萨' '移动'
		 speed_test '16398' '贵州贵阳' '移动'
		 speed_test '25728' '辽宁大连' '移动'
		 speed_test '16167' '辽宁沈阳' '移动'
		 speed_test '17584' '重庆' '移动'
		 speed_test '26380' '陕西西安' '移动'
		 speed_test '29105' '陕西西安５Ｇ' '移动'
		 speed_test '29083' '青海西宁５Ｇ' '移动'
		 speed_test '26656' '黑龙江哈尔滨' '移动'

		end=$(date +%s)  
		rm -rf speedtest*
		echo "----------------------------------------------------------------------"
	fi
}

io_test() {
    (LANG=C dd if=/dev/zero of=test_file_$$ bs=512K count=$1 conv=fdatasync && rm -f test_file_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}

calc_disk() {
    local total_size=0
    local array=$@
    for size in ${array[@]}
    do
        [ "${size}" == "0" ] && size_t=0 || size_t=`echo ${size:0:${#size}-1}`
        [ "`echo ${size:(-1)}`" == "K" ] && size=0
        [ "`echo ${size:(-1)}`" == "M" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' / 1024}' )
        [ "`echo ${size:(-1)}`" == "T" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' * 1024}' )
        [ "`echo ${size:(-1)}`" == "G" ] && size=${size_t}
        total_size=$( awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}' )
    done
    echo ${total_size}
}

power_time() {

	result=$(smartctl -a $(result=$(cat /proc/mounts) && echo $(echo "$result" | awk '/data=ordered/{print $1}') | awk '{print $1}') 2>&1) && power_time=$(echo "$result" | awk '/Power_On/{print $10}') && echo "$power_time"
}

install_smart() {
	# install smartctl
	if  [ ! -e '/usr/sbin/smartctl' ]; then
		echo "正在安装 Smartctl ..."
	    if [ "${release}" == "centos" ]; then
	    	yum update > /dev/null 2>&1
	        yum -y install smartmontools > /dev/null 2>&1
	    else
	    	apt-get update > /dev/null 2>&1
	        apt-get -y install smartmontools > /dev/null 2>&1
	    fi      
	fi
}

ip_info(){
	# use jq tool
	result=$(curl -s 'http://ip-api.com/json')
	country=$(echo $result | jq '.country' | sed 's/\"//g')
	city=$(echo $result | jq '.city' | sed 's/\"//g')
	isp=$(echo $result | jq '.isp' | sed 's/\"//g')
	as_tmp=$(echo $result | jq '.as' | sed 's/\"//g')
	asn=$(echo $as_tmp | awk -F ' ' '{print $1}')
	org=$(echo $result | jq '.org' | sed 's/\"//g')
	countryCode=$(echo $result | jq '.countryCode' | sed 's/\"//g')
	region=$(echo $result | jq '.regionName' | sed 's/\"//g')
	if [ -z "$city" ]; then
		city=${region}
	fi

	echo -e " ASN & ISP           : ${SKYBLUE}$asn, $isp${PLAIN}" | tee -a $log
	echo -e " 机构                : ${YELLOW}$org${PLAIN}" | tee -a $log
	echo -e " 地理位置            : ${SKYBLUE}$city, ${YELLOW}$country / $countryCode${PLAIN}" | tee -a $log
	echo -e " 所在区域            : ${SKYBLUE}$region${PLAIN}" | tee -a $log
}

ip_info2(){
	# no jq
	country=$(curl -s https://ipapi.co/country_name/)
	city=$(curl -s https://ipapi.co/city/)
	asn=$(curl -s https://ipapi.co/asn/)
	org=$(curl -s https://ipapi.co/org/)
	countryCode=$(curl -s https://ipapi.co/country/)
	region=$(curl -s https://ipapi.co/region/)

	echo -e " ASN & ISP           : ${SKYBLUE}$asn${PLAIN}" | tee -a $log
	echo -e " 机构                : ${SKYBLUE}$org${PLAIN}" | tee -a $log
	echo -e " 地理位置            : ${SKYBLUE}$city, ${GREEN}$country / $countryCode${PLAIN}" | tee -a $log
	echo -e " 所在区域            : ${SKYBLUE}$region${PLAIN}" | tee -a $log
}

ip_info3(){
	# use python tool
	country=$(python ip_info.py country)
	city=$(python ip_info.py city)
	isp=$(python ip_info.py isp)
	as_tmp=$(python ip_info.py as)
	asn=$(echo $as_tmp | awk -F ' ' '{print $1}')
	org=$(python ip_info.py org)
	countryCode=$(python ip_info.py countryCode)
	region=$(python ip_info.py regionName)

	echo -e " ASN & ISP           : ${SKYBLUE}$asn, $isp${PLAIN}" | tee -a $log
	echo -e " 机构                : ${GREEN}$org${PLAIN}" | tee -a $log
	echo -e " 地理位置            : ${SKYBLUE}$city, ${GREEN}$country / $countryCode${PLAIN}" | tee -a $log
	echo -e " 所在区域            : ${SKYBLUE}$region${PLAIN}" | tee -a $log

	rm -rf ip_info.py
}

ip_info4(){
	ip_date=$(curl -4 -s http://api.ip.la/en?json)
	echo $ip_date > ip_json.json
	isp=$(python tools.py geoip isp)
	as_tmp=$(python tools.py geoip as)
	asn=$(echo $as_tmp | awk -F ' ' '{print $1}')
	org=$(python tools.py geoip org)
	if [ -z "ip_date" ]; then
		echo $ip_date
		echo "hala"
		country=$(python tools.py ipip country_name)
		city=$(python tools.py ipip city)
		countryCode=$(python tools.py ipip country_code)
		region=$(python tools.py ipip province)
	else
		country=$(python tools.py geoip country)
		city=$(python tools.py geoip city)
		countryCode=$(python tools.py geoip countryCode)
		region=$(python tools.py geoip regionName)	
	fi
	if [ -z "$city" ]; then
		city=${region}
	fi

	echo -e " ASN & ISP           : ${SKYBLUE}$asn, $isp${PLAIN}" | tee -a $log
	echo -e " 机构                : ${YELLOW}$org${PLAIN}" | tee -a $log
	echo -e " 地理位置            : ${SKYBLUE}$city, ${YELLOW}$country / $countryCode${PLAIN}" | tee -a $log
	echo -e " 所在区域            : ${SKYBLUE}$region${PLAIN}" | tee -a $log

	rm -rf tools.py
	rm -rf ip_json.json
}

virt_check(){
	if hash ifconfig 2>/dev/null; then
		eth=$(ifconfig)
	fi

	virtualx=$(dmesg) 2>/dev/null

	# check dmidecode cmd
	if  [ $(which dmidecode) ]; then
		sys_manu=$(dmidecode -s system-manufacturer) 2>/dev/null
		sys_product=$(dmidecode -s system-product-name) 2>/dev/null
		sys_ver=$(dmidecode -s system-version) 2>/dev/null
	else
		sys_manu=""
		sys_product=""
		sys_ver=""
	fi
	
	if grep docker /proc/1/cgroup -qa; then
	    virtual="Docker"
	elif grep lxc /proc/1/cgroup -qa; then
		virtual="Lxc"
	elif grep -qa container=lxc /proc/1/environ; then
		virtual="Lxc"
	elif [[ -f /proc/user_beancounters ]]; then
		virtual="OpenVZ"
	elif [[ "$virtualx" == *kvm-clock* ]]; then
		virtual="KVM"
	elif [[ "$cname" == *KVM* ]]; then
		virtual="KVM"
	elif [[ "$cname" == *QEMU* ]]; then
		virtual="KVM"
	elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
		virtual="VMware"
	elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
		virtual="Parallels"
	elif [[ "$virtualx" == *VirtualBox* ]]; then
		virtual="VirtualBox"
	elif [[ -e /proc/xen ]]; then
		virtual="Xen"
	elif [[ "$sys_manu" == *"Microsoft Corporation"* ]]; then
		if [[ "$sys_product" == *"Virtual Machine"* ]]; then
			if [[ "$sys_ver" == *"7.0"* || "$sys_ver" == *"Hyper-V" ]]; then
				virtual="Hyper-V"
			else
				virtual="Microsoft Virtual Machine"
			fi
		fi
	else
		virtual="Dedicated"
	fi
}

power_time_check(){
	echo -ne " Power time of disk   : "
	install_smart
	ptime=$(power_time)
	echo -e "${SKYBLUE}$ptime Hours${PLAIN}"
}

freedisk() {
	# check free space
	#spacename=$( df -m . | awk 'NR==2 {print $1}' )
	#spacenamelength=$(echo ${spacename} | awk '{print length($0)}')
	#if [[ $spacenamelength -gt 20 ]]; then
   	#	freespace=$( df -m . | awk 'NR==3 {print $3}' )
	#else
	#	freespace=$( df -m . | awk 'NR==2 {print $4}' )
	#fi
	freespace=$( df -m . | awk 'NR==2 {print $4}' )
	if [[ $freespace == "" ]]; then
		$freespace=$( df -m . | awk 'NR==3 {print $3}' )
	fi
	if [[ $freespace -gt 1024 ]]; then
		printf "%s" $((1024*2))
	elif [[ $freespace -gt 512 ]]; then
		printf "%s" $((512*2))
	elif [[ $freespace -gt 256 ]]; then
		printf "%s" $((256*2))
	elif [[ $freespace -gt 128 ]]; then
		printf "%s" $((128*2))
	else
		printf "1"
	fi
}

print_io() {
	if [[ $1 == "fast" ]]; then
		writemb=$((128*2))
	else
		writemb=$(freedisk)
	fi
	
	writemb_size="$(( writemb / 2 ))MB"
	if [[ $writemb_size == "1024MB" ]]; then
		writemb_size="1.0GB"
	fi

	if [[ $writemb != "1" ]]; then
		echo -n " I/O 测速( $writemb_size )   : " | tee -a $log
		io1=$( io_test $writemb )
		echo -e "${YELLOW}$io1${PLAIN}" | tee -a $log
		echo -n " I/O 测速( $writemb_size )   : " | tee -a $log
		io2=$( io_test $writemb )
		echo -e "${YELLOW}$io2${PLAIN}" | tee -a $log
		echo -n " I/O 测速( $writemb_size )   : " | tee -a $log
		io3=$( io_test $writemb )
		echo -e "${YELLOW}$io3${PLAIN}" | tee -a $log
		ioraw1=$( echo $io1 | awk 'NR==1 {print $1}' )
		[ "`echo $io1 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
		ioraw2=$( echo $io2 | awk 'NR==1 {print $1}' )
		[ "`echo $io2 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
		ioraw3=$( echo $io3 | awk 'NR==1 {print $1}' )
		[ "`echo $io3 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
		ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
		ioavg=$( awk 'BEGIN{printf "%.1f", '$ioall' / 3}' )
		echo -e " 平均 I/O 速度       : ${YELLOW}$ioavg MB/s${PLAIN}" | tee -a $log
	else
		echo -e " ${RED}Not enough space!${PLAIN}"
	fi
}

print_system_info() {
	echo -e " 虚拟架构            : ${SKYBLUE}$cname${PLAIN}" | tee -a $log
	echo -e " CPU 核心            : ${YELLOW}$cores Cores ${SKYBLUE}$freq MHz $arch${PLAIN}" | tee -a $log
	echo -e " CPU 缓存            : ${SKYBLUE}$corescache ${PLAIN}" | tee -a $log
	echo -e " 操作系统            : ${SKYBLUE}$opsy ($lbit Bit) ${YELLOW}$virtual${PLAIN}" | tee -a $log
	echo -e " 系统内核            : ${SKYBLUE}$kern${PLAIN}" | tee -a $log
	echo -e " 硬盘空间            : ${SKYBLUE}$disk_used_size GB / ${YELLOW}$disk_total_size GB ${PLAIN}" | tee -a $log
	echo -e " 系统内存            : ${SKYBLUE}$uram MB / ${YELLOW}$tram MB ${SKYBLUE}($bram MB Buff)${PLAIN}" | tee -a $log
	echo -e " SWAP 分配           : ${SKYBLUE}$uswap MB / $swap MB${PLAIN}" | tee -a $log
	echo -e " 系统已运行          : ${SKYBLUE}$up${PLAIN}" | tee -a $log
	echo -e " 系统负载            : ${SKYBLUE}$load${PLAIN}" | tee -a $log
	echo -e " TCP CC              : ${YELLOW}$tcpctrl${PLAIN}" | tee -a $log
}

print_end_time() {
	end=$(date +%s) 
	time=$(( $end - $start ))
	if [[ $time -gt 60 ]]; then
		min=$(expr $time / 60)
		sec=$(expr $time % 60)
		echo -ne " 消耗时间    : ${min} min ${sec} sec" | tee -a $log
	else
		echo -ne " 消耗时间    : ${time} sec" | tee -a $log
	fi
	#echo -ne "\n Current time : "
	#echo $(date +%Y-%m-%d" "%H:%M:%S)
	printf '\n' | tee -a $log
	#utc_time=$(date -u '+%F %T')
	#bj_time=$(date +%Y-%m-%d" "%H:%M:%S -d '+8 hours')
	bj_time=$(curl -s http://cgi.im.qq.com/cgi-bin/cgi_svrtime)
	#utc_time=$(date +"$bj_time" -d '-8 hours')

	if [[ $(echo $bj_time | grep "html") ]]; then
		bj_time=$(date -u +%Y-%m-%d" "%H:%M:%S -d '+8 hours')
	fi
	echo " 当前时间    : $bj_time GMT+8" | tee -a $log
	#echo " Finished!"
	echo " 结果保存到  : $log"
}

get_system_info() {
	cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
	freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	corescache=$( awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	tram=$( free -m | awk '/Mem/ {print $2}' )
	uram=$( free -m | awk '/Mem/ {print $3}' )
	bram=$( free -m | awk '/Mem/ {print $6}' )
	swap=$( free -m | awk '/Swap/ {print $2}' )
	uswap=$( free -m | awk '/Swap/ {print $3}' )
	up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days %d hour %d min\n",a,b,c)}' /proc/uptime )
	load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
	opsy=$( get_opsy )
	arch=$( uname -m )
	lbit=$( getconf LONG_BIT )
	kern=$( uname -r )
	#ipv6=$( wget -qO- -t1 -T2 ipv6.icanhazip.com )
	disk_size1=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $2}' ))
	disk_size2=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $3}' ))
	disk_total_size=$( calc_disk ${disk_size1[@]} )
	disk_used_size=$( calc_disk ${disk_size2[@]} )
	#tcp congestion control
	tcpctrl=$( sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}' )

	#tmp=$(python tools.py disk 0)
	#disk_total_size=$(echo $tmp | sed s/G//)
	#tmp=$(python tools.py disk 1)
	#disk_used_size=$(echo $tmp | sed s/G//)

	virt_check
}

sharetest() {
	echo " 分享测试结果:" | tee -a $log
	echo " 路 $result_speed" | tee -a $log
	log_preupload
	case $1 in
	'ubuntu')
		share_link="https://paste.ubuntu.com".$( curl -v --data-urlencode "content@$log_up" -d "poster=superbench.sh" -d "syntax=text" "https://paste.ubuntu.com" 2>&1 | \
			grep "地理位置" | awk '{print $3}' );;
	'haste' )
		share_link=$( curl -X POST -s -d "$(cat $log)" https://hastebin.com/documents | awk -F '"' '{print "https://hastebin.com/"$4}' );;
	'clbin' )
		share_link=$( curl -sF 'clbin=<-' https://clbin.com < $log );;
	'ptpb' )
		share_link=$( curl -sF c=@- https://ptpb.pw/?u=1 < $log );;
	esac

	# print result info
	echo " 路 $share_link" | tee -a $log
	next
	echo ""
	rm -f $log_up

}

log_preupload() {
	log_up="$HOME/superbench_upload.log"
	true > $log_up
	$(cat superbench.log 2>&1 | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" > $log_up)
}

get_ip_whois_org_name(){
	#ip=$(curl -s ip.sb)
	result=$(curl -s https://rest.db.ripe.net/search.json?query-string=$(curl -s ip.sb))
	#org_name=$(echo $result | jq '.objects.object.[1].attributes.attribute.[1].value' | sed 's/\"//g')
	org_name=$(echo $result | jq '.objects.object[1].attributes.attribute[1]' | sed 's/\"//g')
    echo $org_name;
}

pingtest() {
	local ping_ms=$( ping -w 1 -c 1 $1 | grep 'rtt' | cut -d"/" -f5 )

	# get download speed and print
	if [[ $ping_ms == "" ]]; then
		printf "ping 出现错误!"  | tee -a $log
	else
		printf "%3i.%s ms" "${ping_ms%.*}" "${ping_ms#*.}"  | tee -a $log
	fi
}

cleanup() {
	rm -f test_file_*;
	rm -f speedtest.py;
	rm -f fast_com*;
	rm -f tools.py;
	rm -f ip_json.json
}

bench_all(){
	mode_name="Standard"
	about;
	benchinit;
	clear
	next;
	preinfo
	get_system_info;
	print_system_info;
	ip_info4;
	next;
	print_io;
	speed_test;
	next;
	selecttest;
	runtest;
	next;
	print_end_time;
	next;
	cleanup;
	rm -rf speedtest*
	sharetest ubuntu;
}



log="$HOME/superbench.log"
true > $log

case $1 in
	'info'|'-i'|'--i'|'-info'|'--info' )
		about;sleep 3;next;get_system_info;print_system_info;next;;
    'version'|'-v'|'--v'|'-version'|'--version')
		next;about;next;;
   	'io'|'-io'|'--io'|'-drivespeed'|'--drivespeed' )
		next;print_io;next;;
	'speed'|'-speed'|'--speed'|'-speedtest'|'--speedtest'|'-speedcheck'|'--speedcheck' )
		about;benchinit;next;print_speedtest;next;cleanup;;
	'ip'|'-ip'|'--ip'|'geoip'|'-geoip'|'--geoip' )
		about;benchinit;next;ip_info4;next;cleanup;;
	'bench'|'-a'|'--a'|'-all'|'--all'|'-bench'|'--bench' )
		bench_all;;
	'about'|'-about'|'--about' )
		about;;
	'fast'|'-f'|'--f'|'-fast'|'--fast' )
		fast_bench;;
	'share'|'-s'|'--s'|'-share'|'--share' )
		bench_all;
		is_share="share"
		if [[ $2 == "" ]]; then
			sharetest ubuntu;
		else
			sharetest $2;
		fi
		;;
	'debug'|'-d'|'--d'|'-debug'|'--debug' )
		get_ip_whois_org_name;;
*)
    bench_all;;
esac



if [[  ! $is_share == "share" ]]; then
	case $2 in
		'share'|'-s'|'--s'|'-share'|'--share' )
			if [[ $3 == '' ]]; then
				sharetest ubuntu;
			else
				sharetest $3;
			fi
			;;
	esac
fi
