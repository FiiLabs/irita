6. 环境要求：
go

​       openssl



​	安装openssl，如下命令

​     git clone -b openssl-3.0.0-alpha4 https://github.com/openssl/openssl.git

​      cd openssl && ./config



​      sudo make install



3.安装 jq(https://stedolan.github.io/jq/download/), 以及sed命令



编译运行节点



1.编译源码



make build



2.启动单节点本地测试网（自动启动节点）



bash ./scripts/single-node.sh



2.启动四节点本地测试网



打开第一个terminal, 运行bash ./scripts/four-node.sh



然后在这个terminal启动节点1



./build/irita start  --pruning=nothing --home=./testnet/node0



打开第二个terminal,运行 bash ./scripts/four_last.sh



打开第三个terminal,启动节点2，



./build/irita start  --pruning=nothing --home=./testnet/node1 --rpc.laddr=tcp://0.0.0.0:36657 --p2p.laddr=tcp://0.0.0.0:36656



打开第四个terminal,启动节点3，



./build/irita start  --pruning=nothing --home=./testnet/node2 --rpc.laddr=tcp://0.0.0.0:46657 --p2p.laddr=tcp://0.0.0.0:46656



打开第五个terminal,启动节点4，



./build/irita start  --pruning=nothing --home=./testnet/node3 --rpc.laddr=tcp://0.0.0.0:56657 --p2p.laddr=tcp://0.0.0.0:56656

