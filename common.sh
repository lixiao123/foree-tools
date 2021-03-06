#!/bin/bash
### Description: 对于已经编译过的版本,可以直接lunch上一次编译的类型
### Author:foree
### Date:20151109

#一些约定的名称
#product = vendor_device 类似 meizu_m86
#variant 类似 eng
#device 类似 m86
#vendor 类似 meizu
#lunch = product-variant 类似 meizu_m86-eng

function yes_or_no
{
    read input_choice
    case $input_choice in
        y|yes|Y|Yes)
            echo 'y'
            ;;
        n|no|N|NO)
            echo 'n'
            ;;
        *)
            flog -E "input error,please again"
            yes_or_no
            ;;
    esac
}

#获取一个可能不带repo的Android Project的TOP目录
function _gettopdir()
{

    local TOPDIRFILE=build/core/envsetup.mk
    TOPDIR=
    HERE=`pwd`
    if [ ! -f $TOPDIRFILE ];then
        while [ ! -f $TOPDIRFILE -a "$PWD" != "/" ]; do
            \cd ..
            TOPDIR=`pwd -P`
        done
    else
        TOPDIR=`pwd -P`
    fi

    cd $HERE
    if [ -f $TOPDIR/$TOPDIRFILE ];then
        echo $TOPDIR
    fi
}

#获取一个带repo的Android Project的TOP目录
function _getrepodir()
{

    local REPODIRFILE=.repo/manifests/default.xml
    TOPDIR=
    HERE=`pwd`
    if [ ! -f $REPODIRFILE ];then
        while [ ! -f $REPODIRFILE -a "$PWD" != "/" ]; do
            \cd ..
            TOPDIR=`pwd -P`
        done
    else
        TOPDIR=`pwd -P`
    fi

    cd $HERE
    if [ -f $TOPDIR/$REPODIRFILE ];then
        echo $TOPDIR
    fi

}

#获取目标机型的out目录
function _getoutdir()
{
    local TOPDIR=$(_gettopdir)

    if [ -z $TOPDIR ];then flog -w "Not Found Project Here !!";return 1 ;fi

    local TARGET=$(_get_device_name)

    echo "out/target/product/$TARGET"
}

#获取目标机型的product名称
function _get_lunch_name()
{
    local TOPDIR=$(_gettopdir)

    if [ -z $TOPDIR ];then flog -w "Not Found Project Here !!";return 1 ;fi

    if [ -d $TOPDIR/out/target/product ];then
        cd $TOPDIR/out/target/product
    else
        flog -w "You Must be run lunch manually first !!" >&2
        return 1
    fi

    previous_path=$(find . -maxdepth 2 -name "previous_build_config.mk" |xargs ls -t1 | grep -v "generic")
    previous_number=$( echo "$previous_path" |wc -l )
    if [ $previous_number -eq '0' ];then
        flog -w "previous_build_config.mk not found, You Must be run lunch manually first !!"
        cd $HERE
        return 1
    elif [ $previous_number -gt '1' ];then
        previous_path=$(echo "$previous_path" |head -1)
    fi

    product_name=${previous_path#*/}
    product_name=${product_name%/*}

    lunch_name=$( grep $previous_path -e "[a-z]*_$product_name-[a-z]*" -o)

    echo $lunch_name

}

#获取Android Project的DEVICE
function _get_device_name()
{
    lunch_name=$(_get_lunch_name)

    device_name=$( echo -n $lunch_name |sed "s#[a-z]*_\(.*\)-[a-z]*#\1#" )

    echo $device_name
}

#获取Android Project的vendor
function _get_vendor_name()
{
    lunch_name=$(_get_lunch_name)

    vendor_name=$(echo -n $lunch_name |sed "s#\(.*\)_[a-z0-9]*-[a-z]*#\1#")

    echo $vendor_name
}

#使用shell内置getopts函数解析命令行参数的示例程序
function getopts_help
{
    while getopts ":s:h" args
    do
        case $args in
            s)
                echo "option is -s, argument is $OPTARG"
                ;;
            h)
                usage
                ;;
            ?)
                usage
                ;;
        esac
    done

    shift $(($OPTIND - 1))

    #solve other argument
    for arg in $@
    do
        echo "processing $arg"
    done

}

#使用外部程序getopt命令解析命令行参数的示例程序
function getopt_help
{
    # 使用getopt解析参数
    # s前边的:表示错误自己处理
    # -o 后边加短参数, --long 后边加长参数
    ARGS=`getopt -o :s:h --long search:,help -- "$@"`

    # 参数输入错误时的提示
    if [ $? != 0 ];then
        usage
        exit 1
    fi

    # 将规范化的命令行参数分配到位置参数{$1..$n}
    eval set -- "${ARGS}"

    while true
    do
        case "$1" in
            -s|--search)
                echo "Option s, argument $2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            --)
                shift
                break
                ;;
        esac
    done

    #解析命令行其他参数
    for arg in $@
    do
        echo "processing $arg"
    done

}

#Log函数：
#1.不同等级log不同颜色标识
#2.平常运行flogI(无色彩)，提示flogW(黄色)，运行出错flogE(红色)，并定位到错误管道，多余的信息flogD(蓝色)
#3.控制log打开使用
function flog()
{
    case $1 in
        -I|-i)
            #flogI
            #shift用于去除-i这个参数
            shift
            echo "$@"
            ;;
        -W|-w)
            #flogW
            #shift用于去除-w这个参数
            shift
            _echo_yellow "$@"
            ;;
        -E|-e)
            #flogE
                #shift用于去除-e这个参数
                shift
            _echo_red "$@"
            ;;
        -D|-d)
            #flogD
            if [ "x$DEBUG" = "xtrue" ];then
                #shift用于去除-d这个参数
                shift
                _echo_blue "$@"
            fi
            ;;
        *)
            ;;
    esac


}

#将输入的字符加红色flog -e
function _echo_red()
{
    echo -e "\033[31m$@\033[0m" >&2
}

#将输入的字符加天蓝色flog -d
function _echo_blue()
{

    echo -e "\033[36m$@\033[0m" >&2
}

#将输入的字符加黄色flog -w
function _echo_yellow()
{
    echo -e "\033[33m$@\033[0m" >&2
}

#将输入的字符加绿色
function _echo_green()
{
    echo -e "\033[32m$@\033[0m"
}
