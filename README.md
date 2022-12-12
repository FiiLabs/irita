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


bash `./scripts/four_validators_local.sh`
