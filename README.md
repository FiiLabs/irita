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



3.启动四节点本地测试网


bash `./scripts/four_validators_local.sh`

4.  启动4节点正式网

在本地不启动节点，只生成配置

```bash
./scripts/four_validators_local.sh "local" "genconfig"
```

把本地生成的Keys所保存在的目录，拷贝到4台validators的服务器上

```bash
scp -r $HOME/.irita ubuntu@server-ip:/home/ubuntu
```

把irita指定的--home目录拷贝到对应云服务器上

```bash
scp -r ./testnet ubuntu@server-ip:/home/ubuntu
```

依次启动validators

```bash
docker run -d -p26657:26657 -p26656:26656 --mount type=bind,source=$PWD/testnet,target=/home --mount type=bind,source=$HOME/.irita,target=/root/.irita --name "node0" mathxh/fiilabs irita start --pruning=nothing --home=/home/node0

docker run -d -p26657:26657 -p26656:26656 --mount type=bind,source=$PWD/testnet,target=/home --mount type=bind,source=$HOME/.irita,target=/root/.irita --name "node1" mathxh/fiilabs irita start --pruning=nothing --home=/home/node1 --rpc.laddr=tcp://0.0.0.0:26657 --p2p.laddr=tcp://0.0.0.0:26656

docker run -d -p26657:26657 -p26656:26656 --mount type=bind,source=$PWD/testnet,target=/home --mount type=bind,source=$HOME/.irita,target=/root/.irita --name "node2" mathxh/fiilabs irita start --pruning=nothing --home=/home/node2 --rpc.laddr=tcp://0.0.0.0:26657 --p2p.laddr=tcp://0.0.0.0:26656

docker run -d -p26657:26657 -p26656:26656 --mount type=bind,source=$PWD/testnet,target=/home --mount type=bind,source=$HOME/.irita,target=/root/.irita --name "node3" mathxh/fiilabs irita start --pruning=nothing --home=/home/node3 --rpc.laddr=tcp://0.0.0.0:26657 --p2p.laddr=tcp://0.0.0.0:26656
```


