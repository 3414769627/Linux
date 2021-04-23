#!/usr/bin/bash
ver="1.0"
echo '当前安装程序版本'$ver
echo '@'whoami'欢迎使用'
echo "正在检测系统环境和相关依赖..."
if ! type gcc >/dev/null 2>&1; then
        echo "gcc        \033[31m [NO] \033[0m"
else
        echo "gcc        \033[32m [OK] \033[0m"
fi

if ! type wget >/dev/null 2>&1; then
        echo  "wget       \033[31m [NO] \033[0m"
else
        echo  "wget       \033[32m [OK] \033[0m"
fi

echo " \033[1;41;33m 警告:本工具需要在apt的基础上运行，基于yum的centOS可能
无法正常运行. \033[0m"
sleep 3.0
echo "开始更新系统..."
sleep 1.0
read -p "输入你的用户密码：" passwd
echo $passwd | sudo apt-get update && sudo apt-get upgrade
echo "更新完成."
echo "安装相关依赖包..."
sleep 2.0
echo $passwd | sudo apt-get -f install
echo "安装完成..."
