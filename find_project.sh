#!/bin/bash 

### Description: 查找给定地址的服务器的projects
### Author: foree
### Date: 20151025

#定义变量
ROJECT_LIST=""
source /home/fbash/.config/foree-tools/foree-tools.conf

#判断给定的目录是否是project根目录
function is_project_dir
{
    project_dir=$1
    base_dir=$2

    if [ -d $project_dir/.repo ];then
        if [ ! -z "$2" ];then
            echo "project dir is $base_dir/$project_dir"
        else
            echo "project dir is $project_dir"
        fi
        PROJECT_LIST="$PROJECT_LIST\n$base_dir/$project_dir"
    else
        return 2
    fi
}

#遍历服务器下的目录
function find_project_dir
{
    CURRENT_DIR=$PWD

    for i in ${!BRINGUP_SERVER_SAMBA_PATH[@]}
    do
        PROJECT_LIST=""
        cd ${BRINGUP_SERVER_SAMBA_PATH[$i]}
        level1_dir_list=$( find . -maxdepth 1 -type d |cut -d / -f 2 |grep -v '^\.' )
        for dir in $level1_dir_list
        do
            is_project_dir $dir
            if [ $? -eq '2' ];then
                cd $dir
                level2_dir_list=$( find . -maxdepth 1 -type d |cut -d / -f 2 |grep -v '^\.' )
                for level2_dir in $level2_dir_list
                do
                    is_project_dir $level2_dir $dir
                    if [ $? -eq '2' ];then
                        cd $level2_dir
                        level3_dir_list=$( find . -maxdepth 1 -type d |cut -d / -f 2 |grep -v '^\.' )
                        for level3_dir in $level3_dir_list
                        do
                            is_project_dir $level3_dir $dir/$level2_dir
                        done
                        cd ..
                    fi
                done
                cd ..
            fi
        done
        echo -e "$PROJECT_LIST" >$TOOLS_CONFIG_DIR/SERVER_$i
    done
    cd $CURRENT_DIR

}
find_project_dir
