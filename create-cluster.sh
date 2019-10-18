#!/bin/bash

ip=$1
ports=$2

function help(){
   echo ""
   echo "Help you create redis cluster easily!"
   echo ""
   echo "Usage: ./create-cluster.sh <ip> <ports>"
   echo ""
   echo "Note:"
   echo "  - At least 6 ports"
   echo "  - The number of ports must be even"
   echo ""
   echo "Example":
   echo "  ./create-cluster.sh 127.0.0.1 7001,7002,7003,7004,7005,7006"
   echo ""
}

if (( ${#ip} < 7 || ${#ports} <= 2 )); then
   help
   exit 1
fi

array=(${ports//,/ })
port_len=${#array[@]}

if (( $[${port_len}%2] == 1 || $[${port_len}%2] < 6 )); then
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

if ( [ -d "./redis" ] && [ ! -f ./redis/src/redis-cli ] );then
  rm -rf redis
fi

if [ ! -d "./redis" ];then
   echo "unzip redis.tar.gz ..."
   tar -zxf redis-5.0.4.tar.gz
   echo "unzip finished!"
   mv redis-5.0.4 redis
   cd redis
   echo "compile redis ..."
   make install > /dev/null
   cd ..

   if [ -f "./redis/src/redis-cli" ]; then
       echo "Redis compile success!"
   else
       echo "Redis compile error!"
       exit 1
   fi
fi

if [ -d "./config" ]; then
  rm -rf ./config
fi

if [ -d "./data" ]; then
  rm -rf ./data
fi

mkdir config
mkdir data

for port in ${array[@]}
do
  echo -e "port ${port}\ndaemonize yes\ndir \"./data\"\nlogfile \"${port}.log\"\ndbfilename \"dump-${port}.rdb\"\ncluster-enabled yes\ncluster-config-file nodes-${port}.conf\ncluster-require-full-coverage no\nprotected-mode no\nbind ${ip}" > ./config/redis-${port}.conf

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

echo yes | ./redis/src/redis-cli --cluster create ${temp_str} --cluster-replicas 1

echo Finish!

for((i=1;i<=5;i++));
do
  sleep 1s
  echo -n .
done

echo 
echo ---------------------------------------------------------------
echo 
./redis/src/redis-cli -h ${ip} -p ${array[0]} cluster nodes

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
