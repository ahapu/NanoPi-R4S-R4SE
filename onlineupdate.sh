#!/bin/bash
#Build by lone_wind
#清理文件
clean_up () {
    rm -rf *.img* ${img_path}/*.img* *sha256sums* *update*.sh*
}
#容器检查
docker_check () {
    if opkg list | grep -q "docker"; then
        if /etc/init.d/dockerd status | grep -q "running"; then
            /etc/init.d/dockerd stop
        fi
    fi
}
#硬盘检查
hd_check () {
    hd_id='mmcblk0'
    if [ ! -d /sys/block/$hd_id ]; then
        hd_id='mmcblk1'
        if [ ! -d /sys/block/$hd_id ]; then
            hd_id='sda'
        fi
    fi
}
#设备选择
machine_choose () {
    echo -e '\e[92m输入对应数字选择设备或退出\e[0m'
    echo -e '0 --- 退出\n1 --- R4S\n2 --- DN2\n3 --- X86'
    read -p "请输入数字[0-3],回车确认 " machine_num
    case $machine_num in
        0)
            echo -e '\e[91m退出脚本，升级结束\e[0m' && exit;
            ;;
        1)
            echo -e '\e[92m已选择R4S\e[0m'
            machine_id=1 && repo_id='NanoPi-R4S-R4SE'
            ;;
        2)
            echo -e '\e[92m已选择DN2\e[0m'
            machine_id=1 && repo_id='DoorNet2'
            ;;
        3)
            echo -e '\e[92m已选择X86\e[0m'
            machine_id=3 && repo_id='OpenWRT_x86_x64'
            ;;
        *)
            echo -e '\e[91m非法输入,请输入数字[0-3]\e[0m' && machine_choose
            ;;
    esac
}
#版本选择
version_choose () {
    echo -e '\e[92m根据数字选择固件版本或退出\e[0m'
    echo -e '0 --- Exit退出\n1 --- Docker_容器版\n2 --- Formal_正式版\n3 --- Stable_稳定版\n4 --- Lite_乞丐版'
    read -p "请输入数字[0-4],回车确认 " version_num
    case $version_num in
        0)
            echo -e '\e[91m退出脚本，升级结束\e[0m' && exit;
            ;;
        1)
            echo -e '\e[92m已选择Docker_容器版\e[0m' && version_num=docker
            ;;
        2)
            echo -e '\e[92m已选择Formal_正式版\e[0m' && version_num=full
            ;;
        3)
            echo -e '\e[92m已选择Stable_稳定版\e[0m' && version_num=slim
            ;;
        4)
            echo -e '\e[92m已选择Lite_乞丐版\e[0m' && version_num=beggar
            ;;
        *)
            echo -e '\e[91m非法输入,请输入数字[0-4]\e[0m' && version_choose
            ;;
    esac
}
#格式选择
format_choose () {
        echo -e '\e[92m根据数字选择固件格式或退出\e[0m'
        echo -e '0 --- 退出\n1 --- Ext4\n2 --- Squashfs'
    if [ $machine_num == 3 ];then
        echo -e '\e[91mX86固定使用Squashfs格式\e[0m'
        break
    else
        #echo -e '\e[92m根据数字选择固件格式或退出\e[0m'
        #echo -e '0 --- 退出\n1 --- Ext4\n2 --- Squashfs'
        read -p "请输入数字[0-2],回车确认 " format_num
        case $format_num in
            0)
                echo -e '\e[91m退出脚本，升级结束\e[0m' && exit;
                ;;
            1)
                echo -e '\e[92m已选择EXT4格式\e[0m' && format=ext4
                ;;
            2)
                echo -e '\e[92m已选择Squashfs格式\e[0m' && format=squashfs
                ;;
            *)
                echo -e '\e[91m非法输入,请输入数字[0-2]\e[0m' && format_choose
                ;;
        esac
    fi
}
#仓库选择
repo_set () {
    case $machine_num in
        1)
            firmware_id="friendlyarm_nanopi-r4s-${format}-sysupgrade.img"
            ;;
        2)
            firmware_id="embedfire_doornet2-${format}-sysupgrade.img"
            ;;
        3)
            firmware_id="x86-64-squashfs-efi.img"
            ;;
    esac
    proxy_url=https://ghproxy.com
    repo_url=https://github.com/ahapu/${repo_id}/releases
    firmware_url=${version_num}-${firmware_id}
}
#寻找固件
search_file () {
    cd ${work_path} && clean_up && days=$(($days+1))
    #echo `(date -d "@$(($(busybox date +%s) - 86400*($days-1)))" +%Y.%m.%d)`
    #wget -q ${proxy_url}/${repo_url}/download/$(date -d "@$(($(busybox date +%s) - 86400*($days-1)))" +%Y.%m.%d)-Lean${machine_id}/${version_num}-sha256sums
    wget -q ${repo_url}/download/$(date -d "@$(($(busybox date +%s) - 86400*($days-1)))" +%Y.%m.%d)-Lean${machine_id}/${version_num}-sha256sums
    exist_judge
}
#存在判断
exist_judge () {
    if [ -f ${version_num}-sha256sums ]; then
        echo -e '\e[92m已找到当前日期的固件\e[0m' && echo `(date -d "@$(($(busybox date +%s) - 86400*($days-1)))" +%Y.%m.%d)`
        firmware_confirm
    elif [ $days == 90 ]; then
        echo -e '\e[91m未找到合适固件，脚本退出\e[0m' && exit;
    else
        #echo -e '\e[91m当前固件不存在，寻找前一天的固件\e[0m'
        search_file
    fi
}
#固件确认
firmware_confirm () {
    read -r -p "是否使用此固件? [Y/N]确认 [E]退出 " skip
    case $skip in
        [yY][eE][sS]|[yY])
            echo -e '\e[92m已确认，开始下载固件\e[0m'
            #wget ${proxy_url}/${repo_url}/download/$(date -d "@$(($(busybox date +%s) - 86400*($days-1)))" +%Y.%m.%d)-Lean${machine_id}/${firmware_url}.gz
            wget ${repo_url}/download/$(date -d "@$(($(busybox date +%s) - 86400*($days-1)))" +%Y.%m.%d)-Lean${machine_id}/${firmware_url}.gz
            ;;
        [nN][oO]|[nN])
            echo -e '\e[91m寻找前一天的固件\e[0m' && search_file
            ;;
        [eE][xX][iI][tT]|[eE])
            echo -e '\e[91m取消固件下载，退出升级\e[0m' && clean_up && exit;
            ;;
        *)
            echo -e '\e[91m请输入[Y/N]进行确认，输入[E]退出\e[0m' && firmware_confirm
            ;;
    esac
}
#固件验证
firmware_check () {
    if [ -f ${img_path}/${firmware_url}  ]; then
        echo -e '\e[92m检查升级文件大小\e[0m' && du -sh ${img_path}/${firmware_url}
    elif [ -f ${firmware_url}.gz ]; then
        echo -e '\e[91m开始检查固件完整性\e[0m'
        sha256sum ${firmware_url}.gz | awk '{print $1}' > sha256sums_real
        grep -i ${firmware_url}.gz ${version_num}-sha256sums | awk '{print $1}' > sha256sums_true
        #if diff sha256sums_real sha256sums_true; then
        if cmp -s sha256sums_real sha256sums_true; then
            echo -e '\e[92msha256sum校验通过\e[0m'
        else
            echo -e '\e[91msha256sum校验失败\e[0m' && exit;
        fi
    else
        echo -e '\e[91m没有相关升级文件，请检查网络\e[0m' && exit;
    fi
    version_confirm
}
#版本确认
version_confirm () {
    read -p "是否确认升级? [Y/N] " confirm
    case $confirm in
        [yY][eE][sS]|[yY])
            echo -e '\e[92m已确认升级\e[0m'
            ;;
        [nN][oO]|[nN])
            echo -e '\e[91m已确认退出\e[0m' && clean_up && exit;
            ;;
        *)
            echo -e '\e[91m请输入[Y/N]进行确认\e[0m' && version_confirm
            ;;
    esac
}
#解压固件
unzip_fireware () {
    echo -e '\e[92m开始解压固件\e[0m' && gzip -cd ${firmware_url}.gz > ${img_path}/${firmware_url}
    if [ -f ${img_path}/${firmware_url} ]; then
        echo -e '\e[92m已解压出升级文件\e[0m' && firmware_check
    else
        echo -e '\e[91m解压固件失败\e[0m' && clean_up && exit;
    fi
}
#升级系统
update_system () {
    echo -e '\e[92m开始升级系统\e[0m'
    read -r -p "是否保存配置? [Y/N]确认 [E]退出 " skip
    case $skip in
        [yY][eE][sS]|[yY])
            echo -e '\e[92m已选择保存配置\e[0m' && sysupgrade -F ${firmware_url}
            ;;
        [nN][oO]|[nN])
            echo -e '\e[91m已选择不保存配置\e[0m' && sysupgrade -F -n ${firmware_url}
            ;;
        [eE][xX][iI][tT]|[eE])
            echo -e '\e[91m取消升级\e[0m' && clean_up && exit;
            ;;
        *)
            echo -e '\e[91m请输入[Y/N]进行确认，输入[E]退出\e[0m' && update_system
            ;;
    esac
}
#刷写系统
dd_system () {
    echo -e '\e[92m开始升级系统\e[0m'
    dd if=${img_path}/${firmware_url} of=/dev/${hd_id}
    echo -e '\e[92m刷写系统完毕，请手动断电再上电\e[0m'
}
#系统更新
update_firmware () {
    echo -e '\e[92mFusionWrt固件升级脚本\e[0m'
    echo -e '\e[91m---------------------\e[0m'
    img_path=/tmp && clean_up && docker_check && hd_check
    #machine_choose && version_choose && format_choose && repo_set
    machine_choose && version_choose && format_choose
    mount -t tmpfs -o remount,size=100% tmpfs /tmp
    real_mem=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}') && mini_mem=1572864
    if [ $real_mem -ge $mini_mem ]; then 
        work_path=/tmp
        #search_file && firmware_check && unzip_fireware && update_system
        repo_set && search_file && firmware_check && unzip_fireware && update_system
    else
        echo -e '\e[91m您的内存小于2G，升级将不保留配置\e[0m'
        work_path=/root
        if [ ${version_num} == begger ]; then
            echo -e '\e[92m固件版本为Lite_乞丐版\e[0m'
        else
            echo -e '\e[91m内存小，固件版本强制为Stable_稳定版\e[0m'
            version_num=slim
        fi
        #search_file && firmware_check && unzip_fireware && dd_system
        repo_set && search_file && firmware_check && unzip_fireware && dd_system
    fi
}

update_firmware
