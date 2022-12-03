## How to build

这个遵循官方文档编译构建就可以了

安装：

```bash
make install
```

构建:

```bash
make -B build
```

注意，`make build-linux` 会出错，是因为一个命令行工具没有安装，这个命令行是生成swagger文档的，暂时没用。

生成的binary在`build` 目录下面。

## 版本

```bash
./irita version --long
```

```txt
name: irita
server_name: irita
version: 3.2.4-wenchangchain
commit: 68839fe86b4319184ade1416a453b63eb64319d5
build_tags: netgo,ledger
go: go version go1.19.3 linux/amd64
```

## 命令行探索

### query

可以大概看到有这么多的模块:

```bash
./irita query --help
```

```txt
  account                  Query for account by address
  auth                     Querying commands for the auth module
  bank                     Querying commands for the bank module
  block                    Get verified data for a the block at given height
  evidence                 Query for evidence by hash or for all (paginated) submitted evidence
  evm                      Querying commands for the evm module
  feegrant                 Querying commands for the feegrant module
  feemarket                Querying commands for the fee market module
  identity                 Querying commands for the identity module
  mt                       Querying commands for the MT module
  nft                      Querying commands for the NFT module
  node                     Querying commands for the node module
  opb                      Querying commands for the OPB module
  oracle                   Querying commands for the oracle module
  params                   Querying commands for the params module
  perm                     Querying commands for the perm module
  random                   Querying commands for the random module
  record                   Querying commands for the record module
  service                  Querying commands for the service module
  slashing                 Querying commands for the slashing module
  tendermint-validator-set Get the full tendermint validator set at given height
  tibc                     Querying commands for the TIBC module
  tibc-mt-transfer         TIBC multi token transfer query subcommands
  tibc-nft-transfer        TIBC non fungible token transfer query subcommands
  token                    Querying commands for the token module
  tx                       Query for a transaction by hash, "<addr>/<seq>" combination or comma-separated signatures in a committed block
  txs                      Query for paginated transactions that match a set of events
  upgrade                  Querying commands for the upgrade module
  wasm                     Querying commands for the wasm module
```

后面重点关注 `nft` `tibc` `tibc-nft-transfer`  

## Deploy

选择单validator节点本地网络部署

```bash
sudo apt install jq
```

因为使用了国密`sm2` 算法，所以涉及的openSSL工具必须使用sm2算法的版本，当然，OpenSSL是支持国密的。

我本机的是:

```txt
mathxh@MathxH:~/metablock-projects/irita$ openssl version -a
OpenSSL 1.1.1f  31 Mar 2020
built on: Mon Jul  4 11:24:28 2022 UTC
platform: debian-amd64
options:  bn(64,64) rc4(16x,int) des(int) blowfish(ptr) 
compiler: gcc -fPIC -pthread -m64 -Wa,--noexecstack -Wall -Wa,--noexecstack -g -O2 -fdebug-prefix-map=/build/openssl-51ig8V/openssl-1.1.1f=. -fstack-protector-strong -Wformat -Werror=format-security -DOPENSSL_TLS_SECURITY_LEVEL=2 -DOPENSSL_USE_NODELETE -DL_ENDIAN -DOPENSSL_PIC -DOPENSSL_CPUID_OBJ -DOPENSSL_IA32_SSE2 -DOPENSSL_BN_ASM_MONT -DOPENSSL_BN_ASM_MONT5 -DOPENSSL_BN_ASM_GF2m -DSHA1_ASM -DSHA256_ASM -DSHA512_ASM -DKECCAK1600_ASM -DRC4_ASM -DMD5_ASM -DAESNI_ASM -DVPAES_ASM -DGHASH_ASM -DECP_NISTZ256_ASM -DX25519_ASM -DPOLY1305_ASM -DNDEBUG -Wdate-time -D_FORTIFY_SOURCE=2
OPENSSLDIR: "/usr/lib/ssl"
ENGINESDIR: "/usr/lib/x86_64-linux-gnu/engines-1.1"
Seeding source: os-specific
```

需要手动编译安装

```bash
git clone -b openssl-3.0.0-alpha4 https://github.com/openssl/openssl.git
cd openssl && ./config
sudo make install
```

开始初始化设置并部署

```bash
# 初始化 genesis.json 文件
irita init node0 --chain-id=irita-test --home=testnet

# 创建一个初始化账户mathxh
irita keys add mathxh

# 将 mathxh 添加到 genesis.json 文件，并为该账户添加'RootAdmin'权限
irita add-genesis-account $(irita keys show mathxh -a) 1000000000point --home=testnet --root-admin

# 导出validator节点 node0（步骤1生成的）私钥为 pem 格式，方便用于申请节点证书
irita genkey --home=testnet --out-file priv_validator.pem
# OR 普通节点（目前这里用不到）
irita genkey --type node --out-file=<output-file> --home=testnet

# 生成证书请求文件 如果OpenSSL不支持sm3，就会报错，所要自己编译安装OpenSSL支持国密的版本, 自己编译的OpenSSL默认安装在 /usr/local/bin/openssl
openssl req -new -key priv_validator.pem -out req.csr -sm3 -sigopt "distid:1234567812345678"
openssl req -in req.csr -text

##生成根证书秘钥
openssl ecparam -genkey -name SM2 -out root.key
##生成根证书
openssl req -new -x509 -sm3 -sigopt "distid:1234567812345678" -key root.key -out root.crt -days 365
openssl x509 -in root.crt --text

# 自签
openssl x509 -req -in req.csr -out node0.crt -sm3 -sigopt "distid:1234567812345678" -vfyopt "distid:1234567812345678" -CA root.crt -CAkey root.key -CAcreateserial

# 导入 IRITA 网络的企业根证书(需要先获取根证书)
irita set-root-cert root.crt --home=testnet

# 添加 node0 到 genesis.json 文件  这里会报错 Error: node0.info: key not found，https://github.com/bianjieai/irita/issues/188
irita add-genesis-validator --name node0 --cert node0.crt --power 100 --home=testnet --from node0

# 启动
irita start --home=testnet --pruning=nothing

```

可以简化:

```bash
# 会自动配置节点证书和根证书, 如果OpenSSL不支持sm3，就会报错，所要自己编译安装OpenSSL支持国密的版本
irita testnet --v 1 --output-dir ./testnet --chain-id=test --keyring-backend test
irita start --home=testnet/node0/irita --pruning=nothing
```

```txt
139763058574656:error:100C508A:elliptic curve routines:pkey_ec_ctrl:invalid digest type:../crypto/ec/ec_pmeth.c:331:
```

以上错误，解决方案就是自己编译openSSL版本

```txt
openssl: error while loading shared libraries: libssl.so.3: cannot open shared object file: No such file or directory
```

以上错误， 解决方案就是`sudo ldconfig /usr/local/lib64` https://stackoverflow.com/questions/54124906/openssl-error-while-loading-shared-libraries-libssl-so-3 

## TroubleShooting

之前用Docker compose运行4 validators的本地节点网络，节点内部的`crisis`模块的日志报出 `keeper.Keeper.AssetInvariants`的错误，

还提示:

```txt
CRITICAL please submit the following transaction:
   tx crisis invariant-borken bank total-supply
```

然后我发现了是SDK的这个模块的BUG，但是没追究其原因，我又看了下，感觉`go.mod`里面的sdk版本是包含了这些Fixs的。但是我本机，不在容器里面编译
就可以在ubuntu 20.04的环境里面运行，所以我把Dockerfile里面的golang版本和ubuntu的版本都升级到跟我本机编译开发环境保持一致，

最后运行docker compose的时候，节点就没有报错了，并且4个validators节点正常出块，并且同一高度的block的hash是一致的。

其实Dockerfile还可以优化，直接把golang的alpine Linux版本删除，在ubuntu上构建项目，他们文昌链为什么会这样做，用Alpine Linux编译，然后拷贝到
ubuntu上，是因为golang的官方Docker镜像就是推荐用Alpine Linux的镜像版本，而且他们想用musl编译项目，让irita的二进制全静态，不依赖任何动态库，所以
Dockerfile里面又要下载muslc的静态库.a文件之类的，搞得很烦人。其实完全不必这么麻烦，都容器运行了，动态静态无所谓，所以可以考虑改天优化掉。