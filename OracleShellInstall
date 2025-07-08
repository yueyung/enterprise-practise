#!/usr/bin/env bash
#==============================================================#
# File    :  OracleShellInstall
# Desc    :  Oracle Database Install for single/standlone
# Path    :  /soft/OracleShellInstall
# Version :  1.0.0
# Author  :  Lucifer(pc1107750981@163.com)
# Copyright (C) 2022-2099 Pengcheng Liu
#==============================================================#
# 导出 PS4 变量，以便 set -x 调试时输出行号和函数参数
export PS4='+${BASH_SOURCE}:${LINENO}:${FUNCNAME[0]}: '
#==============================================================#
#                         全局变量定义                           #
#==============================================================#
# 增加 bash 版本限制
bash_version=$(echo "$BASH_VERSION" | cut -d '.' -f1)
if [[ $bash_version ]] && ((bash_version < 4)); then
  printf "\n\E[1;31m%-20s\n\E[0m\n" "本脚本不支持 Bash 版本低于 4 执行安装，当前 Bash 版本为：$bash_version，已退出！"
  exit 1
fi
# 定义 Oracle 官方认证的操作系统列表
oracle_certified_os_list=(Red CentOS rhel centos ol)
# 获取安装软件以及脚本目录（当前目录）
software_dir=$(dirname "$(readlink -f "$0")")
# 当前执行脚本系统时间
current=$(date +%Y%m%d%H%M%S)
# 删除脚本生成的 log 日志文件
find "$software_dir" -name "print_shell_install_*.log" -exec /bin/rm -rf {} +
# 脚本安装日志文件
oracleinstalllog=$software_dir/print_shell_install_$current.log
# 定义 os 认证标识
oracle_os_flag=NONE
# 物理内存（KB）
os_memory_total=$(awk '/MemTotal/{print $2}' /proc/meminfo)
# Swap 大小（KB）
swap_total=$(awk '/^SwapTotal:/ { print $2; }' /proc/meminfo)
# 计算额外需要的交换空间大小
((swap_count = (os_memory_total > 16777216 ? 16777216 : os_memory_total > 2097152 ? os_memory_total : os_memory_total * 3 / 2) - swap_total))
# 主机名称，单机和单机 ASM 模式是当前主机名；
hostname=orcl
# 数据库名称，默认值为 orcl，支持多个实例，传参以逗号隔开：orcl,oradb
db_name=orcl
# 是否 CDB 架构
declare -l iscdb=false
# PDB 名称，如果 PDB 名称有值，则默认为 CDB 架构，默认值为 pdb01，如果传入多个 PDB 名称，则创建多个 PDB，传参以逗号隔开：pdb01,pdb02,pdb03
pdbname=pdb01
# 系统用户 oracle 名称，默认值为 oracle
oracle_user=oracle
# 系统用户 oracle 密码，默认值为 oracle
oracle_passwd=oracle
# 数据库用户 sys/system 密码, 默认值为 oracle
database_passwd=oracle
# 数据库软件安装根目录，默认值为 /u01
env_base_dir=/u01
# 单机数据库参数，数据文件目录，默认值为 /oradata
oradata_dir=/oradata
# 数据库备份目录，默认值为 /backup
backup_dir=/backup
# 数据库字符集，默认值为 AL32UTF8
declare -u db_characterset=AL32UTF8
# 数据库国家字符集，默认值为 AL16UTF16
declare -u nation_characterset=AL16UTF16
# 数据库块大小，默认值为 8192
db_block_size=8192
# 数据库在线重做日志大小，默认值为 1024，单位 MB
redosize=1024
# 数据库是否开启归档模式
declare -l enable_arch=true
# 仅配置操作系统，默认值为 N，包括配置操作系统以及解压软件安装包
declare -u only_conf_os=N
# 安装到 Grid 软件结束，默认值为 N
declare -u install_until_grid=N
# 安装到 Oracle 软件结束，默认值为 N
declare -u install_until_db=N
# 是否优化数据库参数，默认值为 N
declare -u optimize_db=N
# 数据库安装架构，分为单机和 standalone
declare -l oracle_install_mode
# 是否安装图形化界面，默认值为 N
declare -u isgui=N
# 默认配置本地源，默认值为 Y
declare -u local_repo=Y
# 默认不配置大页内存，默认值为 N
declare -u huge_flag=N
#==============================================================#
#                      Standalone 模式全局变量定义                #
#==============================================================#
# 系统用户 grid 名称，默认值为 grid
grid_user=grid
# 系统用户 grid 密码，默认值为 oracle
grid_passwd=oracle
# 是否配置 multipath 多路径，默认值为 Y
declare -u multipath=Y
# asm diskstring，默认值为 /dev/asm*
asmdisk_string="/dev/asm*"
# 是否配置 ASM 磁盘 UDEV 绑盘，默认值为 Y
declare -u asm_disk_conf=Y
# ASM 磁盘组名称，默认为 DATA,ARCH
declare -u data_asm_group=DATA
declare -u arch_asm_group=ARCH
# ASM 磁盘组冗余度，默认值为 EXTERNAL，可选值为 [EXTERNAL|NORMAL|HIGH]
declare -u data_redun=EXTERNAL
declare -u arch_redun=EXTERNAL
# 是否配置 AFD，默认值为 false
declare -l afd=false
# 修复 VBOX BUG，如果使用 VBOX 划盘安装 GRID，则需要设置为 Y，默认值为 N
declare -u virtualbox=N
#==============================================================#
#                           颜色打印                            #
#==============================================================#
function color_printf() {
  declare -u con_flag
  declare -A color_map=(
    ["red"]='\E[1;31m'
    ["green"]='\E[1;32m'
    ["blue"]='\E[1;34m'
    ["yellow"]='\E[1;33m'
    ["light_blue"]='\E[1;94m'
    ["purple"]='\033[35m'
  )
  local res='\E[0m' default_color='\E[1;32m'
  local color=${color_map[$1]:-"$default_color"}
  case "$1" in
  "red")
    # 打印红色文本并退出
    printf "\n${color}%-20s %-30s %-50s\n${res}\n" "$2" "$3" "$4"
    exit 1
    ;;
  "green" | "light_blue")
    # 打印绿色或浅蓝色文本
    printf "${color}%-20s %-30s %-50s\n${res}" "$2" "$3" "$4"
    ;;
  "purple")
    # 打印紫色文本并等待用户输入
    printf "${color}%-s${res}" "$2" "$3"
    read -r con_flag
    # 如果用户未输入，默认为继续
    if [[ -z $con_flag ]]; then
      con_flag=Y
    fi
    if [[ $con_flag != "Y" ]]; then
      echo
      exit 1
    fi
    ;;
  *)
    # 打印其他颜色文本
    printf "${color}%-20s %-30s %-50s\n${res}\n" "$2" "$3" "$4"
    ;;
  esac
}
#==============================================================#
#                          日志打印                             #
#==============================================================#
function log_print() {
  echo
  color_printf green "#==============================================================#"
  color_printf green "$1"
  color_printf green "#==============================================================#"
  echo
}
#==============================================================#
#                      执行命令并输出日志文件                      #
#==============================================================#
function execute_and_log() {
  local prompt="$1" cmd="$2" log_file="$oracleinstalllog" pid start_time end_time execution_time status
  # 打印提示信息
  echo -e "\e[1;34m${prompt}\e[0m\c"
  printf "......"
  # 记录开始时间
  start_time=$(date +%s)
  # 执行命令并将输出重定向到日志文件
  if [[ $debug_flag == "Y" ]]; then
    set -x
  fi
  eval "$cmd" >>"$log_file" 2>&1 &
  if [[ $debug_flag == "Y" ]]; then
    set +x
  fi
  pid=$!
  # 显示进度条
  while ps -p $pid >/dev/null 2>&1; do
    printf "."
    sleep 0.5
    printf "\b"
    sleep 0.5
  done
  # 记录结束时间
  end_time=$(date +%s)
  execution_time=$((end_time - start_time))
  # 等待命令执行完成
  wait $pid
  status=$?
  # 根据命令执行状态打印结果
  if ((status == 0 || status == 3)); then
    printf "已完成 (耗时: %s 秒)\n" "$execution_time"
  elif [[ $status != 0 && $cmd == "pkg_install" ]]; then
    printf "已完成 (耗时: %s 秒)\n" "$execution_time"
  else
    printf "执行出错，请检查日志 %s\n" "$log_file"
    exit 1
  fi
}
#==============================================================#
#                         脚本通用函数                           #
#==============================================================#
function checkpara_NULL() {
  # 检查参数是否为空
  if [[ -z $2 || $2 == -* ]]; then
    color_printf red "参数 [ $1 ] 的值为空，请检查！"
  fi
}
function checkpara_YN() {
  # 检查参数是否为 Y 或者 N
  if ! [[ $2 =~ ^[YyNn]$ ]]; then
    color_printf red "参数 [ $1 ] 的值 $2 必须为 Y 或者 N，请检查！"
  fi
}
function checkpara_tf() {
  # 检查参数是否为 Y 或者 N
  if ! [[ $2 =~ ^(true|false)$ ]]; then
    color_printf red "参数 [ $1 ] 的值 $2 必须为 true 或者 false，请检查！"
  fi
}

function checkpara_REDUN() {
  # 检查 RAC 参数是否为 EXTERNAL，NORMAL 或者 HIGH
  local REDUN="EXTERNAL|NORMAL|HIGH"
  if ! [[ $2 =~ ^($REDUN)$ ]]; then
    color_printf red "RAC 参数 [ $1 ] 的值 $2 必须为 EXTERNAL，NORMAL 或者 HIGH，请检查！"
  fi
}
function check_disknum() {
  local disk_identifier=$1 redun=$2 normal=$3 high=$4 disk_count=$5
  if [[ $redun == "NORMAL" ]]; then
    if ((disk_count < normal)); then
      color_printf red "$disk_identifier 磁盘组冗余度为 $redun 时，至少需要 $normal 块磁盘，请检查磁盘数量！"
    fi
  elif [[ $redun == "HIGH" ]]; then
    if ((disk_count < high)); then
      color_printf red "$disk_identifier 磁盘组冗余度为 $redun 时，至少需要 $high 块磁盘，请检查磁盘数量！"
    fi
  fi
}
function check_password() {
  local password="$2"
  # 密码中不能有不可见的控制字符，例如回车换行制表符等
  if [[ $password =~ [[:cntrl:]] ]]; then
    color_printf red "参数 [ $1 ] 的密码 $2 不符合要求，包含不可见字符，请检查！"
  fi
  if [[ $1 == "-dp" ]]; then
    if ! [[ $password =~ ^[a-zA-Z][a-zA-Z0-9#$_]*$ ]]; then
      color_printf red "参数 [ $1 ] 的密码 $2 不符合要求，必须以字母开头，并且字符只能包含 (_)，(#)，($) ，请检查！"
    fi
  fi
}
function checkpara_NUMERIC() {
  # 检查参数是否为数字
  if ! [[ $2 =~ ^[0-9]+$ ]]; then
    color_printf red "参数 [ $1 ] 的值 $2 不是数字，请检查！"
  fi
}
function checkpara_DBS() {
  # 检查 db_block_size 参数值
  local DBS="2048|4096|8192|16384|32768"
  if ! [[ $2 =~ ^($DBS)$ ]]; then
    color_printf red "参数 [ $1 ] 的值 $2 必须为 2048，4096，8192，16384 或者 32768，请检查！"
  fi
}
function checkpara_DBCHARSET() {
  # 所有有效字符集的列表 247 个
  local CHARSETS="AL16UTF16|AL24UTFFSS|AL32UTF8|AR8ADOS710|AR8ADOS710T|AR8ADOS720|AR8ADOS720T|AR8APTEC715|AR8APTEC715T|AR8ARABICMAC|AR8ARABICMACS|AR8ARABICMACT|AR8ASMO708PLUS|AR8ASMO8X|AR8EBCDIC420S|AR8EBCDICX|AR8HPARABIC8T|AR8ISO8859P6|AR8MSWIN1256|AR8MUSSAD768|AR8MUSSAD768T|AR8NAFITHA711|AR8NAFITHA711T|AR8NAFITHA721|AR8NAFITHA721T|AR8SAKHR706|AR8SAKHR707|AR8SAKHR707T|AR8XBASIC|AZ8ISO8859P9E|BG8MSWIN|BG8PC437S|BLT8CP921|BLT8EBCDIC1112|BLT8EBCDIC1112S|BLT8ISO8859P13|BLT8MSWIN1257|BLT8PC775|BN8BSCII|CDN8PC863|CE8BS2000|CEL8ISO8859P14|CH7DEC|CL8BS2000|CL8EBCDIC1025|CL8EBCDIC1025C|CL8EBCDIC1025R|CL8EBCDIC1025S|CL8EBCDIC1025X|CL8EBCDIC1158|CL8EBCDIC1158R|CL8ISO8859P5|CL8ISOIR111|CL8KOI8R|CL8KOI8U|CL8MACCYRILLIC|CL8MACCYRILLICS|CL8MSWIN1251|D7DEC|D7SIEMENS9780X|D8BS2000|D8EBCDIC1141|D8EBCDIC273|DK7SIEMENS9780X|DK8BS2000|DK8EBCDIC1142|DK8EBCDIC277|E7DEC|E7SIEMENS9780X|E8BS2000|EE8BS2000|EE8EBCDIC870|EE8EBCDIC870C|EE8EBCDIC870S|EE8ISO8859P2|EE8MACCE|EE8MACCES|EE8MACCROATIAN|EE8MACCROATIANS|EE8MSWIN1250|EE8PC852|EEC8EUROASCI|EEC8EUROPA3|EL8DEC|EL8EBCDIC423R|EL8EBCDIC875|EL8EBCDIC875R|EL8EBCDIC875S|EL8GCOS7|EL8ISO8859P7|EL8MACGREEK|EL8MACGREEKS|EL8MSWIN1253|EL8PC437S|EL8PC737|EL8PC851|EL8PC869|ET8MSWIN923|F7DEC|F7SIEMENS9780X|F8BS2000|F8EBCDIC1147|F8EBCDIC297|HU8ABMOD|HU8CWI2|I7DEC|I7SIEMENS9780X|I8EBCDIC1144|I8EBCDIC280|IN8ISCII|IS8MACICELANDIC|IS8MACICELANDICS|IS8PC861|IW7IS960|IW8EBCDIC1086|IW8EBCDIC424|IW8EBCDIC424S|IW8ISO8859P8|IW8MACHEBREW|IW8MACHEBREWS|IW8MSWIN1255|IW8PC1507|JA16DBCS|JA16DBCSFIXED|JA16EBCDIC930|JA16EUC|JA16EUCFIXED|JA16EUCTILDE|JA16EUCYEN|JA16MACSJIS|JA16SJIS|JA16SJISFIXED|JA16SJISTILDE|JA16SJISYEN|JA16VMS|KO16DBCS|KO16DBCSFIXED|KO16KSC5601|KO16KSC5601FIXED|KO16KSCCS|KO16MSWIN949|LA8ISO6937|LA8PASSPORT|LT8MSWIN921|LT8PC772|LT8PC774|LV8PC1117|LV8PC8LR|LV8RST104090|N7SIEMENS9780X|N8PC865|NDK7DEC|NE8ISO8859P10|NEE8ISO8859P4|NL7DEC|RU8BESTA|RU8PC855|RU8PC866|S7DEC|S7SIEMENS9780X|S8BS2000|S8EBCDIC1143|S8EBCDIC278|SE8ISO8859P3|SF7ASCII|SF7DEC|TH8MACTHAI|TH8MACTHAIS|TH8TISASCII|TH8TISEBCDIC|TH8TISEBCDICS|TR7DEC|TR8DEC|TR8EBCDIC1026|TR8EBCDIC1026S|TR8MACTURKISH|TR8MACTURKISHS|TR8MSWIN1254|TR8PC857|US7ASCII|US8BS2000|US8ICL|US8PC437|UTF8|UTFE|VN8MSWIN1258|VN8VN3|WE8BS2000|WE8BS2000E|WE8BS2000L5|
WE8DEC|WE8DG|WE8EBCDIC1047|WE8EBCDIC1047E|WE8EBCDIC1140|WE8EBCDIC1140C|WE8EBCDIC1145|WE8EBCDIC1146|WE8EBCDIC1148|WE8EBCDIC1148C|WE8EBCDIC284|WE8EBCDIC285|WE8EBCDIC37|WE8EBCDIC37C|WE8EBCDIC500|WE8EBCDIC500C|WE8EBCDIC871|WE8EBCDIC924|WE8GCOS7|WE8HP|WE8ICL|WE8ISO8859P1|WE8ISO8859P15|WE8ISO8859P9|WE8ISOICLUK|WE8MACROMAN8|WE8MACROMAN8S|WE8MSWIN1252|WE8NCR4970|WE8NEXTSTEP|WE8PC850|WE8PC858|WE8PC860|WE8ROMAN8|YUG7ASCII|ZHS16CGB231280|ZHS16CGB231280FIXED|ZHS16DBCS|ZHS16DBCSFIXED|ZHS16GBK|ZHS16GBKFIXED|ZHS16MACCGB231280|ZHS32GB18030|ZHT16BIG5|ZHT16BIG5FIXED|ZHT16CCDC|ZHT16DBCS|ZHT16DBCSFIXED|ZHT16DBT|ZHT16HKSCS|ZHT16HKSCS31|ZHT16MSWIN950|ZHT32EUC|ZHT32EUCFIXED|ZHT32SOPS|ZHT32TRIS|ZHT32TRISFIXED"
  # 检查参数是否在有效字符集列表中
  if ! [[ $2 =~ ^($CHARSETS)$ ]]; then
    color_printf red "数据库字符集参数 [ $1 ] 的值 $2 无效，请检查！"
  fi
}
function checkpara_NCHARSET() {
  # 所有有效字符集的列表
  local NCHARSETS="UTF8|AL16UTF16"
  # 检查参数是否在有效字符集列表中
  if ! [[ $2 =~ ^($NCHARSETS)$ ]]; then
    color_printf red "国家字符集参数 [ $1 ] 的值 $2 无效，请检查！"
  fi
}
function check_DBNAME() {
  local dbname="$1"
  local regex="^[a-zA-Z0-9]+$"
  if ! [[ $dbname =~ $regex ]]; then
    color_printf red "参数 [ -o ] 的值 $dbname 不符合要求，请使用数字和字母，不要使用特殊字符，请检查！"
  fi
}
function check_file() {
  # 检查文件是否存在
  if [[ -e "$1" ]]; then
    return 0
  else
    return 1
  fi
}
function mv_file() {
  local file_path=$1
  # 检查原始文件是否存在
  if ! check_file "$file_path".original; then
    # 检查文件是否存在
    if check_file "$file_path"; then
      # 不存在则备份为原始文件
      /bin/mv -f "$file_path"{,.original} >/dev/null 2>&1
    fi
  fi
}
function rm_file() {
  local file=$1
  # 检查文件是否存在
  if check_file "$file"; then
    # 不存在则备份为原始文件
    /bin/rm -rf "$file" >/dev/null 2>&1
  fi
}
function backup_restore_file() {
  local file_path=$1
  if check_file "$file_path"; then
    if (($(grep -E -c "# OracleBegin" "$file_path") == 0)); then
      /bin/cp -f "$file_path"{,.original}
    else
      /bin/cp -f "$file_path"{,."$current"}
      /bin/cp -f "$file_path"{.original,}
    fi
  else
    touch "$file_path".original
  fi
}
function write_file() {
  local flag=$1 file_name=$2 content=$3
  if [[ $flag == "Y" ]]; then
    cat <<-EOF >"$file_name"
$content
EOF
  elif [[ $flag == "N" ]]; then
    cat <<-EOF >>"$file_name"
$content
EOF
  fi
}
function run_as_oracle() {
  local command="$1"
  su - "$oracle_user" -c "$command"
}
function run_as_grid() {
  local command="$1"
  su - "$grid_user" -c "$command"
}
function execute_sqlplus() {
  local dbname="$1" format="$2" sql="$3"
  su - "$oracle_user" <<-SOF
source /home/$oracle_user/.$dbname
sqlplus -S / as sysdba<<-\EOF
set lin 2222 pages 1000 tab off feedback off
$format
$sql
exit;
EOF
SOF
}
function check_ip() {
  # 检查 IP 地址格式是否正确
  local ip=$1
  if echo "$ip" | grep -Eq "^([0-9]{1,3}\.){3}[0-9]{1,3}$"; then
    return 0
  else
    return 1
  fi
}
function check_ip_connectivity() {
  # 检查 IP 地址是否可以 ping 通
  local ip=$1
  if ! ping -c 1 "$ip" >/dev/null 2>&1; then
    color_printf red "IP地址 $ip 无法 ping 通，请检查！"
  fi
}
#============================================================#
#                          GET WWID                            #
#==============================================================#
function get_wwid() {
  local wwid scsi_id
  # 根据操作系统版本设置 scsi_id 命令路径
  if ((os_version == 6)); then
    scsi_id="/sbin/scsi_id"
  else
    scsi_id="/usr/lib/udev/scsi_id"
  fi
  # 获取磁盘的 WWID
  wwid=$("$scsi_id" -g -u "$1")
  echo "$wwid"
}
#==============================================================#
#                       Clean Disk                             #
#==============================================================#
function clean_disk_and_get_wwid() {
  local wwid_list wwid wwid_string identifier=$2 disk_count
  # 使用传入的磁盘列表，以逗号分隔的字符串
  IFS=',' read -ra disks <<<"$1"
  disk_count=${#disks[@]}
  # 遍历处理每个磁盘
  for disk in "${disks[@]}"; do
    if [[ -n "$disk" ]]; then
      # 检查磁盘头部
      if hexdump -C -n 102400 "$disk" | grep -q "$identifier"; then
        color_printf purple "检查 ASM 磁盘 [ $disk ] 中已存在磁盘组名称 [ $identifier ] 信息，请确认是否格式化磁盘 (Y/N): [Y] "
        echo
        dd if=/dev/zero of="$disk" bs=4096 count=1 >/dev/null 2>&1
      fi
      # 获取磁盘 WWID
      wwid=$(get_wwid "$disk")
      if [[ -z "$wwid" ]]; then
        color_printf red "磁盘 $disk 的 WWID 未获取到，请检查磁盘！"
      fi
      wwid_list+=("$wwid")
    fi
  done
  # 将磁盘 WWID 列表转换为逗号分隔的字符串
  wwid_string=$(
    IFS=,
    echo "${wwid_list[*]}"
  )
  # 根据标识符设置全局变量的磁盘 WWID
  case "$identifier" in
  "DATA")
    data_disk_wwid="$wwid_string"
    check_disknum "$identifier" "$data_redun" 2 3 "$disk_count"
    ;;
  "ARCH")
    arch_disk_wwid="$wwid_string"
    check_disknum "$identifier" "$arch_redun" 2 3 "$disk_count"
    ;;
  esac
}
#==============================================================#
#                   Conf Disk && GET WWID                      #
#==============================================================#
function conf_disk_wwid() {
  # 获取 ASM 磁盘 WWID 并格式化磁盘头
  local disk_types=("DATA" "ARCH")
  # 循环遍历磁盘类型，处理每种磁盘
  for disk_type in "${disk_types[@]}"; do
    local base_disk="${disk_type,,}_base_disk"
    if [[ "${!base_disk}" ]]; then
      clean_disk_and_get_wwid "${!base_disk}" "$disk_type"
    fi
  done
  if [[ $asm_disk_conf == "N" ]]; then
    datadisk=$data_base_disk
    archdisk=${arch_base_disk:+"$arch_base_disk"}
    # 构建 ASM 磁盘路径模式，格式为：磁盘目录/磁盘名前三个字符*
    asmdisk_string="$(dirname "${data_base_disk##*,}")/$(echo "${data_base_disk##*/}" | cut -c1-3)""*"
  fi
}
#==============================================================#
#                       过滤唯一 wwid 磁盘                       #
#==============================================================#
function filter_disk() {
  local fil_disk=$1 all_disks disk disk_list=() wwid
  declare -A wwids sizes
  # 获取磁盘存储大小的函数，返回值以 GB 为单位
  disk_storage() {
    lsblk -b -o SIZE,TYPE "${1}" | awk '$2 == "disk" {print $1/1024/1024/1024 "G"}'
  }
  # 获取所有磁盘名，以 sd 或 vd 开头的磁盘
  all_disks=$(lsblk -n -o NAME | awk '/^sd|vd/ { print $1 }')
  # 解析传入的过滤磁盘列表
  IFS=',' read -ra fil_disk_arr <<<"$fil_disk"
  # 过滤磁盘列表，排除在过滤列表中的磁盘
  for disk in $all_disks; do
    if ! [[ "${fil_disk_arr[*]}" =~ $disk ]]; then
      disk_list+=("/dev/$disk")
    fi
  done
  # 获取每个磁盘的大小和 WWID
  for disk in "${disk_list[@]}"; do
    sizes[$disk]=$(disk_storage "$disk")
    wwid=$(get_wwid "$disk")
    if [[ -n $wwid && ! "${wwids[*]}" =~ $wwid ]]; then
      wwids[$disk]=$wwid
    fi
  done
  # 打印磁盘信息
  color_printf light_blue "Disk WWID" "Disk Name" "Size"
  for disk in "${!wwids[@]}"; do
    color_printf green "${wwids[$disk]}" "$disk" "${sizes[$disk]}"
  done | sort -k3,3n -k2,2
}
# 定义一个函数来检查操作系统是否在给定列表中
function is_in_list() {
  local item=$1
  shift
  local list=("$@")
  for element in "${list[@]}"; do
    if [[ "$item" == "$element" ]]; then
      return 0
    fi
  done
  return 1
}
function check_md5sum() {
  local file_name=$1
  local expected_md5=$2
  color_printf green "正在检测安装包 $file_name 的 MD5 值是否正确，请稍等......"
  if [[ $(md5sum "$file_name" | awk '{print $1}') != "$expected_md5" ]]; then
    color_printf red "请检查 $file_name 文件的完整性，确保 md5sum 值为 $expected_md5！"
  fi
}
# 检查 Oracle 兼容性
function check_oracle_compatibility() {
  check_version_compatibility() {
    local supported_versions="$1"
    # 检查操作系统版本是否兼容
    if [[ "$os_version" =~ ^($supported_versions)$ ]]; then
      oracle_os_flag=Y
    else
      oracle_os_flag=N
    fi
  }
  # 检查 Oracle 官方认证的操作系统
  check_oracle_certified_os() {
    if is_in_list "$os_type" "${oracle_certified_os_list[@]}"; then
      case "$db_version" in
      11 | 12) check_version_compatibility "6|7" ;;
      19) check_version_compatibility "7|8|9" ;;
      21) check_version_compatibility "7|8" ;;
      23) check_version_compatibility "8" ;;
      esac
    fi
  }
  check_oracle_certified_os
  if [[ "$oracle_os_flag" == "N" ]]; then
    color_printf red "当前操作系统版本是 [ $pretty_name ] 不在 Oracle 官方支持列表，开源版本暂不支持，请联系开发者获取支持！"
    echo
  elif [[ "$oracle_os_flag" == "NONE" ]]; then
    color_printf red "当前操作系统版本是 [ $pretty_name ] 不在脚本支持列表中，开源版本暂不支持，请联系开发者获取支持！"
  fi
}
#==============================================================#
#                             Usage                            #
#==============================================================#
function help() {
  # 打印参数
  print_options() {
    local options=("$@")
    # 调用 color_printf 函数，输出绿色字体
    # ${option%% *} 表示从 option 变量中删除最后一个空格及其后面的字符，保留前面的部分
    # ${option#* } 表示从 option 变量中删除第一个空格及其前面的字符，保留后面的部分
    for option in "${options[@]}"; do
      color_printf green "${option%% *}" "${option#* }"
    done
  }
  # 单机模式
  color_printf blue "用法: OracleShellInstall [选项] 对象 { 命令 | help }"
  color_printf blue "单机模式："
  options=(
    "-lrp 配置本地软件源，需要挂载本地 ISO 镜像源，默认值：[Y]"
    "-lf [必填] 公网 IP 的网卡名称"
    "-n 主机名，默认值：[orcl]"
    "-ou 系统 oracle 用户名称，默认值：[oracle]"
    "-op 系统 oracle 用户密码，若包含特殊字符必须以单引号包裹，例如：'Passw0rd#'，默认值：[oracle]"
    "-d Oracle 软件安装根目录，默认值：[/u01]"
    "-ord Oracle 数据文件目录，默认值：[/oradata]"
    "-ard Oracle 归档文件目录，默认值：[/oradata/archivelog]"
    "-o Oracle 数据库名称，默认值：[orcl]"
    "-dp Oracle 数据库 sys/system 密码，若包含特殊字符(_,#,$)必须以单引号包裹，例如：'Passw0rd#'，默认值：[oracle]"
    "-ds 数据库字符集，默认值：[AL32UTF8]"
    "-ns 数据库国家字符集，默认值：[AL16UTF16]"
    "-dbs 数据库块大小，默认值：[8192]，可选：[2048|4096|8192|16384|32768]"
    "-er 是否启用归档日志，默认值：[true]"
    "-pdb 用于 CDB 架构，PDB 名称，支持传入多个PDB：-pdb pdb01,pdb02，默认值：[pdb01]"
    "-redo 数据库 redo 日志文件大小，单位为 MB，默认值[1024]"
    "-m 仅配置操作系统，默认值：[N]"
    "-ud 安装到 Oracle 软件结束，默认值：[N]"
    "-gui 是否安装系统图形界面，默认值：[N]"
    "-opd 安装完成是否优化 Oracle 数据库，默认值：[N]"
    "-hf 安装完成是否配置内存大页，默认值：[N]"
  )
  print_options "${options[@]}"
  # 单机 ASM 模式
  echo
  color_printf blue "单机 ASM 模式："
  options=(
    "-lrp 配置本地软件源，需要挂载本地 ISO 镜像源，默认值：[Y]"
    "-lf [必填] 公网 IP 的网卡名称"
    "-n 主机名，默认值：[orcl]"
    "-ou 系统 oracle 用户名称，默认值：[oracle]"
    "-op 系统 oracle 用户密码，若包含特殊字符必须以单引号包裹，例如：'Passw0rd#'，默认值：[oracle]"
    "-d Oracle 软件安装根目录，默认值：[/u01]"
    "-ord Oracle 数据文件目录，默认值：[/oradata]"
    "-o Oracle 数据库名称，默认值：[orcl]"
    "-gu 系统 grid 用户名称，默认值：[grid]"
    "-gp 系统 grid 用户密码，，若包含特殊字符必须以单引号包裹，例如：'Passw0rd#'，默认值：[oracle]"
    "-dp Oracle 数据库 sys/system 密码，若包含特殊字符(_,#,$)必须以单引号包裹，例如：'Passw0rd#'，默认值：[oracle]"
    "-adc 是否需要脚本配置 ASM 磁盘，如果不需要配置，则需要自行提前配置好，默认值：[Y]"
    "-mp 是否需要脚本配置 multipath 多路径，如果不需要配置多路径，则使用UDEV直接绑盘，默认值：[Y]"
    "-dd [必填] ASM DATA 磁盘组的磁盘列表，默认传参为(sd名称)：-dd /dev/sdb：若设置参数 -adc N，则传入已配置好的磁盘列表：-dd /dev/asm_data1"
    "-dn ASM DATA 磁盘组名称，默认值：[DATA]"
    "-dr ASM DATA 磁盘组冗余度，默认值：[EXTERNAL]"
    "-ds 数据库字符集，默认值：[AL32UTF8]"
    "-ns 数据库国家字符集，默认值：[AL16UTF16]"
    "-dbs 数据库块大小，默认值：[8192]，可选：[2048|4096|8192|16384|32768]"
    "-er 是否启用归档日志，默认值：[true]"
    "-pdb 用于 CDB 架构，PDB 名称，支持传入多个PDB：-pdb pdb01,pdb02，默认值：[pdb01]"
    "-redo 数据库 redo 日志文件大小，单位为 MB，默认值[1024]"
    "-m 仅配置操作系统，默认值：[N]"
    "-ud 安装到 Oracle 软件结束，默认值：[N]"
    "-gui 是否安装系统图形界面，默认值：[N]"
    "-opd 安装完成是否优化 Oracle 数据库，默认值：[N]"
    "-vbox 在虚拟机 virtualbox 上安装 RAC 时需要设置 -vbox Y，用于修复 BUG，默认值：[N]"
    "-fd 过滤多路径磁盘，去除重复路径，获取唯一盘符：参数值为非ASM盘符（系统盘等），例如：-fd /dev/sda，多个盘符用逗号拼接：-fd /dev/sda,/dev/sdb"
    "-hf 安装完成是否配置内存大页，默认值：[N]"
  )
  print_options "${options[@]}"
}
#==============================================================#
#                       获取 Grid 安装包信息                     #
#==============================================================#
function get_grid_soft() {
  case "$gi_version" in
  "11")
    cvu_name="cvuqdisk-1.0.9-1.rpm"
    ;;
  *)
    cvu_name="cvuqdisk-1.0.10-1.rpm"
    ;;
  esac
  declare -A gi_version_dirs=(
    ["11"]="$env_base_dir/app/11.2.0/grid;$software_dir/p13390677_112040_Linux-x86-64_3of7.zip;$software_dir/grid/rpm/$cvu_name;11.2.0.4.0"
    ["12"]="$env_base_dir/app/12.2.0/grid;$software_dir/LINUX.X64_122010_grid_home.zip;$env_grid_home/cv/rpm/$cvu_name;12.2.0.1.0"
    ["19"]="$env_base_dir/app/19.3.0/grid;$software_dir/LINUX.X64_193000_grid_home.zip;$env_grid_home/cv/rpm/$cvu_name;19.0.0.0.0"
    ["21"]="$env_base_dir/app/21.3.0/grid;$software_dir/LINUX.X64_213000_grid_home.zip;$env_grid_home/cv/rpm/$cvu_name;21.0.0.0.0"
    ["23"]="$env_base_dir/app/23.5.0/grid;$software_dir/LINUX.X64_235000_forEngineeredSystems_grid_home.zip;$env_grid_home/cv/rpm/$cvu_name;23.0.0.0.0"
  )
  # 根据选择的 Grid 数据库版本
  IFS=";" read -r env_grid_home grid_soft_name cvuqdisk gi_compatible <<<"${gi_version_dirs[$gi_version]}"
  if check_file "$grid_soft_name"; then
    case "${gi_version}" in
    "11")
      check_md5sum "$grid_soft_name" "04cef37991db18f8190f7d4a19b26912"
      ;;
    "12")
      check_md5sum "$grid_soft_name" "ac1b156334cc5e8f8e5bd7fcdbebff82"
      ;;
    "19")
      check_md5sum "$grid_soft_name" "b7c4c66f801f92d14faa0d791ccda721"
      ;;
    "21")
      check_md5sum "$grid_soft_name" "b3fbdb7621ad82cbd4f40943effdd1be"
      ;;
    "23")
      check_md5sum "$grid_soft_name" "bc13cfe0beecd5fd1a75132a7f46bb09"
      ;;
    esac
  else
    color_printf red "请检查 Grid 软件安装包 $grid_soft_name 是否已上传至 $software_dir 目录下！"
  fi
}
#==============================================================#
#                      获取 Oracle 安装包信息                    #
#==============================================================#
function get_db_soft() {
  # 定义 oracle 相关信息
  declare -A db_version_dirs=(
    ["11"]="$env_oracle_base/product/11.2.0/db;$software_dir/p13390677_112040_Linux-x86-64_1of7.zip;$software_dir/p13390677_112040_Linux-x86-64_2of7.zip;;11.2.0.4.0"
    ["12"]="$env_oracle_base/product/12.2.0/db;$software_dir/LINUX.X64_122010_db_home.zip;;$iscdb;12.2.0.1.0"
    ["19"]="$env_oracle_base/product/19.3.0/db;$software_dir/LINUX.X64_193000_db_home.zip;;$iscdb;19.0.0.0.0"
    ["21"]="$env_oracle_base/product/21.3.0/db;$software_dir/LINUX.X64_213000_db_home.zip;;true;21.0.0.0.0"
    ["23"]="$env_oracle_base/product/23.5.0/db;$software_dir/LINUX.X64_235000_forEngineeredSystems_db_home.zip;;true;23.0.0.0.0"
  )
  # 根据选择的 Oracle 数据库版本
  IFS=";" read -r env_oracle_home db_soft_name db_soft_name1 iscdb db_compatible <<<"${db_version_dirs[$db_version]}"
  if ((db_version == 11)); then
    if check_file "$db_soft_name" && check_file "$db_soft_name1"; then
      check_md5sum "$db_soft_name" "1616f61789891a56eafd40de79f58f28"
      check_md5sum "$db_soft_name1" "67ba1e68a4f581b305885114768443d3"
    else
      color_printf red "请检查 Oracle 软件安装包 $db_soft_name,$db_soft_name1 是否已上传至 $software_dir 目录下。"
    fi
  else
    if check_file "$db_soft_name"; then
      case "${db_version}" in
      "12")
        check_md5sum "$db_soft_name" "1841f2ce7709cf909db4c064d80aae79"
        ;;
      "19")
        check_md5sum "$db_soft_name" "1858bd0d281c60f4ddabd87b1c214a4f"
        ;;
      "21")
        check_md5sum "$db_soft_name" "8ac915a800800ddf16a382506d3953db"
        ;;
      "23")
        check_md5sum "$db_soft_name" "2260486cc0383504b35593c40a256a18"
        ;;
      esac
    else
      color_printf red "请检查 Oracle 软件安装包 $db_soft_name 是否已上传至 $software_dir 目录下。"
    fi
  fi
}
#==============================================================#
#                        检查 ISO 镜像源挂载                     #
#==============================================================#
function check_iso() {
  # 获取ISO镜像挂载路径，排除光盘挂载的路径 iso9660 以及被删除挂载 ISO 的路径
  mountPath=$(mount | awk '/iso9660/ && !/(deleted)/ && !/run\/media/ && !/\/media/ {print $3}')
  # 检查是否存在多个挂载路径，存在则报错退出
  if [[ $(echo "$mountPath" | wc -l) -gt 1 ]]; then
    echo "$mountPath"
    color_printf red "当前主机存在多个 ISO 镜像源，脚本无法判断，请务必只保留一个！"
  fi
  # 检查是否需要挂载 ISO 镜像源
  if [[ -z $mountPath ]]; then
    # 脚本尝试挂载 ISO 镜像
    if mount /dev/sr0 /mnt >/dev/null 2>&1; then
      mountPath=/mnt
    else
      color_printf red "本地软件源配置需要挂载 ISO 镜像源，建议挂载 Everything ISO 源！"
    fi
  fi
}
#==============================================================#
#                         备份官方软件源                         #
#==============================================================#
# 创建备份目录并移动文件
function backup_repos() {
  local bak_type="$1" source_repo="$2" backup_repo="$3"
  /bin/mkdir -p "$backup_repo" >/dev/null 2>&1
  if [[ "$bak_type" == "d" ]]; then
    find "$source_repo" -mindepth 1 -maxdepth 1 -type f -exec /bin/mv -f {} "$backup_repo" \; >/dev/null 2>&1
  elif [[ "$bak_type" == "f" ]]; then
    /bin/mv -f "$source_repo" "$backup_repo" >/dev/null 2>&1
  fi
}
#==============================================================#
#                        配置本地软件源                          #
#==============================================================#
function conf_local_repository() {
  log_print "配置本地软件源"
  # 配置本地软件源（单一目录）
  conf_rhel7_repository() {
    backup_repos "d" "/etc/yum.repos.d/" "/etc/yum.repos.d/bak"
    write_file "Y" "/etc/yum.repos.d/local.repo" "[server]
name=server
baseurl=file://$mountPath
enabled=1
gpgcheck=0"
    cat /etc/yum.repos.d/local.repo
  }
  conf_rhel8_repository() {
    backup_repos "d" "/etc/yum.repos.d/" "/etc/yum.repos.d/bak"
    write_file "Y" "/etc/yum.repos.d/local.repo" "[BaseOS]
name=BaseOS
baseurl=file://$mountPath/BaseOS
enabled=1
gpgcheck=0
[AppStream]
name=AppStream
baseurl=file://$mountPath/AppStream
enabled=1
gpgcheck=0"
    cat /etc/yum.repos.d/local.repo
  }
  # 配置本地软件源（分离 BaseOS 和 AppStream）
  conf_rhel_repository() {
    if ((os_version >= 8)); then
      conf_rhel8_repository
    else
      conf_rhel7_repository
    fi
  }
  conf_rhel_repository
}
#==============================================================#
#                            杀进程                             #
#==============================================================#
function kill_process() {
  local process_name=$1
  pgrep -f "$process_name" | awk '{system("pkill -9 -f "$1)}' >/dev/null 2>&1
}
#==============================================================#
#                        级联删除文件夹内容                       #
#==============================================================#
function cascade_del_file() {
  local file_path=$1
  if [[ -d "$file_path" ]]; then
    find "$file_path" -mindepth 1 -delete >/dev/null 2>&1
  elif [[ -f "$file_path" ]]; then
    /bin/rm -f "$file_path" >/dev/null 2>&1
  fi
}
#==============================================================#
#                         打印环境信息                           #
#==============================================================#
function print_sysinfo() {
  log_print "打印系统信息"
  print_cpu_info() {
    # 定义关联数组的键的顺序
    local keys=("A" "B" "C" "D" "E")
    # 保存要提取的信息的关键词
    declare -A keywords=(
      ["A"]="$(grep </proc/cpuinfo "model name" | head -n 1 | awk -F ': ' '{print $2}')"
      ["A_DESC"]="型号名称                "
      ["B"]="$(grep </proc/cpuinfo "physical id" | sort | uniq | wc -l)"
      ["B_DESC"]="物理 CPU 个数           "
      ["C"]="$(grep </proc/cpuinfo "core id" | sort -u | wc -l)"
      ["C_DESC"]="每个物理 CPU 的逻辑核数 "
      ["D"]="$(grep -c "processor" /proc/cpuinfo)"
      ["D_DESC"]="系统的 CPU 线程数       "
      ["E"]="$cpu_type"
      ["E_DESC"]="系统的 CPU 类型         "
    )
    # 循环提取信息并按顺序打印
    for key in "${keys[@]}"; do
      local desc="${keywords[${key}_DESC]}"
      local value="${keywords[$key]}"
      color_printf green "$desc ：$value"
    done
  }
  ## 服务器时间
  color_printf blue "服务器时间: "
  date
  ## 操作系统版本
  echo
  color_printf blue "操作系统版本: "
  if check_file /etc/os-release; then
    cat /etc/os-release
  elif check_file /etc/system-release; then
    cat /etc/system-release
  elif check_file /etc/redhat-release; then
    cat /etc/redhat-release
  fi
  ## 内核信息
  echo
  color_printf blue "内核信息: "
  cat /proc/version
  ## glibc 版本信息
  echo
  color_printf blue "Glibc 版本: "
  ldd --version | head -n 1 | awk '{print $NF}'
  ## cpu信息
  echo
  color_printf blue "CPU 信息: "
  print_cpu_info
  ## 内存信息
  echo
  color_printf blue "内存信息: "
  free -m
  ## 挂载信息
  echo
  color_printf blue "挂载信息: "
  grep </etc/fstab -E -v '^#|^$'
  ## 目录信息
  echo
  color_printf blue "目录信息: "
  df -h
}
#==============================================================#
#                         configure swap                       #
#==============================================================#
# 定义名为 conf_swap 的函数，用于配置交换空间
function conf_swap() {
  # 判断 /etc/fstab 文件中是否存在 /swapfile 文件这行，如果没有则添加
  if ! grep -q '/swapfile swap swap defaults 0 0' /etc/fstab; then
    log_print "配置 SWAP 交换空间"
    rm_file /swapfile
    # 创建指定大小的空文件 /swapfile，并将其格式化为交换分区
    dd if=/dev/zero of=/swapfile bs=1K count=$swap_count >/dev/null 2>&1
    # 设置文件权限为 0600
    chmod 600 /swapfile
    # 格式化文件为 Swap 分区
    mkswap /swapfile >/dev/null 2>&1
    # 启用 Swap 分区
    swapon /swapfile >/dev/null 2>&1
    # 将 Swap 分区信息添加到 /etc/fstab 文件中，以便系统重启后自动加载
    write_file "N" "/etc/fstab" "/swapfile swap swap defaults 0 0"
    free -m
  fi
}
#==============================================================#
#                           禁用防火墙                           #
#==============================================================#
function disable_firewall() {
  log_print "禁用防火墙"
  if ((os_version == 6)); then
    chkconfig iptables off && service iptables stop >/dev/null 2>&1
    service iptables status
  else
    systemctl stop firewalld.service && systemctl disable firewalld.service >/dev/null 2>&1
    systemctl status firewalld
  fi
}
#==============================================================#
#                         禁用 Selinux                          #
#==============================================================#
function disable_selinux() {
  log_print "禁用 SELinux"
  # 检查 SELinux 是否已经被禁用
  if [[ $(getenforce) != "Disabled" ]]; then
    # 临时关闭 SELinux
    setenforce 0
  fi
  # 更新配置文件中的 SELINUX 配置
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  # 记录更新后的 SELINUX 配置
  sestatus
}
#==============================================================#
#                       配置 nsysctl.conf                       #
#==============================================================#
function conf_nsysctl() {
  # 检查是否已经存在 NOZEROCONF=yes 的配置选项，如果不存在则添加之
  if ! grep -q "^NOZEROCONF=yes$" /etc/sysconfig/network; then
    log_print "配置 nsysctl.conf"
    # 备份原始配置文件
    backup_restore_file /etc/sysconfig/network
    # 追加 NOZEROCONF=yes 配置选项
    write_file "N" "/etc/sysconfig/network" "# OracleBegin
NOZEROCONF=yes"
    # 记录更改前后的差异到日志中
    grep -v "^\s*\(#\|$\)" /etc/sysconfig/network
  fi
}
#==============================================================#
#                         GUI Install                          #
#==============================================================#
function install_gui() {
  color_printf green "正在安装图形化界面："
  # 如果需要图形界面，则安装 GUI 软件包
  case "$os_version" in
  "6")
    install_package "nautilus-open-terminal" "tigervnc-server"
    yum groupinstall -y -q "X Window System" "Desktop" >/dev/null 2>&1
    ;;
  "7" | "8" | "9")
    install_package "tigervnc-server"
    yum groupinstall -y -q "Server with GUI" >/dev/null 2>&1
    ;;
  esac
}
#==============================================================#
#                         RPM Install                          #
#==============================================================#
# 安装软件包（如果未安装）
function install_package() {
  local yum_cmd
  if ((os_version <= 7)); then
    yum_cmd=yum
  else
    yum_cmd=dnf
  fi
  # 安装软件包
  for package in "$@"; do
    # 直接尝试安装软件包
    install_cmd="$yum_cmd install -y \"$package\""
    # 执行安装命令并检查是否成功
    if ! eval "$install_cmd" >/dev/null 2>&1; then
      if is_in_list "$package" "${must_packages[@]}"; then
        if [[ "$package" =~ ^libnsl[0-9]*$ ]]; then
          if [[ "$oracle_install_mode" =~ ^(rac|standalone)$ ]]; then
            color_printf red "Oracle Gird 安装需要依赖包 $package ，当前未成功安装，请检查。"
          fi
        fi
      fi
    fi
  done
}
#==============================================================#
#                          安装软件包                            #
#==============================================================#
function pkg_install() {
  log_print "安装依赖软件包"
  local option_packages must_packages
  if [[ $isgui == "Y" ]]; then
    install_gui
  fi
  # 定义可选软件包列表
  option_packages=(
    libaio-devel                 # 异步 I/O 库开发包
    e2fsprogs                    # EXT2/3/4 文件系统工具
    e2fsprogs-libs               # EXT2/3/4 文件系统库
    smartmontools                # 硬盘监控工具
    net-tools                    # 网络工具（如 ifconfig）
    nfs-utils                    # NFS 客户端和服务器工具
    elfutils-libelf              # 处理 ELF 文件的库
    elfutils-libelf-devel        # ELF 文件库的开发包
    libibverbs                   # RDMA (Remote Direct Memory Access) 库
    librdmacm                    # RDMA 通信管理库
    fontconfig                   # 字体配置工具
    fontconfig-devel             # 字体配置开发工具
    libXrender                   # X Rendering Extension 库
    libXrender-devel             # X Rendering Extension 开发包
    libX11                       # X11 库
    libXau                       # X11 认证库
    libXi                        # X Input Extension 库
    libXtst                      # X Testing 库
    libxcb                       # X11 协议 C 语言绑定库
    unixODBC                     # ODBC 数据库访问库
    sysstat                      # 性能监控工具
    readline                     # 提供行编辑功能的库
    readline-devel               # readline 库的开发包
    policycoreutils              # SELinux 工具
    libvirt-libs                 # 虚拟化库
    policycoreutils-python-utils # SELinux Python 工具
    libnsl2                      # 网络服务库 v2
    libasan                      # AddressSanitizer 库
    liblsan                      # LeakSanitizer 库
    compat-openssl10             # 兼容的 OpenSSL 1.0 库
    libxcrypt-compat             # 兼容的加密库
    compat-openssl11             # 兼容的 OpenSSL 1.1 库
    libgfortran                  # Fortran编译器的运行时库
    rlwrap                       # 提供 GNU readline 功能的包装器，增加行编辑和历史记录支持
  )
  # 定义必需软件包列表
  must_packages=(
    psmisc
    tar             # 解压工具
    glibc           # GNU C 库
    libaio          # 异步 I/O 库
    libgcc          # GCC 运行时库
    libstdc++       # C++ 标准库
    bc              # 任意精度计算器语言
    make            # 编译工具
    binutils        # 二进制工具
    glibc-devel     # GNU C 库开发包
    ksh             # KornShell (KSH) 解释器
    libstdc++-devel # C++ 标准库开发包
    unzip           # 解压工具
    gcc             # GNU 编译器集合
    gcc-c++         # GNU C++ 编译器
  )
  # 根据操作系统版本追加必需软件包
  case "${os_version}" in
  "6")
    must_packages+=(
      compat-libstdc++-33 # 兼容的 C++ 标准库
      compat-libcap1      # 兼容的 libcap1 库
    )
    ;;
  "7")
    must_packages+=(
      compat-libcap1 # 兼容的 libcap1 库
    )
    ;;
  "8" | "9" | "10")
    must_packages+=(
      libnsl # 网络服务库
      initscripts
    )
    ;;
  esac
  packages=("${must_packages[@]}" "${option_packages[@]}")
  local packages_display
  packages_display=$(printf '%s \\\n' "${packages[@]}" | sed '$s/\\$//')
  color_printf blue "$packages_display"
  log_print "静默安装软件包"
  install_package "${packages[@]}"
  color_printf blue "检查必需软件包安装情况："
  rpm -q "${must_packages[@]}"
}
#==============================================================#
#                           配置主机名                           #
#==============================================================#
function conf_hostname() {
  log_print "配置主机名"
  if ((os_version < 7)); then
    local hostname_file="/etc/sysconfig/network"
  else
    local hostname_file="/etc/hostname"
  fi
  # 检查新主机名是否已设置，并且不存在于相应的主机名文件中
  if ! grep -Fxq "$HOSTNAME" "$hostname_file"; then
    # 设置新主机名
    case "$os_version" in
    "6")
      hostname "$HOSTNAME"
      sysctl kernel.hostname="$HOSTNAME"
      write_file "Y" "/proc/sys/kernel/hostname" "$HOSTNAME"
      sed -i "s/^HOSTNAME=.*/HOSTNAME=$HOSTNAME/" "$hostname_file"
      # 记录日志
      hostname
      ;;
    *)
      hostnamectl set-hostname "$HOSTNAME"
      write_file "Y" "$hostname_file" "$HOSTNAME"
      # 记录日志
      hostnamectl
      ;;
    esac
  else
    cat "$hostname_file"
  fi
}
#==============================================================#
#                      配置 /etc/hosts 文件                     #
#==============================================================#
function conf_hosts() {
  log_print "配置 /etc/hosts 文件" >>"$oracleinstalllog"
  # 备份 /etc/hosts 文件
  backup_restore_file /etc/hosts
  # 配置 hosts 文件
  write_file "N" "/etc/hosts" "
# OracleBegin
# Public IP
$local_ip	$hostname"
  grep -v "^\s*\(#\|$\)" /etc/hosts >>"$oracleinstalllog" 2>&1 &
}
#==============================================================#
#                        创建用户和组                            #
#==============================================================#
function create_users_groups() {
  log_print "创建用户和组"
  # 定义标记空值标记
  local flag
  if [[ "$oracle_install_mode" == "standalone" ]]; then
    flag="true"
  fi
  # 定义os用户组
  local group_groups=("oinstall:54321" "dba:54322" "oper:54323" "backupdba:54324" "dgdba:54325" "kmdba:54326" "racdba:54330" ${flag:+"asmdba:54327"} ${flag:+"asmoper:54328"} ${flag:+"asmadmin:54329"})
  local user_groups=("$oracle_user" ${flag:+$grid_user})
  # 定义os用户密码数组
  declare -A passwd_groups=(
    [$oracle_user]=$oracle_passwd
    [$grid_user]=$grid_passwd
  )
  # 循环创建组
  for group in "${group_groups[@]}"; do
    local groupname=${group%%:*}
    local gid=${group##*:}
    # 如果不存在，则创建新组
    if ! grep -E -q "^$groupname:" /etc/group; then
      groupadd -g "$gid" "$groupname" >/dev/null 2>&1
    fi
  done
  for user in "${user_groups[@]}"; do
    local uid
    uid=$([[ $user == "$oracle_user" ]] && echo "54321" || echo "11012")
    local primary_group=oinstall
    local other_groups=dba,oper,backupdba,dgdba,kmdba,racdba${flag:+",asmdba"}${flag:+",asmoper"}${flag:+",asmadmin"}
    if ! id -u "$user" >/dev/null 2>&1; then
      useradd -u "$uid" -g $primary_group -G "$other_groups" -m "$user" >/dev/null 2>&1
    else
      usermod -g $primary_group -G "$other_groups" "$user" >/dev/null 2>&1
    fi
    # 为用户设置密码
    echo "$user:${passwd_groups[$user]}" | chpasswd >/dev/null 2>&1
    # 记录日志，输出创建的 grid 和 oracle 用户信息
    color_printf blue "$user 用户："
    id "$user"
    echo
  done
}
#==============================================================#
#                         创建安装目录                           #
#==============================================================#
function create_dir() {
  # 创建 Oracle 环境所需目录
  /bin/mkdir -p "$env_oracle_home" "$env_oracle_inven" "$backup_dir" "$oradata_dir"
  # 如果安装模式是 standalone
  if [[ "$oracle_install_mode" == "standalone" ]]; then
    cascade_del_file "$env_grid_home"
    # 创建额外的目录，并设置属性
    /bin/mkdir -p "$env_grid_base" "$env_grid_home"
    chown -R "$grid_user":oinstall {"$env_base_dir","$env_grid_home","$env_oracle_inven"}
    chown -R "$oracle_user":oinstall {"$backup_dir","$env_oracle_base"}
  else
    /bin/mkdir -p "$archive_dir"
    chown -R "$oracle_user":oinstall {"$oradata_dir","$backup_dir","$env_base_dir","$archive_dir"}
  fi
  chmod -R 775 "$env_base_dir"
}
#==============================================================#
#                        配置 avahi deamon                      #
#==============================================================#
# 安装并配置 Avahi 服务
function conf_avahi() {
  log_print "配置 Avahi-daemon 服务"
  case "$os_version" in
  "6")
    # 如果 avahi-daemon 已经启用，则停止并禁用它
    if (($(chkconfig --list | grep avahi-daemon | grep -c '3:on') > 0)); then
      service avahi-daemon stop
      chkconfig avahi-daemon off
    fi
    # 记录 avahi-daemon 状态
    service avahi-daemon status
    ;;
  *)
    # 停止 avahi-daemon 服务，并使用 "pgrep" 命令杀死任何残留进程
    if (($(systemctl status avahi-daemon | grep -c running) > 0)); then
      systemctl stop avahi-daemon.socket >/dev/null 2>&1
      systemctl stop avahi-daemon.service >/dev/null 2>&1
      kill_process "avahi-daemon"
      # 禁用 avahi-daemon 服务
      systemctl disable avahi-daemon.service >/dev/null 2>&1
      systemctl disable avahi-daemon.socket >/dev/null 2>&1
    fi
    # 记录 avahi-daemon 状态
    systemctl status avahi-daemon
    ;;
  esac
}
#==============================================================#
#               配置 THP && numa && ASM I/O scheduler           #
#==============================================================#
function conf_grub() {
  log_print "配置透明大页 && NUMA && 磁盘 IO 调度器"
  set_kernel_option() {
    local option="$1"
    if grubby --info=ALL | grep -q "$option"; then
      return 0
    fi
    grubby --update-kernel=ALL --args="$option"
  }
  local options=("numa=off" "transparent_hugepage=never" "elevator=deadline")
  for option in "${options[@]}"; do
    set_kernel_option "$option"
  done
  grubby --info=ALL | awk '/numa/{print $0 "\n-" $(NR-1) "\n-" $(NR-2)}'
}
#==============================================================#
#                        配置 sysctl.conf                       #
#==============================================================#
function conf_sysctl() {
  log_print "配置 sysctl.conf"
  # 获取系统页面大小，用于计算内存总量
  local pagesize min_free_kbytes shmall shmmax
  pagesize=$(getconf PAGE_SIZE)
  # min_free_kbytes = os_memory_total * 0.004
  ((min_free_kbytes = os_memory_total / 250))
  ((shmall = (os_memory_total - 1) * 1024 / pagesize))
  ((shmmax = os_memory_total * 1024 - 10))
  # 如果 shmall 小于 2097152，则将其设为 2097152
  ((shmall < 2097152)) && shmall=2097152
  # 如果 shmmax 小于 4294967295，则将其设为 4294967295
  ((shmmax < 4294967295)) && shmmax=4294967295
  # 备份 sysctl 配置文件
  backup_restore_file /etc/sysctl.conf
  # 使用 Here Document 来追加配置参数到 sysctl.conf 文件中
  write_file "Y" "/etc/sysctl.conf" "# OracleBegin
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = $shmall
kernel.shmmax = $shmmax
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
vm.min_free_kbytes=$min_free_kbytes
net.ipv4.conf.$local_ifname.rp_filter = 1
vm.swappiness = 10
kernel.panic_on_oops = 1
kernel.randomize_va_space = 2
vm.hugetlb_shm_group=54321"
  # 修复 centos6 部分版本没有这个参数
  if [[ $os_version != "6" ]]; then
    write_file "N" "/etc/sysctl.conf" "kernel.numa_balancing = 0"
  fi
  # 重新加载 sysctl 配置，并将结果输出到日志中
  color_printf blue "查看 sysctl.conf 配置情况 ：sysctl -p"
  sysctl -p
}
#==============================================================#
#                         配置 RemoveIPC                        #
#==============================================================#
function conf_ipc() {
  log_print "配置 RemoveIPC"
  # redhat6 版本无需配置
  # 检查是否需要设置 RemoveIPC=no。如果不需要设置则直接返回。
  # Failed Install of RAC with ASM: ORA-27300 ORA-27302 ORA-27300 ORA-27301 ORA-27302 (文档 ID 2099563.1)
  # ORA-27300 ORA-27301 ORA-27302 ORA-27157 Database Crash (文档 ID 438205.1)
  if grep -Fq "#RemoveIPC=yes" "$logind_file"; then
    sed -i 's/#RemoveIPC=yes/RemoveIPC=no/' "$logind_file"
  fi
  if grep -Fq "#RemoveIPC=no" "$logind_file"; then
    # 将 "#RemoveIPC=no" 行替换为 "RemoveIPC=no"
    sed -i 's/#RemoveIPC=no/RemoveIPC=no/' "$logind_file"
  fi
  # 重新加载 systemd 守护进程并重启 systemd-logind 服务
  systemctl daemon-reload >/dev/null 2>&1
  systemctl restart systemd-logind >/dev/null 2>&1
  # 检查是否已修改成功
  color_printf blue "查看 RemoveIPC ：$logind_file"
  grep "RemoveIPC" "$logind_file"
}
#==============================================================#
#                         配置 limits.conf                     #
#==============================================================#
function conf_limits() {
  log_print "配置 /etc/security/limits.conf 和 /etc/pam.d/login"
  # 备份 /etc/security/limits.conf 文件
  backup_restore_file /etc/security/limits.conf
  # 在 /etc/security/limits.conf 文件末尾添加 Oracle 的配置
  write_file "N" "/etc/security/limits.conf" "# OracleBegin
$oracle_user soft nofile 1024
$oracle_user hard nofile 65536
$oracle_user soft stack 10240
$oracle_user hard stack 32768
$oracle_user soft nproc 16384
$oracle_user hard nproc 16384
$oracle_user hard memlock unlimited
$oracle_user soft memlock unlimited"
  # 如果 Oracle 安装模式为 RAC，则添加额外的配置
  if [[ "$oracle_install_mode" == "standalone" ]]; then
    write_file "N" "/etc/security/limits.conf" "grid soft nofile 1024
$grid_user hard nofile 65536
$grid_user soft stack 10240
$grid_user hard stack 32768
$grid_user soft nproc 16384
$grid_user hard nproc 16384"
  fi
  # 记录 /etc/security/limits.conf 文件的输出到日志中
  color_printf blue "查看 /etc/security/limits.conf："
  grep -v "^\s*\(#\|$\)" /etc/security/limits.conf
  # 备份 /etc/pam.d/login 文件
  backup_restore_file /etc/pam.d/login
  # 在 /etc/pam.d/login 文件末尾添加 Oracle 的配置
  write_file "N" "/etc/pam.d/login" "# OracleBegin
session required pam_limits.so
# OracleEnd"
  # 记录 /etc/pam.d/login 文件的输出到日志中
  echo
  color_printf blue "查看 /etc/pam.d/login 文件："
  grep -v "^\s*\(#\|$\)" /etc/pam.d/login
}
#==============================================================#
#                         配置 /dev/shm                        #
#==============================================================#
function conf_shm() {
  log_print "配置 /dev/shm"
  local shm_total
  shm_total=$(df -k /dev/shm | awk 'NR==2 {print $2}')
  # 检查是否将 /dev/shm 添加到了 /etc/fstab 文件中
  if ! grep -qE "/dev/shm" /etc/fstab; then
    # 如果没有添加，则将其添加进去
    backup_restore_file /etc/fstab
    write_file "N" "/etc/fstab" "# OracleBegin
tmpfs /dev/shm tmpfs size=${os_memory_total}k 0 0"
  elif ((shm_total < os_memory_total)); then
    # 如果已经添加了 /dev/shm，检查共享内存总大小是否小于操作系统内存总量
    # 如果共享内存总大小小于操作系统内存总量，则将其设置为相同的值
    backup_restore_file /etc/fstab
    sed -i "/\/dev\/shm/d" /etc/fstab
    write_file "N" "/etc/fstab" "# OracleBegin
tmpfs /dev/shm tmpfs size=${os_memory_total}k 0 0"
  fi
  # 重新挂载 /dev/shm
  mount -o remount /dev/shm
  color_printf blue "查看 Linux 挂载情况：/etc/fstab"
  grep -v "^\s*\(#\|$\)" /etc/fstab
}
#==============================================================#
#                       安装 rlwrap 插件                        #
#==============================================================#
function install_rlwrap() {
  # 如果压缩包存在则开始安装 rlwrap
  log_print "安装 rlwrap 插件"
  # 创建并进入目录
  /bin/mkdir -p "$software_dir"/rlwrap && cd "$software_dir"/rlwrap || return 1
  # 解压缩文件
  tar -xf "$software_dir"/rlwrap-*.gz --strip-components 1 -C "$software_dir"/rlwrap
  # 配置、编译和安装软件，并将日志重定向到/dev/null以避免输出干扰
  (./configure -q && make -s && make install -s prefix=/usr/local libdir=/usr/local/libexec) >/dev/null 2>&1
  # 返回 /soft 目录
  cd ..
  # 删除不必要的文件夹和文件
  rm_file "$software_dir/rlwrap"
  # 检查 rlwrap 是否已成功安装
  if type rlwrap >/dev/null 2>&1; then
    # 如果已成功安装，则输出信息
    color_printf green "成功安装 rlwrap：" "$(rlwrap -v)"
  else
    # 如果未成功安装，则输出错误信息
    color_printf yellow "未能成功安装 rlwrap，请检查安装日志。"
  fi
}
#==============================================================#
#                         配置 profile                          #
#==============================================================#
function conf_profile() {
  local oracle_sids grid_sid
  log_print "Root 用户环境变量"
  # 配置 root 用户环境变量
  backup_restore_file /root/"$profile_name"
  write_file "N" "/root/$profile_name" "# OracleBegin
alias so='su - $oracle_user'
export PS1="[\`whoami\`@\`hostname\`:"'\$PWD]# '
alias bdf='df -Th'
alias syslog='vi /var/log/messages'"
  # 增加集群相关
  if [[ $oracle_install_mode == "standalone" ]]; then
    write_file "N" "/root/$profile_name" "alias sg='su - $grid_user'
alias crsctl='$env_grid_home/bin/crsctl'
alias srvctl='$env_grid_home/bin/srvctl'"
  fi
  color_printf blue "查看 root 用户环境变量：/root/$profile_name"
  grep -v "^\s*\(#\|$\)" /root/"$profile_name"
  # 获取 ASM 实例名称
  grid_sid=+ASM
  # 获取 DB 实例名
  for name in "${db_names[@]}"; do
    oracle_sids+=("$name" "$name")
  done
  adapt_oracle_support() {
    local profile_user=$1
    case "$os_version" in
    7)
      if [[ "$oracle_os_flag" == "N" ]]; then
        write_file "N" "/home/$profile_user/$profile_name" "export CV_ASSUME_DISTID=OL7"
      fi
      ;;
    8 | 9 | 10)
      if ((db_version >= 23)); then
        write_file "N" "/home/$profile_user/$profile_name" "export CV_ASSUME_DISTID=OL8"
      else
        write_file "N" "/home/$profile_user/$profile_name" "export CV_ASSUME_DISTID=OL7"
      fi
      ;;
    esac
  }
  for ((i = 0; i < ${#oracle_sids[@]}; i += 2)); do
    # 配置 oracle 用户环境变量
    log_print "$oracle_user 用户环境变量，实例名：${oracle_sids[i + 1]}"
    backup_restore_file /home/"$oracle_user"/"$profile_name"
    write_file "N" "/home/$oracle_user/$profile_name" "# OracleBegin
umask 022
export TMP=/tmp
export TMPDIR=\$TMP
export NLS_LANG=AMERICAN_AMERICA.$db_characterset
export ORACLE_BASE=$env_oracle_base
export ORACLE_HOME=$env_oracle_home
export ORACLE_TERM=xterm
export TNS_ADMIN=\$ORACLE_HOME/network/admin
export ORACLE_SID=${oracle_sids[i + 1]}
export PATH=/usr/sbin:\$PATH
export PATH=\$ORACLE_HOME/bin:\$ORACLE_HOME/OPatch:\$ORACLE_HOME/perl/bin:\$PATH
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export PERL5LIB=\$ORACLE_HOME/perl/lib
alias sas='sqlplus / as sysdba'
alias awr='sqlplus / as sysdba @?/rdbms/admin/awrrpt'
alias ash='sqlplus / as sysdba @?/rdbms/admin/ashrpt'
alias alert='vi \$ORACLE_BASE/diag/rdbms/*/\$ORACLE_SID/trace/alert_\$ORACLE_SID.log'
export PS1=\"[\`whoami\`@\`hostname\`:\"'\$PWD]\$ '
alias bdf='df -Th'
alias acd='cd \$ORACLE_BASE/diag/rdbms/*/\$ORACLE_SID/trace'
alias dblog='tail -200f \$ORACLE_BASE/diag/rdbms/*/\$ORACLE_SID/trace/alert_\$ORACLE_SID.log'"
    adapt_oracle_support "$oracle_user"
    # 检查 rlwrap 是否已经安装，并显示无误信息
    if type rlwrap >/dev/null 2>&1; then
      write_file "N" "/home/$oracle_user/$profile_name" "alias sqlplus='rlwrap sqlplus'
alias rman='rlwrap rman'
alias adrci='rlwrap adrci'"
    fi
    color_printf blue "查看 $oracle_user 用户环境变量：/home/$oracle_user/$profile_name"
    grep -v "^\s*\(#\|$\)" /home/"$oracle_user"/"$profile_name"
    # 创建一个与实例名同名的环境变量
    /bin/cp -f "/home/$oracle_user/$profile_name" "/home/$oracle_user/.${oracle_sids[i]}"
    chown -R "$oracle_user":oinstall "/home/$oracle_user/"
  done
  # grid
  if [[ $oracle_install_mode == "standalone" ]]; then
    log_print "$grid_user 用户环境变量"
    backup_restore_file /home/"$grid_user"/"$profile_name"
    write_file "N" "/home/$grid_user/$profile_name" "# OracleBegin
umask 022
export TMP=/tmp
export TMPDIR=\$TMP
export NLS_LANG=AMERICAN_AMERICA.$db_characterset
export ORACLE_BASE=$env_grid_base
export ORACLE_HOME=$env_grid_home
export ORACLE_TERM=xterm
export TNS_ADMIN=\$ORACLE_HOME/network/admin
export ORACLE_SID=$grid_sid
export PATH=/usr/sbin:\$PATH
export PATH=\$ORACLE_HOME/bin:\$ORACLE_HOME/OPatch:\$PATH
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
alias sas='sqlplus / as sysasm'
alias bdf='df -Th'
export PS1=\"[\`whoami\`@\`hostname\`:\"'\$PWD]\$ '"
    adapt_oracle_support "$grid_user"
    # 检查 rlwrap 是否已经安装，并显示无误信息
    if type rlwrap >/dev/null 2>&1; then
      write_file "N" "/home/$grid_user/$profile_name" "alias sqlplus='rlwrap sqlplus'
alias adrci='rlwrap adrci'"
    fi
    color_printf blue "查看 $grid_user 用户环境变量：/home/$grid_user/$profile_name"
    grep -v "^\s*\(#\|$\)" /home/"$grid_user"/"$profile_name"
    chown -R "$grid_user":oinstall "/home/$grid_user/"
  fi
}
#==============================================================#
#                    Configure Oracle ASM                      #
#==============================================================#
# 配置asm磁盘
function conf_asmdisk() {
  local uuid=$1 symlink=$2 udev_rule
  if [[ $multipath == "Y" ]]; then
    # 多路径udev绑盘
    udev_rule="KERNEL==\"dm-*\",ENV{DM_UUID}==\"$uuid\",SYMLINK+=\"$symlink\",OWNER=\"grid\",GROUP=\"asmadmin\",MODE=\"0660\""
  else
    # 没有多路径udev绑盘,版本不同，scsi_id 路径不同
    if ((os_version == 6)); then
      udev_rule="SUBSYSTEM==\"block\", PROGRAM==\"/sbin/scsi_id -g -u -d /dev/\$name\", RESULT==\"$uuid\", SYMLINK+=\"$symlink\", OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"0660\""
    else
      udev_rule="SUBSYSTEM==\"block\", PROGRAM==\"/usr/lib/udev/scsi_id -g -u -d /dev/\$name\", RESULT==\"$uuid\", SYMLINK+=\"$symlink\", OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"0660\""
    fi
  fi
  # 写入udev规则文件
  write_file "N" "/etc/udev/rules.d/99-oracle-asmdevices.rules" "$udev_rule"
}
#==============================================================#
#                         配置 asm disk                         #
#==============================================================#
function conf_asm() {
  # 如果 udev 规则文件存在则删除
  rm_file /etc/udev/rules.d/99-oracle-asmdevices.rules
  # 配置多路径
  if [[ $multipath == "Y" ]]; then
    if [[ "$os_type" =~ ^(ubuntu|debian|Deepin|arch)$ ]]; then
      install_package "multipath-tools" "multipath-tools-boot"
    elif [[ "$os_type" == "openEuler" ]]; then
      install_package "multipath-tools"
    else
      install_package "device-mapper-multipath"
    fi
    log_print "配置 multipath 多路径和 UDEV 绑盘" >>"$oracleinstalllog"
    # 启用多路径
    mpathconf --enable --with_multipathd y >/dev/null 2>&1
    # 配置多路径开机自启和获取根目录磁盘
    case "$os_version" in
    "6")
      chkconfig multipathd.service on >/dev/null 2>&1
      ;;
    *)
      systemctl enable multipathd.service >/dev/null 2>&1
      ;;
    esac
    backup_restore_file /etc/multipath.conf
    # 配置 multipath.conf
    write_file "Y" "/etc/multipath.conf" "# OracleBegin
defaults {
  user_friendly_names yes
}

blacklist {
  devnode \"^(ram|raw|loop|fd|md|dm-|sr|scd|st)[0-9]*\"
  devnode \"^asm/*\"
  devnode \"ofsctl\"
}

multipaths {"
  fi
  # 将磁盘 WWID 和磁盘组名称存放在关联数组变量中
  declare -A DISK_INFOS=(
    ["data"]="$data_disk_wwid"
    ["arch"]="$arch_disk_wwid"
  )
  # 循环ASM磁盘信息数组
  for NAME in "${!DISK_INFOS[@]}"; do
    # 获取当前磁盘组中的磁盘 WWID 列表
    local WWID_LIST=${DISK_INFOS[$NAME]}
    # 定义一个间接变量用于存放asm磁盘路径，用逗号拼接
    local asm_disks="${NAME}disk"
    # 当前磁盘组存在 WWID 时解析
    if [[ -n $WWID_LIST ]]; then
      # 将逗号分隔的 WWID 转换成 WWID 数组
      IFS=',' read -ra WWIDS <<<"$WWID_LIST"
      # 遍历 WWID 数组，为每个 WWID 添加别名
      for ((i = 0; i < ${#WWIDS[@]}; i++)); do
        # 获取当前循环的 WWID 值
        local WID="${WWIDS[i]}"
        # 根据当前索引计算出别名编号
        local NUM
        ((NUM = i + 1))
        local ALIAS=asm_${NAME}_$NUM
        local WWID=$WID
        # 需要配置多路径时，写入多路径配置文件
        if [[ $multipath == "Y" ]]; then
          # 构造磁盘管理器使用的 WWID 和别名
          WWID=mpath-$WID
          # 将当前磁盘的 WWID 和别名写入 multipath.conf
          write_file "N" "/etc/multipath.conf" "multipath {
wwid $WID
alias $ALIAS
}"
        fi
        local ALIAS_STR=/dev/$ALIAS
        # 针对 udev 的规则配置 ASM 磁盘
        conf_asmdisk "$WWID" "$ALIAS"
        # 拼接 asm 磁盘组磁盘路径
        eval "${asm_disks}=\"\${${asm_disks}}${ALIAS_STR},\""
      done
    fi
    # 去掉最后一个逗号
    eval "${asm_disks}=\${${asm_disks}%?}"
  done
  if [[ $multipath == "Y" ]]; then
    write_file "N" "/etc/multipath.conf" "}"
    # 解决 VirtualBox 的一个 bug
    if [[ $virtualbox =~ ^[yY] ]]; then
      sed -i 's/1ATA_//' /etc/multipath.conf
      sed -i 's/1ATA_//' /etc/udev/rules.d/99-oracle-asmdevices.rules
    fi
    # 启用及查看多路径服务状态
    case "$os_version" in
    "6")
      service multipathd restart >/dev/null 2>&1
      ;;
    *)
      systemctl restart multipathd >/dev/null 2>&1
      ;;
    esac
    color_printf blue "检查 Mulltipath 多路径情况：" >>"$oracleinstalllog"
    while true; do
      if multipath -ll >>"$oracleinstalllog" 2>&1; then
        break
      fi
      # 睡眠 5s，防止 multipath 服务重启慢问题
      sleep 5s
    done
  fi
  # 打印 UDEV 配置信息
  {
    echo
    color_printf blue "UDEV 配置信息："
    cat /etc/udev/rules.d/99-oracle-asmdevices.rules
    echo
  } >>"$oracleinstalllog"
  # 启动 UDEV
  while true; do
    if ((os_version == 6)); then
      # 在 CentOS 6 上启动 UDEV 服务
      start_udev >/dev/null 2>&1
    else
      # 在 CentOS 7/8/9 上启动 UDEV 服务
      # 重新加载 udev 规则
      udevadm control --reload-rules >/dev/null 2>&1
      # 触发设备变化事件
      udevadm trigger --type=devices --action=change >/dev/null 2>&1
    fi
    # 睡眠 5s，防止 udev 加载慢问题
    sleep 5s
    if [[ $(find /dev -name "asm*" 2>/dev/null) ]]; then
      {
        color_printf blue "检查 UDEV 绑定磁盘情况："
        ls -lcm /dev/asm_*
        echo
        color_printf blue "UDEV 配置完成！"
      } >>"$oracleinstalllog"
      break
    fi
  done
}
#==============================================================#
#                        解压 Grid 软件包                        #
#==============================================================#
function unzip_gridsoft() {
  # 执行日志输出函数
  log_print "静默解压缩 Grid 软件包"
  # 修改软件目录的所有者和所属组为GRID
  chown -R "$grid_user":oinstall "$software_dir"
  color_printf blue "正在静默解压缩 Grid 软件包，请稍等："
  # 解压缩 Grid 安装包
  if ((gi_version == 11)); then
    # 如果 Grid 软件目录不存在，则解压缩 Grid 安装包到指定目录中
    if ! check_file "$software_dir"/grid; then
      cascade_del_file "$software_dir/grid"
    fi
    color_printf green "静默解压 Grid 软件安装包： $grid_soft_name"
    run_as_grid "unzip -oq \"$grid_soft_name\" -d \"$software_dir\""
  else
    echo
    color_printf green "静默解压 Grid 软件安装包： $grid_soft_name"
    run_as_grid "unzip -oq \"$grid_soft_name\" -d \"$env_grid_home\""
  fi
  # 安装 cvuqdisk
  if ! type cvuqdisk >/dev/null 2>&1; then
    # 安装 cvuqdisk，并将安装文件拷贝到其他节点指定的目录下，然后在其他节点上执行安装
    if check_file "$cvuqdisk"; then
      echo
      color_printf green "静默安装 cvu 软件：$cvu_name"
      echo
      rpm -Uvh --quiet "$cvuqdisk" >/dev/null 2>&1
    fi
  fi
}
#==============================================================#
#                       配置 grid 静默文件                       #
#==============================================================#
function conf_gridrsp() {
  log_print "Grid 安装静默文件"
  gridrsp_array=(
    "INVENTORY_LOCATION=$env_oracle_inven"
    "oracle.install.option=HA_CONFIG"
    "ORACLE_BASE=$env_grid_base"
    "oracle.install.asm.OSDBA=asmdba"
    "oracle.install.asm.OSOPER=asmoper"
    "oracle.install.asm.OSASM=asmadmin"
    "oracle.install.crs.config.gpnp.configureGNS=false"
    "oracle.install.crs.config.useIPMI=false"
    "oracle.install.asm.SYSASMPassword=$database_passwd"
    "oracle.install.asm.diskGroup.name=$data_asm_group"
    "oracle.install.asm.diskGroup.redundancy=$data_redun"
    "oracle.install.asm.diskGroup.disks=$datadisk"
    "oracle.install.asm.diskGroup.diskDiscoveryString=$asmdisk_string"
    "oracle.install.asm.monitorPassword=$database_passwd"
  )
  # 根据不同的版本向grid.rsp文件追加配置
  case "$gi_version" in
  "11")
    gridrsp_array+=(
      "oracle.install.responseFileVersion=/oracle/install/rspfmt_crsinstall_response_schema_v11_2_0"
      "SELECTED_LANGUAGES=en"
      "ORACLE_HOME=$env_grid_home"
      "oracle.install.crs.config.storageOption=ASM_STORAGE"
      "oracle.install.asm.diskGroup.AUSize=$ausize"
      "oracle.installer.autoupdates.option=SKIP_UPDATES"
    )
    ;;
  "12" | "19" | "21" | "23")
    gridrsp_array+=(
      "oracle.install.crs.config.ClusterConfiguration=STANDALONE"
      "oracle.install.crs.config.configureAsExtendedCluster=false"
      "oracle.install.asm.storageOption=ASM"
      "oracle.install.asm.diskGroup.AUSize=$ausize"
      "oracle.install.asm.configureAFD=$afd"
      "oracle.install.crs.config.ignoreDownNodes=false"
      "oracle.install.config.managementOption=NONE"
      "oracle.install.crs.rootconfig.executeRootScript=false"
    )
    case "$gi_version" in
    "12")
      gridrsp_array+=("oracle.install.responseFileVersion=/oracle/install/rspfmt_crsinstall_response_schema_v12.2.0")
      ;;
    "19")
      gridrsp_array+=(
        "oracle.install.responseFileVersion=/oracle/install/rspfmt_crsinstall_response_schema_v19.0.0"
        "oracle.install.crs.config.scanType=LOCAL_SCAN"
        "oracle.install.crs.configureGIMR=false"
      )
      ;;
    "21")
      gridrsp_array+=(
        "oracle.install.responseFileVersion=/oracle/install/rspfmt_crsinstall_response_schema_v21.0.0"
        "oracle.install.crs.config.scanType=LOCAL_SCAN"
        "oracle.install.crs.configureGIMR=false"
      )
      ;;
    "23")
      gridrsp_array+=(
        "oracle.install.responseFileVersion=/oracle/install/rspfmt_crsinstall_response_schema_v23.0.0"
        "oracle.install.crs.config.scanType=LOCAL_SCAN"
        "oracle.install.crs.configureGIMR=false"
      )
      ;;
    esac
    ;;
  esac
  rm_file "$software_dir/grid.rsp"
  printf '%s\n' "${gridrsp_array[@]}" >>"$software_dir"/grid.rsp
  # 记录grid.rsp文件内容到日志中
  cat "$software_dir"/grid.rsp
}
#==============================================================#
#                      获取安装 grid 命令                        #
#==============================================================#
function get_gridinstall_cmd() {
  log_print "静默安装 Grid 软件命令"
  case "$gi_version" in
  "11")
    gridinstall_cmd=$(echo -e "$software_dir/grid/runInstaller \\
-silent \\
-showProgress \\
-ignoreSysPrereqs \\
-ignorePrereq \\
-waitForCompletion \\
-responseFile $software_dir/grid.rsp")
    ;;
  "12" | "19" | "21" | "23")
    if ((gi_version == 12)); then
      # [INS-42505] The installer has detected that the Oracle Grid Infrastructure home software at (/oracle/GRID/12201) is not complete. (Doc ID 2697235.1)
      if ! check_file "$env_grid_home"/install/files.lst.original; then
        /bin/mv -f "$env_grid_home"/install/files.lst "$env_grid_home"/install/files.lst.original
      fi
    fi
    gridinstall_cmd=$(echo -e "$env_grid_home/gridSetup.sh \\
-silent \\
-skipPrereqs \\
-ignorePrereqFailure \\
-waitForCompletion \\
-responseFile $software_dir/grid.rsp")
    ;;
  esac
  color_printf blue "$gridinstall_cmd"
}
#==============================================================#
#                         安装 Grid 软件                        #
#==============================================================#
function install_gridsoft() {
  # 配置 grid 静默安装文件
  conf_gridrsp
  # 获取安装 grid 命令
  get_gridinstall_cmd
  # 修改软件目录的所有者和所属组为 grid
  chown -R "$grid_user":oinstall "$software_dir"
  # 打印日志
  log_print "静默安装 Grid 软件"
  color_printf blue "正在安装 Grid 软件："
  # 安装 Grid 软件
  run_as_grid "$gridinstall_cmd"
  # Grid 软件安装后步骤
  after_grid_install "$@"
  # 打印日志
  log_print "Grid 软件版本"
  color_printf blue "查看 Grid 软件版本：sqlplus -V"
  run_as_grid "sqlplus -V"
  log_print "Grid 资源检查"
  color_printf blue "查看 Grid 集群情况：crsctl stat res -t"
  run_as_grid "crsctl stat res -t"
}
#==============================================================#
#                      执行 root.sh 脚本                        #
#==============================================================#
# 执行 root.sh 脚本
function exec_root() {
  local root_path=$1
  log_print "执行 root 脚本"
  # 执行 orainstRoot.sh 脚本，不论 grid/oracle 软件安装都执行
  if check_file "$env_oracle_inven"/orainstRoot.sh; then
    color_printf blue "执行命令：$env_oracle_inven/orainstRoot.sh"
    "$env_oracle_inven"/orainstRoot.sh
  fi
  if check_file "$root_path"/root.sh; then
    echo
    color_printf blue "执行命令：$root_path/root.sh"
    "$root_path"/root.sh
  fi
}
#==============================================================#
#                      安装 Grid 软件后操作                      #
#==============================================================#
function after_grid_install() {
  case "$gi_version" in
  "11")
    # Grid patch 18370031 补丁安装，无需 OPatch 补丁，修复执行 root.sh 脚本报错 ohas 服务问题
    if ((os_version >= 7)); then
      log_print "静默安装 18370031 补丁"
      run_as_grid "unzip -oq $software_dir/p18370031_112040_Linux-x86-64.zip -d $software_dir"
      run_as_grid "$env_grid_home/OPatch/opatch napply -oh $env_grid_home -local $software_dir/18370031 -silent"
    fi
    # 执行 root 脚本
    exec_root "$env_grid_home"
    # 执行 configToolAllCommands 完成 Grid 基础配置
    if ! check_file "$env_grid_home"/cfgtoollogs/configToolAllCommands; then
      run_as_grid "$env_grid_home/oui/bin/runConfig.sh ORACLE_HOME=$env_grid_home MODE=perform ACTION=configure RERUN=true $*" >/dev/null 2>&1
    fi
    # 添加 asm 账户密码信息到 cfgrsp.properties 文件中
    write_file "N" "/home/$grid_user/cfgrsp.properties" "oracle.assistants.asm|S_ASMPASSWORD=$database_passwd
oracle.assistants.asm|S_ASMMONITORPASSWORD=$database_passwd"
    run_as_grid "$env_grid_home/cfgtoollogs/configToolAllCommands RESPONSE_FILE=/home/$grid_user/cfgrsp.properties" >/dev/null 2>&1
    rm_file /home/"$grid_user"/cfgrsp.properties
    ;;
  "12" | "19" | "21" | "23")
    # 恢复 files.lst
    if ((gi_version == 12)); then
      if check_file "$env_grid_home"/install/files.lst.original; then
        /bin/mv -f "$env_grid_home"/install/files.lst.original "$env_grid_home"/install/files.lst
      fi
      make -s -f "$env_grid_home"/rdbms/lib/ins_rdbms.mk client_sharedlib libasmclntsh12.ohso libasmperl12.ohso ORACLE_HOME="$env_grid_home" >/dev/null 2>&1
    fi
    # 执行 root 脚本
    exec_root "$env_grid_home"
    run_as_grid "$env_grid_home/gridSetup.sh -executeConfigTools -responseFile $software_dir/grid.rsp -silent" >/dev/null 2>&1
    ;;
  esac
}
#==============================================================#
#                     获取创建 ASM 磁盘组命令                     #
#==============================================================#
# 创建ASM磁盘组
function get_asmca_cmd() {
  # 打印日志
  log_print "静默创建 ASM 磁盘组命令"
  # 操作Grid用户创建数据磁盘组
  data_asmca_cmd=$(echo -e "$env_grid_home/bin/asmca -silent \\
-createDiskGroup \\
-diskGroupName $data_asm_group \\
-diskList $datadisk \\
-redundancy $data_redun \\
-au_size $ausize \\
-compatible.asm $gi_compatible \\
-compatible.rdbms $db_compatible")
  color_printf blue "$data_asmca_cmd"
  # 判断归档磁盘是否存在，并操作Grid用户创建归档磁盘组
  if [[ -n "$arch_base_disk" ]]; then
    arch_asmca_cmd=$(echo -e "$env_grid_home/bin/asmca -silent \\
-createDiskGroup \\
-diskGroupName $arch_asm_group \\
-diskList $archdisk \\
-au_size $ausize \\
-redundancy $arch_redun \\
-compatible.asm $gi_compatible \\
-compatible.rdbms $db_compatible")
    color_printf blue "$arch_asmca_cmd"
  fi
}
#==============================================================#
#                       创建 ASM 磁盘组                          #
#==============================================================#
# 创建ASM磁盘组
function create_asmgroup() {
  # 获取创建 ASM 磁盘组命令
  get_asmca_cmd
  # 打印日志
  log_print "ASM 磁盘组创建"
  color_printf blue "正在创建 ASM 磁盘组："
  # 操作Grid用户创建数据磁盘组
  run_as_grid "$data_asmca_cmd"
  # 判断归档磁盘是否存在，并操作Grid用户创建归档磁盘组
  if [[ -n "$arch_asmca_cmd" ]]; then
    run_as_grid "$arch_asmca_cmd"
  fi
  color_printf blue "查看 ASM 磁盘组：asmcmd lsdg"
  run_as_grid "asmcmd lsdg"
}
#==============================================================#
#                        解压 Oracle 软件                       #
#==============================================================#
function unzip_dbsoft() {
  # 执行日志输出函数
  log_print "静默解压 Oracle 软件包"
  # 修改软件目录的所有者和所属组为Oracle
  chown -R "$oracle_user":oinstall "$software_dir"
  color_printf blue "正在静默解压缩 Oracle 软件包，请稍等："
  # 安装Oracle数据库软件
  case "$db_version" in
  "11" | "12")
    # 只有当数据库所需文件夹不存在时，才会解压文件到指定目录下
    if check_file "$software_dir"/database; then
      cascade_del_file "$software_dir/database"
    fi
    # 解压第一个文件到指定的目录下，-o选项可以覆盖原有文件，-q选项可以减少输出信息
    if [[ "$db_soft_name1" ]]; then
      color_printf green "静默解压 Oracle 软件安装包： $db_soft_name,$db_soft_name1"
      run_as_oracle "unzip -oq $db_soft_name -d $software_dir && unzip -oq $db_soft_name1 -d $software_dir"
    else
      color_printf green "静默解压 Oracle 软件安装包： $db_soft_name"
      run_as_oracle "unzip -oq $db_soft_name -d $software_dir"
    fi
    ;;
  *)
    echo
    color_printf green "静默解压 Oracle 软件安装包： $db_soft_name"
    run_as_oracle "unzip -oq $db_soft_name -d $env_oracle_home"
    ;;
  esac
}
#==============================================================#
#                    创建 Oracle 静默安装文件                     #
#==============================================================#
function conf_oraclersp() {
  log_print "Oracle 安装静默文件"
  # 将Oracle软件安装相关配置写入oracle.rsp文件
  declare -a oracle_rsp_arr=(
    "oracle.install.option=INSTALL_DB_SWONLY"
    "UNIX_GROUP_NAME=oinstall"
    "INVENTORY_LOCATION=$env_oracle_inven"
    "ORACLE_BASE=$env_oracle_base"
    "oracle.install.db.InstallEdition=EE"
  )
  # 根据不同的版本向oracle.rsp文件追加配置
  case "$db_version" in
  "11")
    oracle_rsp_arr+=(
      "oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v11_2_0"
      "SELECTED_LANGUAGES=en,zh_CN"
      "ORACLE_HOME=$env_oracle_home"
      "oracle.install.db.DBA_GROUP=dba"
      "oracle.install.db.OPER_GROUP=oper"
      "DECLINE_SECURITY_UPDATES=true"
      "oracle.installer.autoupdates.option=SKIP_UPDATES"
    )
    ;;
  "12")
    oracle_rsp_arr+=(
      "oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v12.2.0"
      "SELECTED_LANGUAGES=en,zh_CN"
      "ORACLE_HOME=$env_oracle_home"
      "oracle.install.db.OSDBA_GROUP=dba"
      "oracle.install.db.OSOPER_GROUP=oper"
      "oracle.install.db.OSBACKUPDBA_GROUP=backupdba"
      "oracle.install.db.OSDGDBA_GROUP=dgdba"
      "oracle.install.db.OSKMDBA_GROUP=kmdba"
      "oracle.install.db.OSRACDBA_GROUP=racdba"
    )
    ;;
  "19" | "21" | "23")
    oracle_rsp_arr+=(
      "oracle.install.db.OSDBA_GROUP=dba"
      "oracle.install.db.OSOPER_GROUP=oper"
      "oracle.install.db.OSBACKUPDBA_GROUP=backupdba"
      "oracle.install.db.OSDGDBA_GROUP=dgdba"
      "oracle.install.db.OSKMDBA_GROUP=kmdba"
      "oracle.install.db.OSRACDBA_GROUP=racdba"
      "oracle.install.db.rootconfig.executeRootScript=false"
      "oracle.install.db.rootconfig.configMethod="
    )
    case "$db_version" in
    "19")
      oracle_rsp_arr+=("oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v19.0.0")
      ;;
    "21")
      oracle_rsp_arr+=("oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v21.0.0")
      ;;
    "23")
      oracle_rsp_arr+=("oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v23.0.0")
      ;;
    esac
    ;;
  esac
  rm_file "$software_dir/oracle.rsp"
  printf '%s\n' "${oracle_rsp_arr[@]}" >"$software_dir/oracle.rsp"
  # 记录 oracle.rsp 文件内容到日志中
  cat "$software_dir/oracle.rsp"
}
#==============================================================#
#                      获取安装 Oracle 命令                      #
#==============================================================#
function get_oracleinstall_cmd() {
  log_print "静默安装 Oracle 软件命令"
  case "$db_version" in
  "11" | "12")
    # 获取安装命令
    oracleinstall_cmd=$(echo -e "$software_dir/database/runInstaller \\
-silent \\
-responseFile $software_dir/oracle.rsp \\
-showProgress \\
-ignoreSysPrereqs \\
-ignorePrereq \\
-waitForCompletion")
    ;;
  "19" | "21" | "23")
    oracleinstall_cmd=$(echo -e "$env_oracle_home/runInstaller \\
-silent \\
-ignorePrereqFailure \\
-responseFile $software_dir/oracle.rsp \\
-waitForCompletion")
    ;;
  esac
  color_printf blue "$oracleinstall_cmd"
}
#==============================================================#
#                       安装 Oracle 软件                         #
#==============================================================#
function install_dbsoft() {
  # 配置 Oracle 静默安装文件
  conf_oraclersp
  # 获取安装 Oracle 命令
  get_oracleinstall_cmd
  # 修改软件目录的所有者和所属组为Oracle
  chown -R "$oracle_user":oinstall "$software_dir"
  # 打印日志
  log_print "静默安装数据库软件"
  color_printf blue "正在安装 Oracle 软件："
  # 安装数据库软件
  run_as_oracle "$oracleinstall_cmd"
  # 安装 Oracle 软件后操作
  after_oracle_install
  # 打印日志
  log_print "Oracle 软件版本"
  run_as_oracle "sqlplus -V"
}
#==============================================================#
#                     安装 Oracle 软件后操作                     #
#==============================================================#
function after_oracle_install() {
  case "$db_version" in
  "11" | "12")
    if ((db_version == 11 && gi_version > 11)); then
      # 如果 GI 和 DB 版本不一致，[INS-35354] The system on which you are attempting to install Oracle RAC is not part of a valid cluster
      run_as_grid "$env_grid_home/oui/bin/runInstaller -updateNodeList ORACLE_HOME=$env_grid_home CRS=true" >/dev/null 2>&1
    fi
    # 执行 root 脚本
    exec_root "$env_oracle_home"
    # 在 Linux6 上安装 12c 需要设置 irman、ioracle
    if ((db_version == 12 && os_version == 6)); then
      run_as_oracle "make -s -f $env_oracle_home/rdbms/lib/ins_rdbms.mk irman" >/dev/null 2>&1
      run_as_oracle "make -s -f $env_oracle_home/rdbms/lib/ins_rdbms.mk ioracle" >/dev/null 2>&1
    fi
    # 安装 11GR2 需要修改 -lnnz11
    if ((db_version == 11)); then
      if ((os_version >= 7)); then
        sed -i "s/^\(\s*\$(MK_EMAGENT_NMECTL)\)\s*$/\1 -lnnz11/g" "$env_oracle_home"/sysman/lib/ins_emagent.mk
      fi
    fi
    ;;
  # 在 19C、21C 上应用 RU
  "19" | "21" | "23")
    # 执行 root 脚本
    exec_root "$env_oracle_home"
    ;;
  esac
}
#==============================================================#
#                           配置监听                            #
#==============================================================#
# 配置监听
function conf_netca() {
  # 检查Oracle安装模式是否为单实例，以及 listener.ora 文件是否存在
  if [[ "$oracle_install_mode" == "single" ]] && ! check_file "$env_oracle_home"/network/admin/listener.ora; then
    # 如果 netca.rsp 文件存在则执行 netca 配置命令
    if check_file "$env_oracle_home"/assistants/netca/netca.rsp; then
      log_print "静默安装 Oracle 软件命令"
      local netca_cmd
      netca_cmd=$(echo -e "$env_oracle_home/bin/netca -silent \\
-responsefile $env_oracle_home/assistants/netca/netca.rsp")
      color_printf blue "$netca_cmd"
      log_print "创建监听"
      color_printf blue "正在创建监听："
      run_as_oracle "$netca_cmd"
    fi
  fi
  # 输出检查监听状态的提示信息
  echo
  log_print "检查监听状态"
  # 使用oracle用户执行lsnrctl stat命令来检查监听状态
  run_as_oracle "lsnrctl stat"
}
#==============================================================#
#                        配置建库响应文件                         #
#==============================================================#
function get_dbca_rsp() {
  local dbname=$1 nums=$2 redo_size templatename db_block_size_11g
  # 计算数据库内存总和(MB) = 物理内存的 80%
  ((db_memory_total = os_memory_total * 4 / 5 / 1024 / nums))
  if ((db_block_size == 8192)); then
    templatename=General_Purpose.dbc
  else
    templatename=New_Database.dbt
  fi
  log_print "DBCA 静默建库文件：$dbname"
  if ((db_version == 11)); then
    db_block_size_11g=$((db_block_size / 1024))
    declare -a db_rsp_arr=(
      "[GENERAL]"
      "RESPONSEFILE_VERSION=11.2.0"
      "OPERATION_TYPE=createDatabase"
      "[CREATEDATABASE]"
      "GDBNAME=$dbname"
      "SID=$dbname"
      "TEMPLATENAME=$templatename"
      "SYSPASSWORD=$database_passwd"
      "SYSTEMPASSWORD=$database_passwd"
      "CHARACTERSET=$db_characterset"
      "NATIONALCHARACTERSET=$nation_characterset"
      "INITPARAMS=db_block_size=$db_block_size_11g"
      "TOTALMEMORY=$db_memory_total"
      "AUTOMATICMEMORYMANAGEMENT=FALSE"
    )
    # 根据安装模式设置特定参数
    case "$oracle_install_mode" in
    "standalone")
      db_rsp_arr+=(
        "STORAGETYPE=ASM"
        "DISKGROUPNAME=$data_asm_group"
        "RECOVERYGROUPNAME=$data_asm_group"
      )
      ;;
    *)
      db_rsp_arr+=(
        "DATAFILEDESTINATION=$oradata_dir"
        "RECOVERYAREADESTINATION=$oradata_dir"
        "storageType=FS"
      )
      ;;
    esac
    redoline="<fileSize unit=\"KB\">51200</fileSize>"
  else
    declare -a db_rsp_arr=(
      "gdbName=$dbname"
      "sid=$dbname"
      "templateName=$templatename"
      "sysPassword=$database_passwd"
      "systemPassword=$database_passwd"
      "characterSet=$db_characterset"
      "nationalCharacterSet=$nation_characterset"
      "automaticMemoryManagement=false"
      "totalMemory=$db_memory_total"
      "initParams=db_block_size=${db_block_size}BYTES"
      "createAsContainerDatabase=$iscdb"
    )
    # 根据安装模式设置特定参数
    case "$oracle_install_mode" in
    "standalone")
      db_rsp_arr+=(
        "databaseConfigType=SI"
        "storageType=ASM"
        "diskGroupName=$data_asm_group"
        "recoveryGroupName=$data_asm_group"
      )
      ;;
    *)
      db_rsp_arr+=(
        "databaseConfigType=SI"
        "storageType=FS"
        "datafileDestination=$oradata_dir"
        "recoveryAreaDestination=$oradata_dir"
      )
      ;;
    esac
    case "$db_version" in
    "12")
      db_rsp_arr+=("responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v12.2.0")
      ;;
    "19")
      db_rsp_arr+=("responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v19.0.0")
      ;;
    "21")
      db_rsp_arr+=("responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v21.0.0")
      ;;
    "23")
      db_rsp_arr+=("responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v23.0.0")
      ;;
    esac
    redoline="<fileSize unit=\"KB\">204800</fileSize>"
  fi
  # 使用归档日志模式
  if [[ $enable_arch == "true" ]]; then
    sed -i "s|<archiveLogMode>false</archiveLogMode>|<archiveLogMode>true</archiveLogMode>|g" "$env_oracle_home/assistants/dbca/templates/$templatename"
  fi
  # 修改 redo 文件大小
  redo_size=$((redosize * 1024))
  sed -i "s|$redoline|<fileSize unit=\"KB\">${redo_size}</fileSize>|g" "$env_oracle_home/assistants/dbca/templates/$templatename"
  # 处理 12.2 Oracle Restart 问题
  if ((db_version == 12)); then
    check_file "$env_oracle_home/log/$dbname" || /bin/mkdir -p "$env_oracle_home/log/$dbname"
    chown -R "$oracle_user":oinstall "$env_oracle_home/log/$dbname"
  fi
  rm_file "$software_dir/db.rsp"
  printf '%s\n' "${db_rsp_arr[@]}" >"$software_dir/db.rsp"
  # 记录 db.rsp 文件内容到日志中
  cat "$software_dir/db.rsp"
}
#==============================================================#
#                       获取 DB 创建命令                         #
#==============================================================#
function get_dbca_cmd() {
  log_print "静默创建数据库命令"
  # 获取安装命令
  if ((db_version == 11)); then
    dbca_cmd="$env_oracle_home/bin/dbca -silent -responseFile $software_dir/db.rsp"
  else
    dbca_cmd="$env_oracle_home/bin/dbca -silent -createDatabase \\
-responseFile $software_dir/db.rsp \\
-ignorePreReqs \\
-ignorePrereqFailure"
    if [[ "$db_version" =~ ^(19|21|23)$ ]]; then
      dbca_cmd="$dbca_cmd \\
-J-Doracle.assistants.dbca.validate.ConfigurationParams=false"
      if ((db_version == 23)); then
        dbca_cmd="$dbca_cmd \\
-initParams _exadata_feature_on=true"
      fi
    fi
  fi
  color_printf blue "$dbca_cmd"
}
#==============================================================#
#                           创建数据库                           #
#==============================================================#
# 创建数据库
function create_db() {
  # 获取建库命令并打印
  for name in "${db_names[@]}"; do
    get_dbca_rsp "$name" ${#db_names[@]}
    get_dbca_cmd
    # 修改软件目录的所有者和所属组为 grid
    chown -R "$oracle_user":oinstall "$software_dir"
    # 打印日志到终端和文件
    log_print "创建数据库实例：$name"
    color_printf blue "正在创建数据库：$name"
    run_as_oracle "$dbca_cmd"
    # 配置 Oracle Managed Files（OMF）
    conf_omf "$name"
    # 创建 PDB
    if [[ $iscdb == "true" ]]; then
      create_pdb "$name"
    fi
  done
  # 配置 sqlnet.ora 文件
  if ((db_version >= 12)); then
    conf_sqlnet
  fi
}
#==============================================================#
#                       创建 PDB数据库                           #
#==============================================================#
# 创建 PDB 数据库
function create_pdb() {
  local dbname=$1
  # 打印日志到终端和文件
  log_print "创建 PDB 数据库"
  # 如果启用了多租户架构，则创建可插入数据库 (PDB)
  for pdbs in ${pdbname//,/ }; do
    color_printf blue "正在创建 PDB：$pdbs"
    execute_sqlplus "$dbname" "" "create pluggable database $pdbs admin user admin identified by $database_passwd default tablespace users;
alter pluggable database all open;
alter pluggable database all save state;
alter session set container=$pdbs;
alter profile default limit password_life_time unlimited;"
  done
  # 查看 pdb
  execute_sqlplus "$dbname" "" "show pdbs"
}
#==============================================================#
#                         配置 SQLNET                              #
#==============================================================#
# 配置 SQLNET.ORA
function conf_sqlnet() {
  # 配置 sqlnet.ora 文件
  if check_file "$env_oracle_home/network/admin/sqlnet.ora"; then
    backup_restore_file "$env_oracle_home/network/admin/sqlnet.ora"
  fi
  run_as_oracle "cat <<-EOF >>$env_oracle_home/network/admin/sqlnet.ora
# OracleBegin
SQLNET.ALLOWED_LOGON_VERSION_CLIENT=8
SQLNET.ALLOWED_LOGON_VERSION_SERVER=8
EOF"
}
#==============================================================#
#                         配置 OMF                              #
#==============================================================#
# 配置 OMF 以及优化 RMAN
function conf_omf() {
  # 定义 omf 变量，判断版本在11以后是否需要在路径前添加 + 符号
  local omf dbname=$1 arch
  # 如果安装模式为 standalone，则获取数据组存储的路径；否则使用 oradata_dir 变量定义的路径。
  if [[ "$oracle_install_mode" == "standalone" ]]; then
    omf=+$data_asm_group
    # 判断是否存在归档日志组磁盘路径，如果存在，则获取 arch_asm_group 存储路径；否则使用 omf 变量定义的路径。
    if [[ $arch_base_disk ]]; then
      arch=+$arch_asm_group
    else
      arch=$omf
    fi
    # 使用 su 命令以 oracle 用户身份执行 rman 命令，配置控制文件备份地址\
    su - "$oracle_user" <<-SO
source /home/$oracle_user/.$dbname
rman target / <<-EOF
CONFIGURE SNAPSHOT CONTROLFILE NAME TO '$omf/snapcf_$dbname.f';
SHOW SNAPSHOT CONTROLFILE NAME;
EOF
SO
  else
    # 获取 oradata 目录的存储路径
    omf=$oradata_dir
    # 获取归档日志组存储路径
    arch=$archive_dir
  fi
  # 使用 su 命令以 oracle 用户身份执行 sqlplus 命令，配置数据库链接、redo log 和归档日志的存储路径
  execute_sqlplus "$dbname" "" "alter system set db_create_file_dest='$omf';
alter system set log_archive_dest_1='location=$arch';
alter system reset db_recovery_file_dest;
alter system reset db_recovery_file_dest_size;"
}
#==============================================================#
#                          配置控制文件                          #
#==============================================================#
function conf_controlfile() {
  log_print "配置 Oracle 数据库控制文件复用"
  local dbname=$1 ctl_count ctl_name ctl_name_new ctl_path
  ctl_count=$(execute_sqlplus "$dbname" "set pagesize 0" "select count(*) from v\$controlfile;" | tr -d '[:space:]')
  # 如果控制文件数量只有1个，则增加一个控制文件
  if ((ctl_count == 1)); then
    ctl_name=$(execute_sqlplus "$dbname" "set pagesize 0" "select name from v\$controlfile;" | tr -d '[:space:]')
    ctl_path=$(execute_sqlplus "$dbname" "set pagesize0" "select substr(name, 1, instr(name, '/', 1, 3)) from v\$controlfile;" | tr -d '[:space:]')
    if [[ "$oracle_install_mode" == "standalone" ]]; then
      ctl_name_new=$(execute_sqlplus "$dbname" "set pagesize 0" "select substr(replace(name,substr(name,1,instr(name,'/',1)-1),'+$data_asm_group'),1,instr(name,'/',-1)-1) || '/control02.ctl' from v\$controlfile where name = '$ctl_name';" | tr -d '[:space:]')
      # 重启数据库至 nomount 状态
      run_as_oracle "srvctl stop database -d $dbname"
      run_as_oracle "srvctl start database -d $dbname -o nomount"
    else
      ctl_name_new="${ctl_path}control02.ctl"
      # 重启数据库至 nomount 状态
      execute_sqlplus "$dbname" "" "shu immediate;
startup nomount;" >/dev/null 2>&1
    fi
    # 从原来的控制文件恢复一个新的控制文件
    su - "$oracle_user" <<-SO
source /home/$oracle_user/.$dbname
rman target / <<-EOF
restore controlfile to '$ctl_name_new' from '$ctl_name';
EOF
SO
    # 修改数据库控制文件参数
    execute_sqlplus "$dbname" "" "alter system set control_files='$ctl_name','$ctl_name_new' scope=spfile;"
    # 重启数据库生效参数
    if [[ "$oracle_install_mode" == "standalone" ]]; then
      run_as_oracle "srvctl stop database -d $dbname"
      run_as_oracle "srvctl start database -d $dbname"
    else
      execute_sqlplus "$dbname" "" "shu immediate;
startup;" >/dev/null 2>&1
    fi
  fi
  # 查询当前数据库控制文件
  echo
  color_printf blue "数据库控制文件："
  execute_sqlplus "$dbname" "col name for a100" "select name from v\$controlfile;"
}
#==============================================================#
#                    Configure redolog                         #
#==============================================================#
function conf_redolog() {
  log_print "配置在线重做日志"
  local i dbname=$1 redolog_path max_group new_group
  max_group=$(execute_sqlplus "$dbname" "set pagesize0" "select max(group#) from v\$logfile;" | tr -d '[:space:]')
  redolog_path=$(execute_sqlplus "$dbname" "set pagesize0" "select substr(member, 1, instr(member, '/', -1, 1)) from v\$logfile where rownum = 1;" | tr -d '[:space:]')
  for ((a = 1; a < 6; a++)); do
    new_group=$((a + max_group))
    if ((new_group < 10)); then
      printf -v new_group "%02d" "$new_group"
    fi
    if [[ "$oracle_install_mode" == "single" ]]; then
      execute_sqlplus "$dbname" "" "alter database add logfile group $new_group '${redolog_path}redo${new_group}.log' size ${redosize}M;" >/dev/null 2>&1
    else
      execute_sqlplus "$dbname" "" "alter database add logfile group $new_group size ${redosize}M;" >/dev/null 2>&1
    fi
  done
  execute_sqlplus "$dbname" "col member for a80" "select a.thread#,a.group#,b.member member,a.bytes/1024/1024 \"size(M)\" from v\$log a,v\$logfile b where a.group#=b.group# order by 1,2;"
}
#==============================================================#
#                       配置数据库开机自启                        #
#==============================================================#
function db_autostart() {
  log_print "配置 Oracle 数据库开机自启"
  local dbname=$1
  # 查询当前数据库在线重做日志
  # 修改 oratab 文件，将数据库自动启动状态改为 Y
  sed -i 's/db:N/db:Y/' /etc/oratab
  if [[ "$oracle_install_mode" == "standalone" ]]; then
    if ((gi_version == 11)); then
      # 修改资源配置，设置数据库自动启动
      "$env_grid_home"/bin/crsctl modify resource "ora.$dbname.db" -attr "AUTO_START=always"
    else
      # 该版本修改数据库自动启动方式不受支持，需要在命令中添加 -unsupported 参数
      "$env_grid_home"/bin/crsctl modify resource "ora.$dbname.db" -attr "AUTO_START=always" -unsupported
    fi
    color_printf blue "数据库开机自启配置："
    "$env_grid_home"/bin/crsctl stat res "ora.$dbname.db" -p | grep AUTO_START
  else
    color_printf blue "数据库开机自启配置："
    # 修改 dbstart 脚本，将变量 ORACLE_HOME_LISTNER 的值改为 $ORACLE_HOME
    sed -i "s/ORACLE_HOME_LISTNER=\$1/ORACLE_HOME_LISTNER=$ORACLE_HOME/" "$env_oracle_home/bin/dbstart"
    rc_file="/etc/rc.d/rc.local"
    # 备份 rc 文件
    backup_restore_file $rc_file
    # 在 rc 文件中添加启动监听器和数据库的命令，并配置权限为可执行
    if ! grep '#!/bin/bash' $rc_file >/dev/null 2>&1; then
      write_file "N" $rc_file "#!/bin/bash"
    fi
    write_file "N" $rc_file "# OracleBegin
su $oracle_user -lc \"$env_oracle_home/bin/lsnrctl start\"
su $oracle_user -lc \"$env_oracle_home/bin/dbstart\""
    chmod +x $rc_file
    grep -v "^\s*\(#\|$\)" $rc_file
  fi
}
#==============================================================#
#                      配置 RMAN 备份脚本                        #
#==============================================================#
function db_backup() {
  log_print "配置 RMAN 备份任务"
  install_package "cron"
  local dbname=$1 scripts_dir=/home/$oracle_user/scripts rman_log_dir="/backup" rman_config
  mkdir -p "$scripts_dir"
  # 共用的 RMAN 配置参数
  rman_config=$(
    cat <<-RMAN
allocate channel c1 device type disk;
allocate channel c2 device type disk;
crosscheck backup;
crosscheck archivelog all;
sql"alter system archive log current";
delete noprompt expired backup;
delete noprompt obsolete device type disk;
backup not backed up 1 times as compressed backupset archivelog all format '/backup/arch_%d_%T_%t_%s_%p';
RMAN
  )
  # 删除过期归档日志脚本
  local del_arch_script="$scripts_dir/del_arch_$dbname.sh"
  cat >"$del_arch_script" <<DELARCH
#!/bin/bash
source ~/.$dbname
deltime=\$(date +"20%y%m%d%H%M%S")
rman target / nocatalog msglog $scripts_dir/del_arch_${dbname}_\$deltime.log <<-EOF
crosscheck archivelog all;
delete noprompt archivelog until time 'sysdate-7';
delete noprompt force archivelog until time 'SYSDATE-10';
EOF
DELARCH
  chmod +x "$del_arch_script"
  # Level 0 备份脚本
  local lv0_backup_script="$scripts_dir/dbbackup_lv0_$dbname.sh"
  cat >"$lv0_backup_script" <<LV0BACKUP
#!/bin/bash
source ~/.$dbname
backtime=\$(date +"20%y%m%d%H%M%S")
rman target / log=$rman_log_dir/level0_backup_${dbname}_\$backtime.log<<-EOF
run {
$rman_config
backup incremental level 0 database include current controlfile format '/backup/backlv0_%d_%T_%t_%s_%p';
}
EOF
LV0BACKUP
  chmod +x "$lv0_backup_script"
  # Level 1 备份脚本
  local lv1_backup_script="$scripts_dir/dbbackup_lv1_$dbname.sh"
  cat >"$lv1_backup_script" <<LV1BACKUP
#!/bin/bash
source ~/.$dbname
backtime=\$(date +"20%y%m%d%H%M%S")
rman target / log=$rman_log_dir/level1_backup_${dbname}_\$backtime.log<<-EOF
run {
$rman_config
backup incremental level 1 database include current controlfile format '/backup/backlv1_%d_%T_%t_%s_%p';
}
EOF
LV1BACKUP
  chmod +x "$lv1_backup_script"
  # 添加 crontab 计划任务
  local crontab_file="/var/spool/cron/$oracle_user"
  if check_file "$crontab_file"; then
    backup_restore_file "$crontab_file"
  else
    # 不存在文件时，生成一个原始空文件
    touch /var/spool/cron/"$oracle_user".original
  fi
  write_file "N" "$crontab_file" "# OracleBegin
00 02 * * * $del_arch_script
#00 00 * * 0 $lv0_backup_script
#00 00 * * 1,2,3,4,5,6 $lv1_backup_script"
  if check_file /etc/cron.allow; then
    write_file "N" "/etc/cron.allow" "$oracle_user"
  fi
  chown -R "$oracle_user":oinstall "$scripts_dir" "$rman_log_dir"
  cat /var/spool/cron/"$oracle_user"
}
#==============================================================#
#                        优化数据库参数                          #
#==============================================================#
function conf_para() {
  log_print "优化数据库参数"
  local dbname=$1 nums=$2 sga_target pga_target
  # memory for db sga_size(MB) = os_memory_total * 0.8 * 0.8 / 1024
  ((sga_target = (os_memory_total * 8 * 8 / 100 / 1024 / nums)))
  sga_target="${sga_target}M"
  # memory for db pga_size(MB) = os_memory_total * 0.8 * 0.2 / 1024
  ((pga_target = (os_memory_total * 8 * 2 / 100 / 1024 / nums)))
  pga_target="${pga_target}M"
  # 23ai 已经取消了这两个 job
  if ((db_version != 23)); then
    execute_sqlplus "$dbname" "" "exec dbms_scheduler.disable('ORACLE_OCM.MGMT_CONFIG_JOB');
exec dbms_scheduler.disable('ORACLE_OCM.MGMT_STATS_CONFIG_JOB');"
  fi
  execute_sqlplus "$dbname" "" "BEGIN
DBMS_AUTO_TASK_ADMIN.DISABLE(
client_name => 'auto space advisor',
operation => NULL,
window_name => NULL);
END;
/
BEGIN
DBMS_AUTO_TASK_ADMIN.DISABLE(
client_name => 'sql tuning advisor',
operation => NULL,
window_name => NULL);
END;
/
alter profile default limit password_grace_time unlimited;
alter profile default limit password_life_time unlimited;
alter profile default limit password_lock_time unlimited;
alter profile default limit failed_login_attempts unlimited;
alter system set audit_trail=none sid='*' scope=spfile;
alter system set sga_max_size=$sga_target sid='*' scope=spfile;
alter system set sga_target=$sga_target sid='*' scope=spfile;
alter system set pga_aggregate_target=$pga_target sid='*' scope=spfile;
alter system set processes=2000 scope=spfile;
alter system set open_cursors=1000 scope=spfile;
alter system set session_cached_cursors=300 scope=spfile;
alter system set db_files=5000 scope=spfile;
alter system set \"_undo_autotune\"=false sid='*' scope=spfile;
alter system set undo_retention=10800 scope=spfile;
alter system set control_file_record_keep_time=31;
alter system set event='28401 trace name context forever,level 1','10949 trace name context forever,level 1' sid='*' scope=spfile;
alter system set \"_b_tree_bitmap_plans\"=false sid='*';
alter system set deferred_segment_creation=false sid='*';
alter system set \"_optimizer_adaptive_cursor_sharing\"=false sid='*' scope=spfile;
alter system set \"_optimizer_extended_cursor_sharing\"=none sid='*' scope=spfile;
alter system set \"_optimizer_extended_cursor_sharing_rel\"=none sid='*' scope=spfile;
alter system set \"_optimizer_use_feedback\"=false sid ='*' scope=spfile;
alter system set \"_cleanup_rollback_entries\"=2000 sid='*' scope=spfile;
alter system set \"_datafile_write_errors_crash_instance\"=false sid='*';
alter system set parallel_max_servers=64 sid='*';"
  # for 11g implied parameters
  if ((db_version == 11)); then
    execute_sqlplus "$dbname" "" "alter system set resource_limit=true sid='*' scope=spfile;
alter system set resource_manager_plan='force:' sid='*' scope=spfile;
alter system set \"_optimizer_null_aware_antijoin\"=false sid ='*' scope=spfile;
alter system set \"_px_use_large_pool\"=true sid ='*' scope=spfile;
alter system set \"_partition_large_extents\"=false sid='*' scope=spfile;
alter system set \"_index_partition_large_extents\"=false sid='*' scope=spfile;
alter system set \"_use_adaptive_log_file_sync\"=false sid='*' scope=spfile;
alter system set \"_memory_imm_mode_without_autosga\"=false sid='*' scope=spfile;
alter system set enable_ddl_logging=true sid='*' scope=spfile;
alter system set sec_case_sensitive_logon=false sid='*' scope=spfile;"
  fi
  color_printf blue "数据库参数："
  # 查看数据库参数
  execute_sqlplus "$dbname" "col name for a50
col sid for a10
col spvalue for a80
col VALUE for a80" "SELECT DISTINCT s.name,
                s.sid,
                s.value spvalue,
                p.value VALUE
  FROM v\$spparameter s,
       gv\$parameter  p
 WHERE s.name = p.name
   AND (s.value IS NOT NULL OR (p.name IN ('statistics_level',
                                           'processes',
                                           'sessions',
                                           'db_files',
                                           'spfile',
                                           'optimizer_adaptive_features',
                                           'optimizer_adaptive_plans',
                                           'optimizer_adaptive_statistics',
                                           'max_string_size',
                                           'control_file_record_keep_time',
                                           '_use_adaptive_log_file_sync',
                                           'fast_start_parallel_rollback',
                                           '_datafile_write_errors_crash_instance',
                                           'max_dump_file_size',
                                           'parallel_max_servers',
                                           'deferred_segment_creation',
                                           '_optimizer_use_feedback',
                                           'open_cursors',
                                           'session_cached_cursors',
                                           'OPTIMIZER_INDEX_COST_ADJ',
                                           'optimizer_index_caching',
                                           'audit_trail',
                                           'SEC_CASE_SENSITIVE_LOGON',
                                           'parallel_force_local',
                                           'db_file_multiblock_read_count',
                                           'event',
                                           'dispatchers',
                                           'db_writer_processes',
                                           'optimizer_mode')))
   AND p.name NOT IN ('thread',
                      'instance_name',
                      'instance_number',
                      'undo_tablespace',
                      'local_listener',
                      'remote_listener',
                      'lisneter_network',
                      'control_files')
 ORDER BY s.name;"
}
#==============================================================#
#                         配置大页内存                           #
#==============================================================#
function conf_hugepage() {
  log_print "配置大页内存"
  # 获取当前系统的内核版本
  local KERN HPG_SZ NUM_PG=0 MIN_PG RES_BYTES HUGETLB_POOL
  KERN=$(uname -r | awk -F. '{ printf("%d.%d\n",$1,$2); }')
  HPG_SZ=$(grep Hugepagesize /proc/meminfo | awk '{print $2}')
  if [ -z "$HPG_SZ" ]; then
    color_printf yellow "在当前系统中不支持 HugePages！"
    echo
    return 1
  fi
  # 初始化计数器，累加所需的 HugePages 数量
  for SEG_BYTES in $(ipcs -m | cut -c44-300 | awk '{print $1}' | grep "[0-9][0-9]*"); do
    MIN_PG=$(echo "$SEG_BYTES/($HPG_SZ*1024)" | bc -q)
    if ((MIN_PG > 0)); then
      NUM_PG=$(echo "$NUM_PG+$MIN_PG+1" | bc -q)
    fi
  done
  # 计算所需的 HugePages 总大小（以字节为单位）
  RES_BYTES=$(echo "$NUM_PG * $HPG_SZ * 1024" | bc -q)
  # 如果需要使用 HugePages 的共享内存段总大小小于 100MB，则无法配置成功
  if ((RES_BYTES < 100000000)); then
    color_printf yellow "无法为 HugePages 配置分配足够的共享内存段。HugePages 只能用于大小与 Oracle 数据库 SGA 匹配的共享内存段。请确保：
* Oracle 数据库实例正在运行；
* Oracle 数据库 11g 自动内存管理（AMM）未配置！"
    echo
    return 1
  fi
  # 根据不同的内核版本，采用不同的 HugePages 配置方式
  case $KERN in
  "2.4")
    # 对于 2.4 版本的内核，使用 hugetlbfs 模式，并设置 vm.hugetlb_pool 参数
    HUGETLB_POOL=$(echo "$NUM_PG*$HPG_SZ/1024" | bc -q)
    echo "建议的参数设置：vm.hugetlb_pool = $HUGETLB_POOL"
    sysctl -w vm.hugetlb_pool="$HUGETLB_POOL"
    write_file "N" "/etc/sysctl.conf" "vm.hugetlb_pool=$HUGETLB_POOL"
    ;;
  *)
    # 对于其他版本的内核，直接设置 vm.nr_hugepages 参数即可
    echo "建议的参数设置：vm.nr_hugepages = $NUM_PG"
    sysctl -w vm.nr_hugepages="$NUM_PG"
    write_file "N" "/etc/sysctl.conf" "vm.nr_hugepages=$NUM_PG"
    ;;
  esac
  grep HugePages_Total /proc/meminfo
}
#==============================================================#
#                       配置 glogin.sql                         #
#==============================================================#
function conf_glogin() {
  # 定义函数，用于写入 glogin.sql 配置
  write_glogin_sql_config() {
    local target_file="$1"
    write_file "Y" "$target_file" "define _editor=vi
set serveroutput on size 1000000
set trimspool on
set long 5000
set linesize 100
set pagesize 9999
column plan_plus_exp format a80
set sqlprompt '&_user.@&_connect_identifier. SQL> '"
  }
  # 配置 glogin.sql
  log_print "配置 glogin.sql"
  backup_restore_file "$env_oracle_home/sqlplus/admin/glogin.sql"
  write_glogin_sql_config "$env_oracle_home/sqlplus/admin/glogin.sql"
  if [[ "$oracle_install_mode" == "standalone" ]]; then
    backup_restore_file "$env_grid_home/sqlplus/admin/glogin.sql"
    write_glogin_sql_config "$env_grid_home/sqlplus/admin/glogin.sql"
  fi
  # 移除 glogin.sql 中的注释行和空行
  grep -v "^\s*\(#\|$\|--\)" "$env_oracle_home/sqlplus/admin/glogin.sql"
}
#==============================================================#
#                          优化数据库                            #
#==============================================================#
function db_optimize() {
  for name in "${db_names[@]}"; do
    conf_controlfile "$name"
    conf_redolog "$name"
    db_autostart "$name"
    db_backup "$name"
    conf_para "$name" ${#db_names[@]}
  done
  conf_glogin
}
function end_del_file() {
  rm_file "$software_dir/db.rsp"
  rm_file "$software_dir/oracle.rsp"
  rm_file "$software_dir/grid.rsp"
  rm_file "$software_dir/database"
  rm_file "$software_dir/grid"
  rm_file "$software_dir/README.txt"
  rm_file "$software_dir/README.html"
  rm_file "$software_dir/bundle.xml"
  rm_file "$software_dir/18370031"
}
#==============================================================#
#                          主机是否重启                          #
#==============================================================#
function ask_for_reboot() {
  declare -u isreboot
  read -rep "$(echo -e "\033[1;34m$1 \E[0m")" isreboot
  echo
  # 安装完成删除脚本相关文件
  end_del_file
  if [[ $isreboot == "Y" ]]; then
    color_printf blue "正在重启当前节点主机......"
    shutdown -r now
  else
    exit 1
  fi
}
#==============================================================#
#                          Logo 打印                            #
#==============================================================#
function logo_print() {
  cat <<-EOF

   ███████                             ██          ████████ ██               ██  ██ ██                    ██              ██  ██
  ██░░░░░██                           ░██         ██░░░░░░ ░██              ░██ ░██░██                   ░██             ░██ ░██
 ██     ░░██ ██████  ██████    █████  ░██  █████ ░██       ░██       █████  ░██ ░██░██ ███████   ██████ ██████  ██████   ░██ ░██
░██      ░██░░██░░█ ░░░░░░██  ██░░░██ ░██ ██░░░██░█████████░██████  ██░░░██ ░██ ░██░██░░██░░░██ ██░░░░ ░░░██░  ░░░░░░██  ░██ ░██
░██      ░██ ░██ ░   ███████ ░██  ░░  ░██░███████░░░░░░░░██░██░░░██░███████ ░██ ░██░██ ░██  ░██░░█████   ░██    ███████  ░██ ░██
░░██     ██  ░██    ██░░░░██ ░██   ██ ░██░██░░░░        ░██░██  ░██░██░░░░  ░██ ░██░██ ░██  ░██ ░░░░░██  ░██   ██░░░░██  ░██ ░██
 ░░███████  ░███   ░░████████░░█████  ███░░██████ ████████ ░██  ░██░░██████ ███ ███░██ ███  ░██ ██████   ░░██ ░░████████ ███ ███
  ░░░░░░░   ░░░     ░░░░░░░░  ░░░░░  ░░░  ░░░░░░ ░░░░░░░░  ░░   ░░  ░░░░░░ ░░░ ░░░ ░░ ░░░   ░░ ░░░░░░     ░░   ░░░░░░░░ ░░░ ░░░ 

EOF
  echo
  color_printf yellow "注意：本脚本仅用于新服务器上实施部署数据库使用，严禁在已运行数据库的主机上执行，以免发生数据丢失或者损坏，造成不可挽回的损失！！！"
}
#==============================================================#
#                          传参前校验函数                         #
#==============================================================#
function pre_para_check() {
  # 检查脚本路径
  if [[ "$(dirname "$(readlink -f "$0")")" != "/soft" ]]; then
    color_printf yellow "注意：建议将 Oracle 软件安装包以及脚本放到 /soft 目录下并在 /soft 目录下执行脚本，否则可能会失败！"
  fi
  # 检查脚本名称是否为 OracleShellInstall
  if [[ "$(basename "$0")" != "OracleShellInstall" ]]; then
    color_printf red "本脚本不允许修改脚本名称，请修改回：OracleShellInstall，已退出！"
    exit 1
  fi
  # 判断当前执行脚本用户是否为 root 用户
  if [ "$(id -u)" != 0 ]; then
    color_printf red "本脚本需要使用 root 用户执行，已退出！"
    exit 1
  fi
}
#==============================================================#
#                           校验传参                            #
#==============================================================#
function accept_para() {
  while [[ $1 ]]; do
    case $1 in
    -lrp | --local_repo)
      checkpara_NULL "$1" "$2"
      checkpara_YN "$1" "$2"
      local_repo=$2
      shift 2
      ;;
    -o | --db_name)
      checkpara_NULL "$1" "$2"
      db_name=$2
      shift 2
      ;;
    -n | --hostname)
      checkpara_NULL "$1" "$2"
      hostname=$2
      shift 2
      ;;
    -d | --env_base_dir)
      checkpara_NULL "$1" "$2"
      env_base_dir=${2%/}
      shift 2
      ;;
    -ord | --oradata_dir)
      checkpara_NULL "$1" "$2"
      oradata_dir=${2%/}
      shift 2
      ;;
    -ard | --archive_dir)
      checkpara_NULL "$1" "$2"
      archive_dir=${2%/}
      shift 2
      ;;
    -gu | --grid_user)
      checkpara_NULL "$1" "$2"
      grid_user=$2
      shift 2
      ;;
    -gp | --grid_passwd)
      checkpara_NULL "$1" "$2"
      check_password "$1" "$2"
      grid_passwd=$2
      shift 2
      ;;
    -ou | --oracle_user)
      checkpara_NULL "$1" "$2"
      oracle_user=$2
      shift 2
      ;;
    -op | --oracle_passwd)
      checkpara_NULL "$1" "$2"
      check_password "$1" "$2"
      oracle_passwd=$2
      shift 2
      ;;
    -dp | --database_passwd)
      checkpara_NULL "$1" "$2"
      check_password "$1" "$2"
      database_passwd=$2
      shift 2
      ;;
    -lf | --local_ifname)
      checkpara_NULL "$1" "$2"
      local_ifname=$2
      shift 2
      ;;
    -ds | --db_characterset)
      checkpara_NULL "$1" "$2"
      checkpara_DBCHARSET "$1" "$2"
      db_characterset=$2
      shift 2
      ;;
    -ns | --nation_characterset)
      checkpara_NULL "$1" "$2"
      checkpara_NCHARSET "$1" "$2"
      nation_characterset=$2
      shift 2
      ;;
    -dbs | --db_block_size)
      checkpara_NUMERIC "$1" "$2"
      checkpara_DBS "$1" "$2"
      db_block_size=$2
      shift 2
      ;;
    -redo | --redosize)
      checkpara_NULL "$1" "$2"
      redosize=$2
      shift 2
      ;;
    -er | --enable_arch)
      checkpara_NULL "$1" "$2"
      checkpara_tf "$1" "$2"
      enable_arch=$2
      shift 2
      ;;
    -pdb | --pdbname)
      checkpara_NULL "$1" "$2"
      pdbname=$2
      iscdb=true
      shift 2
      ;;
    -dn | --data_asm_group)
      checkpara_NULL "$1" "$2"
      data_asm_group=$2
      shift 2
      ;;
    -an | --arch_asm_group)
      checkpara_NULL "$1" "$2"
      arch_asm_group=$2
      shift 2
      ;;
    -mp | --multipath)
      checkpara_NULL "$1" "$2"
      checkpara_YN "$1" "$2"
      multipath=$2
      shift 2
      ;;
    -adc | --asm_disk_conf)
      checkpara_NULL "$1" "$2"
      checkpara_YN "$1" "$2"
      asm_disk_conf=$2
      shift 2
      ;;
    -dd | --data_base_disk)
      checkpara_NULL "$1" "$2"
      data_base_disk=$2
      shift 2
      ;;
    -ad | --arch_base_disk)
      checkpara_NULL "$1" "$2"
      arch_base_disk=$2
      shift 2
      ;;
    -dr | --data_redun)
      checkpara_NULL "$1" "$2"
      checkpara_REDUN "$1" "$2"
      data_redun=$2
      shift 2
      ;;
    -ar | --arch_redun)
      checkpara_NULL "$1" "$2"
      checkpara_REDUN "$1" "$2"
      arch_redun=$2
      shift 2
      ;;
    -gui | --isgui)
      checkpara_NULL "$1" "$2"
      checkpara_YN "$1" "$2"
      isgui=$2
      shift 2
      ;;
    -vbox | --virtualbox)
      checkpara_NULL "$1" "$2"
      checkpara_YN "$1" "$2"
      virtualbox=$2
      shift 2
      ;;
    -m | --only_conf_os)
      checkpara_NULL "$1" "$2"
      checkpara_YN "$1" "$2"
      only_conf_os=$2
      shift 2
      ;;
    -ug | --install_until_grid)
      checkpara_NULL "$1" "$2"
      checkpara_YN "$1" "$2"
      install_until_grid=$2
      shift 2
      ;;
    -ud | --install_until_db)
      checkpara_NULL "$1" "$2"
      checkpara_YN "$1" "$2"
      install_until_db=$2
      shift 2
      ;;
    -opd | --optimize_db)
      checkpara_NULL "$1" "$2"
      checkpara_YN "$1" "$2"
      optimize_db=$2
      shift 2
      ;;
    -install_mode | --oracle_install_mode)
      checkpara_NULL "$1" "$2"
      oracle_install_mode=$2
      shift 2
      ;;
    -giv | --gi_version)
      checkpara_NULL "$1" "$2"
      gi_version=$2
      shift 2
      ;;
    -dbv | --db_version)
      checkpara_NULL "$1" "$2"
      db_version=$2
      shift 2
      ;;
    -hf | --huge_flag)
      checkpara_NULL "$1" "$2"
      checkpara_YN "$1" "$2"
      huge_flag=$2
      shift 2
      ;;
    -debug | --debug)
      debug_flag="Y"
      shift 1
      ;;
    -fd | --filter_disk)
      checkpara_NULL "$1" "$2"
      filter_disk "$2"
      exit 0
      ;;
    -h | --help)
      help
      exit 0
      ;;
    *)
      color_printf red "脚本执行命令中的参数 [ $1 ] 传参不正确，请使用 'sh OracleShellInstall --help' 以获取更多帮助信息！"
      ;;
    esac
  done
}
function conf_master_node() {
  local paras paran parav
  paras=(
    "-lf local_ifname"
  )
  if [[ $oracle_install_mode == "standalone" ]]; then
    paras+=(
      "-dd data_base_disk"
    )
  fi
  for para in "${paras[@]}"; do
    paran=${para%% *}
    parav=${para##* }
    if [[ -z ${!parav} ]]; then
      color_printf red "Oracle $oracle_install_mode 模式安装必须设置参数：[ $paran ]，请运行命令 'sh OracleShellInstall --help' 以获取更多帮助信息！"
    fi
  done
  for name in "${db_names[@]}"; do
    local length=${#name}
    check_DBNAME "$name"
    if ((length > 8 && length <= 12)); then
      color_printf purple "数据库名称 $name 长度超过 8 位，受 Oracle 限制，建库时会自动截取前 8 位作为数据库名称：${name:0:8}，请确认是否继续 (Y/N): [Y] "
      echo
    elif ((length > 12)); then
      color_printf red "数据库实例名称 $name 长度不能超过 12 位，受 Oracle 限制，建库会报错失败，请检查参数 [ -o ] 的值！"
      echo
    fi
  done
  if [[ $local_ip ]]; then
    if check_ip "$local_ip"; then
      check_ip_connectivity "$local_ip"
    else
      color_printf red "参数 [ -lf ] 网卡名称：$local_ifname 对应的 IP：$local_ip 不合规，请检查！"
    fi
  else
    color_printf red "参数 [ -lf ] 网卡名称：$local_ifname 不存在或者未配置 IP 信息，请检查！"
  fi
  # 单机 ASM 检查
  if [[ "$oracle_install_mode" == "standalone" ]]; then
    if ((os_version == 7)); then
      if ((gi_version == 11)); then
        # 7 版本操作系统安装 11GR2 Grid 存在 bug 18370031，必须上传 p18370031_112040_Linux-x86-64.zip 补丁包
        if check_file "$software_dir"/p18370031_112040_Linux-x86-64.zip; then
          check_md5sum "$software_dir/p18370031_112040_Linux-x86-64.zip" "2a081e6145d4e4d2bf5350709dd3affa"
        else
          color_printf red "在 Linux 7 安装 11GR2 RAC 时，必须应用补丁 18370031，请上传补丁包 p18370031_112040_Linux-x86-64.zip 到 $software_dir 目录下！"
        fi
      fi
    fi
  fi
}
function handle_para() {
  # 全局变量赋值
  if [[ $software_dir == "$env_base_dir" ]]; then
    color_printf red "Oracle 软件安装包以及脚本不能放在 $env_base_dir，建议创建 /soft 目录存放！"
  fi
  env_oracle_base=$env_base_dir/app/oracle
  env_oracle_inven=$env_base_dir/app/oraInventory
  env_grid_base=$env_base_dir/app/grid
  if [[ -z "$archive_dir" ]]; then
    archive_dir=$oradata_dir/archivelog
  fi
  IFS=',' read -ra db_names <<<"$db_name"
  local_ip=$(ip addr show dev "$local_ifname" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n 1)
  HOSTNAME=$hostname
  # 配置安装包信息
  if [[ "$oracle_install_mode" == "standalone" ]]; then
    get_grid_soft
  fi
  get_db_soft
  # 配置软件源
  conf_repo
  # 主节点校验必传参数
  conf_master_node
}
#==============================================================#
#                         获取操作系统信息                        #
#==============================================================#
function get_os_info() {
  local os_file
  libc_version=$(ldd --version | head -n 1 | awk '{print $NF}' | cut -d '.' -f 2)
  # 获取 cpu 类型
  cpu_type=$(uname -m)
  # 获取 os 类型
  if [[ -e /etc/os-release ]]; then
    os_type=$(grep -oP '^ID="?(\K[^"]+|[^"]+$)' /etc/os-release)
    pretty_name=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d'"' -f2)
  else
    os_file=$(if [[ -f "/etc/system-release" ]]; then echo /etc/system-release; else echo /etc/redhat-release; fi)
    os_type=$(grep -oP '^[A-Za-z]+' "$os_file")
    pretty_name=$(cat /etc/system-release)
  fi
  # 获取 os 版本
  if ((libc_version >= 12 && libc_version <= 16)); then
    os_version=6
  elif ((libc_version >= 17 && libc_version <= 27)); then
    os_version=7
  elif ((libc_version >= 28 && libc_version <= 33)); then
    os_version=8
  elif ((libc_version >= 34 && libc_version <= 38)); then
    os_version=9
  elif ((libc_version >= 39)); then
    os_version=10
  else
    color_printf red "当前操作系统版本 [ $pretty_name ] 不在脚本支持列表中，如有需要请联系开发者适配！"
  fi
  # 处理系统默认配置
  conf_os
}
#==============================================================#
#                    选择数据库安装模式和版本                      #
#==============================================================#
function select_db_options() {
  local dbversion
  while :; do
    read -rep "$(echo -e "\033[1;34m请选择安装模式 [单机(si)/单机ASM(sa)] : \E[0m")" oracle_install_mode
    echo
    case "$oracle_install_mode" in
    si) oracle_install_mode=single ;;
    sa) oracle_install_mode=standalone ;;
    esac
    if [[ "$oracle_install_mode" =~ ^(single|standalone)$ ]]; then
      color_printf green "数据库安装模式:" "$oracle_install_mode"
      break
    else
      color_printf yellow "数据库安装模式输入错误，请重新选择！"
    fi
  done
  dbversion='11|12|19|21|23'
  while :; do
    echo
    read -rep "$(echo -e "\033[1;34m请选择数据库版本 [$dbversion] : \E[0m")" db_version
    echo
    if [[ "$db_version" =~ ^($dbversion)$ ]]; then
      color_printf green "数据库版本:" "$db_version"
      break
    else
      color_printf yellow "数据库版本输入错误，请重新选择！"
    fi
  done
  echo
  if [[ "$oracle_install_mode" =~ ^(standalone)$ ]]; then
    # gi_version 未传参，则代表 GI 和 DB 版本相同
    if [[ -z "$gi_version" ]]; then
      gi_version=$db_version
    else
      # 判断 gi 版本需要大于 db 版本
      if ((gi_version < db_version)); then
        color_printf red "参数 [ -giv ] 的值：GI 版本 $gi_version 必须必须大于等于 DB 版本 $db_version，请检查！"
      fi
    fi
  fi
}
function install_time_record() {
  local signal=$1
  if [[ "$signal" == "start" ]]; then
    install_start_time=$(date +%s)
    # 安装日志提示
    date >>"$oracleinstalllog"
    color_printf green "OracleShellInstall 开始安装，详细安装过程可查看日志： tail -2000f $oracleinstalllog"
    echo
  elif [[ "$signal" == "end" ]]; then
    local install_end_time install_execution_time
    install_end_time=$(date +%s)
    install_execution_time=$((install_end_time - install_start_time))
    echo
    ask_for_reboot "恭喜！Oracle 一键安装执行完成 (耗时: $install_execution_time 秒)，现在是否重启主机：[Y/N]"
  fi
}
function conf_os() {
  # 避免Linux主机提示注册
  [[ -e /etc/yum/pluginconf.d/subscription-manager.conf ]] && sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/subscription-manager.conf
  # 避免Kyli/openEuler主机提示注册
  [[ -e /etc/yum/pluginconf.d/debuginfo-install.conf ]] && sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/debuginfo-install.conf
  # 切换用户时不显示 Last Login 信息
  sed -i 's/^session\+[[:space:]]\+include[[:space:]]\+postlogin/#&/g' /etc/pam.d/su
  # 处理 egrep 告警问题
  local target_line="echo \"\$cmd: warning: \$cmd is obsolescent; using grep -E\" >&2"
  if check_file /usr/bin/egrep; then
    if grep -q -F "$target_line" /usr/bin/egrep; then
      sed -i "/$target_line/s/^/#/" /usr/bin/egrep
    fi
  fi
  # 获取 profile 名称
  profile_name=.bash_profile
}

function conf_repo() {
  # 必须联网的操作系统，检查外网联通性
  echo
  # 检查本地 ISO 是否挂载
  if [[ $local_repo == "Y" ]]; then
    check_iso
    execute_and_log "正在配置本地软件源" conf_local_repository
  else
    yum clean all >/dev/null 2>&1
    if ! yum makecache >/dev/null 2>&1; then
      color_printf red "当前软件源配置错误，请自行检查软件源配置！"
    fi
  fi
}
function clean_old_envir() {
  color_printf purple "当前主机已存在数据库用户 $oracle_user 且 $env_base_dir 目录已存在，请检查是否连错主机，若没有则需要清理旧环境后再执行脚本，是否打印清理命令 (Y/N): [Y] "
  echo
  color_printf blue "请使用 root 用户手工执行清理旧环境命令（建议清理完成后重启主机）："
  echo
  # 删除用户和组
  local users=("$oracle_user") groups=("oinstall" "dba" "oper" "dgdba" "backupdba" "kmdba" "racdba") oracle_processes=("oracle" "$oracle_user" "ora_" "tnslsnr")
  local dirs_to_clean=("/etc/oracle" "$env_base_dir" "$oradata_dir" "$archive_dir") files_to_clean=("/etc" "/opt" "/tmp")
  # 针对单机 ASM 模式
  if [[ "$oracle_install_mode" == "standalone" ]]; then
    dirs_to_clean+=("/etc/init.d/init.tfa" "/etc/init.d/init.ohasd")
    # 添加 RAC 相关进程到 oracle_processes 数组
    oracle_processes+=("grid" "$grid_user" "crsd.bin" "ohasd.bin" "ohasd" "evmd.bin" "evmlogger.bin" "ocssd.bin" "agent.bin" "asm_" "ASM" "tfa" "tfa.TFAMain" "OSWatcher")
    # 删除 grid 用户
    users+=("$grid_user")
    # 添加 ASM 相关组
    groups+=("asmdba" "asmoper" "asmadmin")
  fi
  for user in "${users[@]}"; do
    # 查找并强制终止用户的所有进程
    if getent passwd "$user" >/dev/null 2>&1; then
      echo "pkill -KILL -u $user"
      echo "pkill -u $user -9 -f"
      echo "userdel -rf $user"
      if [[ "$os_type" == "kylin" ]]; then
        # 检查用户名是否在 /etc/uid_list 文件中
        if grep -q "^$user:" /etc/uid_list; then
          # 如果存在，使用 sed 命令删除该行
          echo "sed -i \"/^$user:/d\" /etc/uid_list"
        fi
      fi
    fi
  done
  for group in "${groups[@]}"; do
    if getent group "$group" >/dev/null 2>&1; then
      echo "groupdel $group"
    fi
  done
  # 清理旧文件和目录内容
  for dir in "${dirs_to_clean[@]}"; do
    if [[ "$dir" ]]; then
      echo "/bin/rm -rf $dir"
    fi
  done
  for path in "${files_to_clean[@]}"; do
    echo "find $path -maxdepth 1 \( -name \"Ora*\" -o -name \"ora*\" -o -name \"CVU*\" -o -name \"osw*\" -o -name \"hsperfdata*\" \) ! -name \"oracle-release\" -exec /bin/rm -rf {} +"
  done
  # 关闭数据库和监听进程
  for process in "${oracle_processes[@]}"; do
    if pgrep -f "$process" >/dev/null 2>&1; then
      echo "pkill -9 -f $process"
    fi
  done
  # 重启主机
  echo "shutdown -r now"
}
#==============================================================#
#                            主函数                             #
#==============================================================#
function main() {
  # 打印脚本 Logo
  logo_print
  # 脚本处理传参
  accept_para "$@"
  # 获取操作系统信息
  get_os_info
  pre_para_check
  select_db_options
  # 清理 oracle 安装旧环境
  # 判断当前安装用户是否存在，并且对应的 env_base_dir 目录下有数据，则清理
  if getent passwd "$oracle_user" >/dev/null 2>&1 && check_file "$env_base_dir"; then
    clean_old_envir
    echo
    exit 1
  fi
  # 检查 Oracle 官方兼容性
  check_oracle_compatibility
  # 获取共享磁盘 WWID
  if [[ "$oracle_install_mode" == "standalone" ]]; then
    conf_disk_wwid
  fi
  # 安装开始记录时间以及日志
  install_time_record "start"
  color_printf blue "正在进行安装前检查，请稍等......"
  # 脚本校验传参
  handle_para
  ## 打印系统信息
  execute_and_log "正在获取操作系统信息" print_sysinfo
  # 安装软件包
  execute_and_log "正在安装依赖包" pkg_install
  # 如果需要额外交换空间，则创建并启用 swap，避免报错 mkswap: error: swap area needs to be at least 40 KiB
  if ((swap_count > 40)); then
    execute_and_log "正在配置 Swap" conf_swap
  fi
  if { type firewalld || type iptables; } >/dev/null 2>&1; then
    execute_and_log "正在禁用防火墙" disable_firewall
  fi
  if type getenforce >/dev/null 2>&1 && check_file /etc/selinux/config; then
    execute_and_log "正在禁用 selinux" disable_selinux
  fi
  if check_file /etc/sysconfig/network; then
    execute_and_log "正在配置 nsyctl" conf_nsysctl
  fi
  execute_and_log "正在配置主机名和 hosts 文件" conf_hostname
  conf_hosts
  execute_and_log "正在创建用户和组" create_users_groups
  execute_and_log "正在创建安装目录" create_dir
  if type avahi-daemon >/dev/null 2>&1; then
    execute_and_log "正在配置 Avahi-daemon 服务" conf_avahi
  fi
  execute_and_log "正在配置透明大页 && NUMA && 磁盘 IO 调度器" conf_grub
  execute_and_log "正在配置操作系统参数 sysctl" conf_sysctl
  if ((os_version >= 7)); then
    if ((os_version >= 10)); then
      logind_file="/usr/lib/systemd/logind.conf"
    else
      logind_file="/etc/systemd/logind.conf"
    fi
    if grep -q "RemoveIPC=" $logind_file; then
      execute_and_log "正在配置 RemoveIPC" conf_ipc
    fi
  fi
  execute_and_log "正在配置用户限制 limit" conf_limits
  execute_and_log "正在配置 shm 目录" conf_shm
  # 检查 rlwrap 压缩包是否存在
  if ls "$software_dir"/rlwrap-*.gz >/dev/null 2>&1; then
    if ! type rlwrap >/dev/null 2>&1; then
      execute_and_log "正在安装 rlwrap 插件" install_rlwrap
    fi
  fi
  execute_and_log "正在配置用户环境变量" conf_profile
  # 单机模式安装
  install_single_mode() {
    execute_and_log "正在解压 Oracle 安装包" unzip_dbsoft
    if [[ $only_conf_os == "N" ]]; then
      execute_and_log "正在安装 Oracle 软件" install_dbsoft
      execute_and_log "正在创建监听" conf_netca
      if [[ $install_until_db == "N" ]]; then
        execute_and_log "正在创建数据库" create_db
      fi
    fi
  }
  # 单机 ASM 模式安装
  install_standalone_mode() {
    if [[ $asm_disk_conf == "Y" ]]; then
      conf_asm
    fi
    execute_and_log "正在解压 Grid 安装包" unzip_gridsoft
    execute_and_log "正在解压 Oracle 安装包" unzip_dbsoft
    if [[ $only_conf_os == "N" ]]; then
      execute_and_log "正在安装 Grid 软件" install_gridsoft
      if [[ $install_until_grid == "N" ]]; then
        execute_and_log "正在安装 Oracle 软件" install_dbsoft
        if [[ $install_until_db == "N" ]]; then
          execute_and_log "正在创建数据库" create_db
        fi
      fi
    fi
  }
  # 判断 Oracle 安装模式
  case "$oracle_install_mode" in
  "single")
    install_single_mode
    ;;
  "standalone")
    install_standalone_mode
    ;;
  esac
  # 优化数据库
  if [[ $optimize_db == "Y" ]]; then
    execute_and_log "正在优化数据库" db_optimize
  fi
  if [[ $huge_flag == "Y" ]]; then
    execute_and_log "正在配置内存大页" conf_hugepage
  fi
  install_time_record "end"
}
# 执行主函数
main "$@"
