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

先登录要部署node0(validator0)的节点云服务器

运行

```bash
./scripts/four_validators_local.sh "docker"
```

运行这个命令以后，你用docker ps会看到node0 - node3的四个容器启动，相应的数据和配置都已经生成在testnet目录底下。手动docker kill node1-node3的容器，因为用不到。

把在node0所在的服务器的Keys所保存在的目录，和--home指定的testnet目录下的数据 拷贝到剩下的3台要部署的validator1-validator3的服务器上

```bash
scp -r $HOME/.irita ubuntu@server-ip:/home/ubuntu
sudo -E scp -r ./testnet ubuntu@server-ip:/home/ubuntu
```

分别登录到node1到node3的云服务器上，依次修改其tendermint的`config.toml`文件的配置

并用docker启动validators1-validator3

```bash
# 替换这个字段的值，确保ID是validator0的ID，并且IP和端口指向node0的26656端口 persistent_peers = "102ef69152b239e1c9cbb08bcdf2c71c63d220f7@1.14.72.3:26656"
vim ~/testnet/node1/config/config.toml
docker run -d -p26657:26657 -p26656:26656 --mount type=bind,source=$PWD/testnet,target=/home --mount type=bind,source=$HOME/.irita,target=/root/.irita --name "node1" mathxh/fiilabs irita start --pruning=nothing --home=/home/node1 --rpc.laddr=tcp://0.0.0.0:26657 --p2p.laddr=tcp://0.0.0.0:26656

# 替换这个字段的值，确保ID是validator0的ID，并且IP和端口指向node0的26656端口 persistent_peers = "102ef69152b239e1c9cbb08bcdf2c71c63d220f7@1.14.72.3:26656"
vim ~/testnet/node2/config/config.toml
docker run -d -p26657:26657 -p26656:26656 --mount type=bind,source=$PWD/testnet,target=/home --mount type=bind,source=$HOME/.irita,target=/root/.irita --name "node2" mathxh/fiilabs irita start --pruning=nothing --home=/home/node2 --rpc.laddr=tcp://0.0.0.0:26657 --p2p.laddr=tcp://0.0.0.0:26656

# 替换这个字段的值，确保ID是validator0的ID，并且IP和端口指向node0的26656端口 persistent_peers = "102ef69152b239e1c9cbb08bcdf2c71c63d220f7@1.14.72.3:26656"
vim ~/testnet/node3/config/config.toml
docker run -d -p26657:26657 -p26656:26656 --mount type=bind,source=$PWD/testnet,target=/home --mount type=bind,source=$HOME/.irita,target=/root/.irita --name "node3" mathxh/fiilabs irita start --pruning=nothing --home=/home/node3 --rpc.laddr=tcp://0.0.0.0:26657 --p2p.laddr=tcp://0.0.0.0:26656
```


