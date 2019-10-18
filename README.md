# 快速在本地Linux虚拟机搭建redis集群

    $ git clone https://github.com/IndustriousSnail/create-local-redis-cluster-easily.git
    $ cd create-local-redis-cluster-easily
    $ chmod +x create-cluster.sh
    $ ./create-cluster.sh 127.0.0.1 7001,7002,7003,7004,7005,7006

    
# 说明

- 端口需要用逗号进行分割
- 端口必须为双数，每个端口代表一个节点，前面的为master，后面的为slave
- 端口至少填6个，也就是至少三主三从

    
    
# 注意：

- 本项目假设Linux已经具备了编译redis的环境，如gcc等。

- 如果虚拟机外部需要连接Redis集群，请不要使用127.0.0.1，而是虚拟机IP，原因可以参考

    https://blog.csdn.net/zhaohongfei_358/article/details/100584158
       
    

# 最后输出这个说明安装成功

    [OK] All nodes agree about slots configuration.
    >>> Check for open slots...
    >>> Check slots coverage...
    [OK] All 16384 slots covered.
    Finish!
    
    ---------------------------------------------------------------
    
    825b64426cb892a21938dc4d9e0e87405153cb3b 127.0.0.1:7004@17004 slave abe27c60f851b68b78b08c43bb27a1e6047c075d 0 1571336785425 4 connected
    92c3b0da747bd095ac6e73635533aab6cea6dd07 127.0.0.1:7006@17006 slave 36744ffc8c0afdf0f92d51baa605dd969eaa153d 0 1571336786434 6 connected
    6236270ccd29bb4907de4abe2d72418f1b605947 127.0.0.1:7002@17002 master - 0 1571336785000 2 connected 5461-10922
    47c77199d7e2a1d659c22044d947fa567129f68d 127.0.0.1:7005@17005 slave 6236270ccd29bb4907de4abe2d72418f1b605947 1571336787443 1571336784412 5 connected
    abe27c60f851b68b78b08c43bb27a1e6047c075d 127.0.0.1:7001@17001 myself,master - 0 1571336786000 1 connected 0-5460
    36744ffc8c0afdf0f92d51baa605dd969eaa153d 127.0.0.1:7003@17003 master - 0 1571336784000 3 connected 10923-16383    
    
# TODO

- [ ] 检测gcc等环境