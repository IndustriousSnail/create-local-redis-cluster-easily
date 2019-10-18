# 快速在本地Linux虚拟机搭建redis集群

    $ git clone https://github.com/IndustriousSnail/create-local-redis-cluster-easily.git
    $ cd create-local-redis-cluster-easily
    $ chmod +x create-cluster.sh
    $ ./create-cluster.sh 127.0.0.1 7001,7002,7003,7004,7005,7006
    
    
# 注意：

- 本项目假设Linux已经具备了编译redis的环境，如gcc等。

- 如果虚拟机外部需要连接Redis集群，请不要使用127.0.0.1，而是虚拟机IP，原因可以参考

    https://blog.csdn.net/zhaohongfei_358/article/details/100584158
    
# TODO

- [ ] 检测gcc等环境