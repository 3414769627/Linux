#!/bin/bash
# Mysql安装包所在路径,需要带上包名，示例：PACKAGE_FULL_WAY=/root/mysql-5.6.41-linux-glibc2.12-x86_64.tar.gz
readonly PACKAGE_FULL_WAY=
# Mysql安装主目录,示例：INSTALL_HOME=/usr/local/mysql
readonly INSTALL_HOME=
# Mysql数据库root用户密码,示例：USER_PASSWD=root
readonly USER_PASSWD=
 
#check user
if [[ "$UID" -ne 0 ]]; then
    echo "ERROR: the script must run as root"
    exit 3
fi
 
function log_info() {
    echo "[$(date -d today +"%Y-%m-%d %H:%M:%S %:::z")] $1"
}
 
function log_error() {
    echo -e "[$(date +"%Y-%m-%d %H:%M:%S %Z%:z")] [ERROR] $* \n"
    exit 1
 
}
 
function check_result() {
    local ret_code=$1
    shift
    local error_msg=$*
    if [[ ${ret_code} -ne 0 ]]; then
        log_error ${error_msg}
    fi
}
 
# 校验参数
function check_param() {
    if [[ ! -n ${PACKAGE_FULL_WAY} ]] || [[ ! -n ${INSTALL_HOME} ]] || [[ ! -n ${USER_PASSWD} ]]; then
        log_error "Param: PACKAGE_FULL_WAY INSTALL_HOME USER_PASSWD can not be null"
    fi
    if [[ ! -f ${PACKAGE_FULL_WAY} ]]; then
        log_error "Please check the config of PACKAGE_FULL_WAY dose config Mysql package name"
    fi
}
 
function check_mysql_process() {
    local mysql_process_count=`ps -ef |grep ${INSTALL_HOME}|grep -vwE "grep|vi|vim|tail|cat"|wc -l`
    if [[ ${mysql_process_count} -gt 0 ]]; then
        log_error "please stop and uninstall the mysql first"
    fi
}
 
# 新建mysql用户
function add_user() {
    #create group mysql
    grep "^mysql" /etc/group &> /dev/null
    if [[ $? -ne 0 ]]; then
        groupadd mysql
    fi
 
    #create user mysql
    id mysql &> /dev/null
    if [[ $? -ne 0 ]]; then
        useradd -g mysql mysql
        chage -M 99999 mysql
    fi
}
 
# 安装Mysql
function install_mysql() {
    # 创建安装主目录
    mkdir -p ${INSTALL_HOME}
    # 解压mysql到安装主目录
    tar -zxvf ${PACKAGE_FULL_WAY} -C ${INSTALL_HOME} > /dev/null 2>&1
    check_result $? "unzip Mysql package error"
    local package_name=`ls ${INSTALL_HOME} |grep mysql`
    mv ${INSTALL_HOME}/${package_name}/* ${INSTALL_HOME}
    rm -rf ${INSTALL_HOME}/${package_name}
    cd ${INSTALL_HOME}
 
    # 新建数据库目录
    mkdir -p ${INSTALL_HOME}/data/mysql
    chown -R mysql:mysql ${INSTALL_HOME}
 
    # 安装并指定用户和data文件夹位置
    ./scripts/mysql_install_db --user=mysql --datadir=${INSTALL_HOME}/data/mysql
 
    # 复制mysql到服务自动启动里面
    cp -pf ${INSTALL_HOME}/support-files/mysql.server /etc/init.d/mysqld
    chmod 755 /etc/init.d/mysqld
    # 复制配置文件到etc下
    cp -pf ${INSTALL_HOME}/support-files/my-default.cnf /etc/my.cnf
    chmod 755 /etc/my.cnf
    # 修改basedir和datadir
    sed -i "s#^basedir=.*#basedir=${INSTALL_HOME}#" /etc/init.d/mysqld
    sed -i "s#^datadir=.*#datadir=${INSTALL_HOME}\/data\/mysql#" /etc/init.d/mysqld
    # 加入环境变量,方便使用mysql命令,但是需要source /etc/profile
    echo "###MYSQL_PATH_ENV_S" >>/etc/profile
    echo "export PATH=${INSTALL_HOME}/bin:\$PATH" >> /etc/profile
    echo "###MYSQL_PATH_ENV_E" >> /etc/profile
    # 启动Mysql
    start
    # 修改Mysql用户root密码
    ./bin/mysqladmin -u root -h localhost.localdomain password ${USER_PASSWD}
    cd ${INSTALL_HOME}
 
# 开启远程登录权限
./bin/mysql -h127.0.0.1 -uroot -p${USER_PASSWD} << EOF
grant all privileges on *.* to root@'%' identified by 'root'; flush privileges;
EOF
    chown -R mysql:mysql ${INSTALL_HOME}
}
 
# 安装Mysql
function install() {
    log_info "+++++++++++ step 1 ++++++++++++++++"
    check_param
    log_info "check_param finish"
 
    log_info "+++++++++++ step 2 ++++++++++++++++"
    check_mysql_process
    log_info "check_mysql_process finish"
 
    log_info "+++++++++++ step 3 ++++++++++++++++"
    add_user
    log_info "add_user finish"
 
    log_info "+++++++++++ step 4 ++++++++++++++++"
    install_mysql
    log_info "install_mysql finish"
}
 
# 卸载Mysql
function uninstall() {
    # 如果Mysql仍启动则停止Msql
    local mysql_process_count=`ps -ef |grep ${INSTALL_HOME}|grep -vwE "grep|vi|vim|tail|cat"|wc -l`
    if [[ ${mysql_process_count} -gt 0 ]]; then
        stop
    fi
 
    # 删除创建的文件
    rm -rf ${INSTALL_HOME}
    rm -rf /etc/init.d/mysqld
    rm -rf /etc/my.cnf
 
    # 删除sock文件
    if [[ -f /tmp/mysql.sock ]]; then
        rm -rf /tmp/mysql.sock
    fi
 
    # 删除配置的环境变量
    sed -i '/###MYSQL_PATH_ENV_S/,/###MYSQL_PATH_ENV_E/d' /etc/profile
 
    #删除用户和用户组
    id mysql &> /dev/null
    if [[ $? -eq 0 ]]; then
        userdel mysql
    fi
    log_info "uninstall Mysql success"
}
 
# 停止Mysql
function stop() {
    su - mysql -c "service mysqld stop"
}
 
# 启动Mysql
function start() {
    su - mysql -c "service mysqld start"
}
 
# Mysql状态检查
function check_status() {
    su - mysql -c "service mysqld status"
}
 
function usage() {
    echo "Usage: $PROG_NAME {start|stop|install|uninstall|check_status}"
    exit 2
 
}
 
PROG_NAME=$0
ACTION=$1
 
case "$ACTION" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    restart)
        stop
        start
    ;;
    install)
        install
    ;;
    uninstall)
        uninstall
    ;;
    check_status)
        check_status
    ;;
    *)
        usage
    ;;
esac
#————————————————
#版权声明：本文为CSDN博主「左撇子帕布」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
#原文链接：https://blog.csdn.net/u011294519/article/details/89004581

