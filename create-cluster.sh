#!/bin/bash

ip=$1
ports=$2

custom_configs=(cluster-require-full-coverage=no protected-mode=no)

# 检测是否有-c参数，如果有，将其解析，并将配置写入custom_configs中
has_config_option=false
config_options=()
next_is_password_arg=false
password=''
for arg in "$@"
do
  if [[ "$next_is_password_arg" == "true" ]];then
     password=$arg
     next_is_password_arg=false
     continue
  fi
  if [[ "$arg" == "-a" ]];then
     next_is_password_arg=true
     continue
  fi
  if [[ "$arg" == "-c" ]];then
     has_config_option=true
     continue
  fi
  if [[ "$has_config_option" == "true" ]];then
     config_options[${#config_options[@]}]=$arg
  fi
done

if [[ $(( ${#config_options[@]} % 2 )) != 0 || (${#config_options[@]} == 0 && ${has_config_option} == "true") ]]; then
   echo "error:Custom configuration parameters were wrong!"
   exit
fi

echo "The password of the Redis Cluster is $password"

item_idx=0
while (($item_idx<${#config_options[@]}))
do
  custom_configs[${#custom_configs[@]}]="${config_options[item_idx]}=${config_options[$(($item_idx+1))]}"
  let item_idx+=2
done

if [ -n "$password" ]; then
    config_len=${#custom_configs[@]}
    custom_configs[$((config_len+1))]="requirepass=$password"
    custom_configs[$((config_len+2))]="masterauth=$password"
fi

function help(){
   echo """
Help you create redis cluster easily!

Usage: ./create-cluster.sh <ip> <ports> [-c [config value [config value...]] [-a password]
  <ip>      The IP of Cluster binding.
  <ports>   Port Numbers for redis. Master in front, slave in back.
  -c        Custom cluster configuration. The configuration and values are separated by Spaces.
            You can write multiple configurations.
  -a        The password of the Redis Cluster.

Note:
  - At least 6 ports.
  - The number of ports must be even.

Example:
  ./create-cluster.sh 127.0.0.1 7001,7002,7003,7004,7005,7006
  ./create-cluster.sh 127.0.0.1 7001,7002,7003,7004,7005,7006 -c timeout 300
  ./create-cluster.sh 127.0.0.1 7001,7002,7003,7004,7005,7006 -c timeout 300 save '60 360'
  ./create-cluster.sh 127.0.0.1 7001,7002,7003,7004,7005,7006 -a 'mypass'
  ./create-cluster.sh 127.0.0.1 7001,7002,7003,7004,7005,7006 -c timeout 300 -a 'mypass'
"""
}

if (( ${#ip} < 7 || ${#ports} <= 2 )); then
   help
   exit 1
fi

array=(${ports//,/ })
port_len=${#array[@]}

if (( $[${port_len}%2] == 1 || $[${port_len}] < 6 )); then
  help
  exit 1
fi

for port in ${array[@]}
do
    # 先停止这些端口的redis
    pid=`ps -ef|grep redis|grep ${port}|awk '{printf $2}'`
    if (( ${#pid} > 0 )); then
      echo "kill redis in port $port"
      kill -9 $pid
    fi
done

if ( [[ -d "./redis" ]] && [[ ! -f ./redis/src/redis-cli ]] );then
  rm -rf redis
fi

if [[ ! -d "./redis" ]];then
   echo "unzip redis.tar.gz ..."
   tar -zxf redis-5.0.4.tar.gz
   echo "unzip finished!"
   mv redis-5.0.4 redis
   cd redis
   echo "compile redis ..."
   make install > /dev/null
   cd ..

   if [[ -f "./redis/src/redis-cli" ]]; then
       echo "Redis compile success!"
   else
       echo "Redis compile error!"
       exit 1
   fi
fi

if [[ -d "./config" ]]; then
  rm -rf ./config
fi

if [[ -d "./data" ]]; then
  rm -rf ./data
fi

mkdir config
mkdir data

for port in ${array[@]}
do
  echo -e "port ${port}\ndaemonize yes\ndir \"./data\"\nlogfile \"${port}.log\"\ndbfilename \"dump-${port}.rdb\"\ncluster-enabled yes\ncluster-config-file nodes-${port}.conf\ncluster-require-full-coverage no\nprotected-mode no\nbind ${ip}" > ./config/redis-${port}.conf
  for config_item in "${custom_configs[@]}"
    do
      temp=${config_item//=/ }
      echo -e ${temp} >> ./config/redis-${port}.conf
    done
  ./redis/src/redis-server ./config/redis-${port}.conf
done

echo "start redis-server success."

echo "ready to create cluster"

temp_str=""
for port in ${array[@]}
do
  temp_str="${temp_str} ${ip}:${port}"
done

sleep 1s

if [ -n "$password" ]; then
    echo yes | ./redis/src/redis-cli --cluster create ${temp_str} --cluster-replicas 1 -a ${password}
else
    echo yes | ./redis/src/redis-cli --cluster create ${temp_str} --cluster-replicas 1
fi

echo Finish!

for((i=1;i<=5;i++));
do
  sleep 1s
  echo -n .
done

echo 
echo ---------------------------------------------------------------
echo
if [ -n "$password" ]; then
    ./redis/src/redis-cli -h ${ip} -p ${array[0]} -a ${password} cluster nodes
else
    ./redis/src/redis-cli -h ${ip} -p ${array[0]} cluster nodes
fi

rm -rf start.sh
rm -rf stop.sh
echo "#!/bin/bash" >> start.sh
for port in ${array[@]}
do
    echo "./redis/src/redis-server ./config/redis-${port}.conf" >> start.sh
done

chmod +x start.sh

echo "#!/bin/bash" >> stop.sh
echo "ports=${ports}" >> stop.sh
echo 'array=(${ports//,/ })' >> stop.sh
echo 'for port in ${array[@]}' >> stop.sh
echo 'do' >> stop.sh
echo '   pid=`ps -ef|grep redis|grep ${port}|awk '"'"'{printf $2}'"'"'`' >> stop.sh
echo '    if (( ${#pid} > 0 )); then' >> stop.sh
echo 'echo "kill redis in port $port"' >> stop.sh
echo '      kill -9 $pid' >> stop.sh
echo '    fi'  >> stop.sh
echo 'done' >> stop.sh

chmod +x stop.sh
