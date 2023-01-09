#!/usr/bin/env bash

# How to use this script: ./script/prod/four_validators_local.sh <docker | local> <genconfig>
# docker: run docker container
# local: run metaosd directly
# genconfig: only generate config Home directory

Home=./testnet
HomeUserPath=$HOME
ChainID=testnet # chain-id
ChainCMD="irita"
NodeName=metaos-node # node name
NodeIP=(tcp://127.0.0.1 tcp://127.0.0.1 tcp://127.0.0.1 tcp://127.0.0.1)
NodeNames=("node0" "node1" "node2" "node3")
NodeDic=("${Home}/node0" "${Home}/node1" "${Home}/node2" "${Home}/node3")
Mnemonics=("eagle marriage host height topple sorry exist nation screen affair bulk average medal flush candy alert amused alone hire clerk treat hybrid tip cake"
"width clap suspect squeeze rich exact lawn output play blanket join join measure charge they sword wheat light federal review true portion add rival"
"satisfy web truck wink canal use decrease glove glow skill always script differ speed eternal close today slow grass disorder robot match face consider"
"assist cute perfect during kiwi vacant marble happy smooth now isolate social birth maid just mixture federal pause ridge midnight picture cattle document inner"
"setup capital exact dad minimum pigeon blush claw cake find animal torch cry guide dirt settle parade host grief lunar indicate laptop bulk cherry"
)
Validators=("validator0" "validator1" "validator2" "validator3")
IpPorts=(tcp://127.0.0.1:26657 tcp://127.0.0.1:36657 tcp://127.0.0.1:46657 tcp://127.0.0.1:56657)
Stake=uirita
TotalStake=10000000000000000${Stake} # total stake in genesis
SendStake=10000000000000${Stake}

Point=upoint
PointOwner=iaa1g6gqr3s58dhw3jq5hm95qrng0sa9um7gavevjc # replace with actual address, this is admin address
PointToken="{\"symbol\": \"point\", \"name\": \"Irita point native token\", \"scale\": 6, \"min_unit\": \"upoint\", \"initial_supply\": \"1000000000\", \"max_supply\": \"1000000000000\", \"mintable\": true, \"owner\": \"${PointOwner}\"}"
Password=12345678
# https://docs.cosmos.network/v0.46/run-node/keyring.html
KeyRingBackEndType="file"
DockerFlag=$1
GenConfigFlag=$2
DockerImageName="mathxh/bianjieai"


rm -rf "$Home"

$ChainCMD config keyring-backend $KeyRingBackEndType

echo -e "${Password}" | $ChainCMD keys delete admin -y --keyring-backend $KeyRingBackEndType
# delete all validators related keys and docker container names
for i in {0..3}; do  
   echo -e "${Password}" | $ChainCMD keys delete "${Validators[$i]}" -y  --keyring-backend $KeyRingBackEndType;
   if [ "$DockerFlag" == "docker" ]; then
      docker container rm "${NodeNames[$i]}";
   fi
done

# Add related accounts
echo "please input Mnemonics: ${Mnemonics[4]}"
${ChainCMD} keys add admin --recover  --keyring-backend $KeyRingBackEndType
# (echo "setup capital exact dad minimum pigeon blush claw cake find animal torch cry guide dirt settle parade host grief lunar indicate laptop bulk cherry"; echo "12345678", echo "12345678") | sudo -E metaosd keys add admin --recover
# (echo "12345678"; echo "12345678") | sudo -E metaosd keys add admin

for i in {0..3}; do
   echo "please input Mnemonics: ${Mnemonics[$i]}";
   ${ChainCMD} keys add "${Validators[$i]}" --recover  --keyring-backend $KeyRingBackEndType;
done

# for generating a temaplate genesis.json for change it and copy
$ChainCMD init moniker --chain-id $ChainID --home=$Home

for i in {0..3}; do
   $ChainCMD init moniker --chain-id $ChainID --home="${NodeDic[$i]}";
   # validator key
   $ChainCMD genkey --out-file "${NodeDic[$i]}/priv_validator.pem" --home="${NodeDic[$i]}";
   # node key
   $ChainCMD genkey --type node --out-file "${NodeDic[$i]}/priv_node.pem" --home="${NodeDic[$i]}";
done

# Change genesis.json (https://hub.cosmos.network/main/resources/genesis.html) and config.toml
sed -i 's/127.0.0.1:26657/0.0.0.0:26657/g' $Home/config/config.toml
sed -i 's/addr_book_strict = true/addr_book_strict = false/' $Home/config/config.toml
sed -i 's/timeout_commit = "5s"/timeout_commit = "2s"/' $Home/config/config.toml
sed -i 's/allow_duplicate_ip = false/allow_duplicate_ip = true/' $Home/config/config.toml
sed -i 's/minimum-gas-prices = ""/minimum-gas-prices = "1uirita"/' $Home/config/app.toml
#sed -i 's/filter_peers = false/filter_peers = true/' $Home/config/config.toml
sed -i "s/stake/$Stake/g" $Home/config/genesis.json
sed -i "s/\"point_token_denom\": \"$Stake\"/\"point_token_denom\": \"$Point\"/g" $Home/config/genesis.json
sed -i "s/node0token/$Point/g" $Home/config/genesis.json
sed -i "s/\"base_denom\": \"$Stake\"/\"base_denom\": \"$Point\"/g" $Home/config/genesis.json
sed -i "s/\"restricted_service_fee_denom\": false/\"restricted_service_fee_denom\": true/g" $Home/config/genesis.json
cat $Home/config/genesis.json | jq ".app_state.service.params.min_deposit[0].denom = \"$Point\"" > $Home/temp; cat $Home/temp; cp -f $Home/temp $Home/config/genesis.json
cat $Home/config/genesis.json | jq ".app_state.token.tokens |= . + [$PointToken]" > $Home/temp; cat $Home/temp; cp -f $Home/temp $Home/config/genesis.json
validator0_address=$($ChainCMD keys show validator0 -a --keyring-backend $KeyRingBackEndType)
sed -i "s/\"base_token_manager\": \"\"/\"base_token_manager\": \"${validator0_address}\"/" $Home/config/genesis.json
sed -i "s/\"token_tax_rate\": \"0.400000000000000000\"/\"token_tax_rate\": \"1\"/g" $Home/config/genesis.json
sed -i "s/\"denom\": \"irita\"/\"denom\": \"point\"/g" $Home/config/genesis.json
sed -i "s/\"amount\": \"60000000000\"/\"amount\": \"60000\"/g" $Home/config/genesis.json
sed -i "s/\"amount\": \"1000000000\"/\"amount\": \"1000000000000000\"/g" $Home/config/genesis.json
sed -i "s/\"amount\": \"500000000\"/\"amount\": \"1000000000000000\"/g" $Home/config/genesis.json
sed -i "s/\"amount\": \"1000\"/\"amount\": \"1000000000\"/g" $Home/config/genesis.json
sed -i "s/\"amount\": \"5000\"/\"amount\": \"5000000000\"/g" $Home/config/genesis.json
sed -i "s/nodes\": \[/nodes\": \[{\"id\": \"$($ChainCMD tendermint show-node-id --home=$Home)\", \"name\": \"$NodeName\"}/" $Home/config/genesis.json

validator0_address=$($ChainCMD keys show validator0 -a --home="${NodeDic[0]}" --keyring-backend $KeyRingBackEndType)
$ChainCMD add-genesis-account "${validator0_address}" ${TotalStake} --root-admin --home=$Home --keyring-backend $KeyRingBackEndType
PointOwner=$($ChainCMD keys show admin -a --keyring-backend $KeyRingBackEndType)
$ChainCMD add-genesis-account "${PointOwner}" 1000000000000000${Point} --home=$Home --keyring-backend $KeyRingBackEndType

## generate root.key and root.crt
openssl ecparam -genkey -name SM2 -out $Home/root.key
echo -e "CN\nSH\nSH\nIT\nDEV\n'${NodeNames[0]}'\n\n" | openssl req -new -x509 -sm3 -sigopt "distid:1234567812345678" -key $Home/root.key -out $Home/root.crt -days 3650
# set root cert
$ChainCMD set-root-cert $Home/root.crt --home=$Home

for i in {0..3}; do
    # generate validator.crt
    echo -e "CN\nSH\nSH\nIT\nDEV\n'${NodeNames[$i]}'\n\n\n\n" | openssl req -new -key "${NodeDic[$i]}/priv_validator.pem" -out "${NodeDic[$i]}/validator_req.csr" -sm3 -sigopt "distid:1234567812345678";
    openssl x509 -req -in "${NodeDic[$i]}/validator_req.csr" -out "${NodeDic[$i]}/validator.crt" -sm3 -sigopt "distid:1234567812345678" -vfyopt "distid:1234567812345678" -CA $Home/root.crt -CAkey $Home/root.key -CAcreateserial;
    # gernate node.crt
    echo -e "CN\nSH\nSH\nIT\nDEV\n'${NodeNames[$i]}'\n\n\n\n" | openssl req -new -key "${NodeDic[$i]}/priv_node.pem" -out "${NodeDic[$i]}/node_req.csr" -sm3 -sigopt "distid:1234567812345678";
    openssl x509 -req -in "${NodeDic[$i]}/node_req.csr" -out "${NodeDic[$i]}/node.crt" -sm3 -sigopt "distid:1234567812345678" -vfyopt "distid:1234567812345678" -CA $Home/root.crt -CAkey $Home/root.key -CAcreateserial;
done

# set node0 is genesis validator(first validator)
echo ${Password} | $ChainCMD add-genesis-validator --name ${NodeNames[0]} --cert "${NodeDic[0]}/validator.crt" --power 10000 --from validator0 --home=$Home --keyring-backend $KeyRingBackEndType

#sed -i "s/persistent_peers = \"\"/persistent_peers = \"$($ChainCMD tendermint show-node-id --home=${NodeDic[0]} | sed 's/\^M\$//')@`echo ${NodeIP[0]} | awk -F // '{print $2}'`:26656,$($ChainCMD tendermint show-node-id --home=${NodeDic[1]} | sed 's/\^M\$//')@`echo ${NodeIP[0]} | awk -F // '{print $2}'`:36656,$($ChainCMD tendermint show-node-id --home=${NodeDic[2]} | sed 's/\^M\$//')@`echo ${NodeIP[0]} | awk -F // '{print $2}'`:46656,$($ChainCMD tendermint show-node-id --home=${NodeDic[3]} | sed 's/\^M\$//')@`echo ${NodeIP[0]} | awk -F // '{print $2}'`:56656\"/" $Home/config/config.toml
sed -i "s/persistent_peers = \"\"/persistent_peers = \"$($ChainCMD tendermint show-node-id --home="${NodeDic[0]}" | sed 's/\^M\$//')@`echo "${NodeIP[0]}" | awk -F // '{print $2}'`:26656\"/" $Home/config/config.toml

for i in {0..3}; do
   echo "node ${NodeDic[0]} id is";
   $ChainCMD tendermint show-node-id --home="${NodeDic[0]}" | sed 's/\^M\$//';
done

# Copy config files unerder folder config to other nodes
for i in {0..3}; do
    cp "$Home/config/config.toml" "${NodeDic[$i]}/config";
    cp "$Home/config/genesis.json" "${NodeDic[$i]}/config";
    cp "$Home/config/app.toml" "${NodeDic[$i]}/config";
done

# Change validator 1 - 3's config files
for i in {1..3}; do
    port_prefix=$(($i + 2))
    
    echo "port prefix is ${port_prefix} for ${NodeDic[$i]}"
    echo "sed -i replacing s/address = \"tcp:\/\/0.0.0.0:1317\"/address = \"tcp:\/\/0.0.0.0:${port_prefix}1317\"/"
    
    # app.toml is generated by cosmos sdk, it used to configure your app, such as state pruning strategies, telemetry, gRPC and REST servers configuration, state sync...
    sed -i "s/address = \"tcp:\/\/0.0.0.0:1317\"/address = \"tcp:\/\/0.0.0.0:${port_prefix}1317\"/" ${NodeDic[$i]}/config/app.toml
    sed -i "s/address = \":8080\"/address = \":${port_prefix}8080\"/" ${NodeDic[$i]}/config/app.toml
    sed -i "s/address = \"0.0.0.0:9090\"/address = \"0.0.0.0:${port_prefix}9090\"/" ${NodeDic[$i]}/config/app.toml
    sed -i "s/address = \"0.0.0.0:9091\"/address = \"0.0.0.0:${port_prefix}9091\"/" ${NodeDic[$i]}/config/app.toml
    sed -i "s/address = \"0.0.0.0:8545\"/address = \"0.0.0.0:${port_prefix}8545\"/" ${NodeDic[$i]}/config/app.toml
    sed -i "s/ws-address = \"0.0.0.0:8546\"/ws-address = \"0.0.0.0:${port_prefix}8546\"/" ${NodeDic[$i]}/config/app.toml

    # config.toml is generated by tendermint , it used to configure the Tendermint
    sed -i "s/proxy_app = \"tcp:\/\/127.0.0.1:26658\"/proxy_app = \"tcp:\/\/127.0.0.1:${port_prefix}6658\"/" ${NodeDic[$i]}/config/config.toml
    sed -i "s/laddr = \"tcp:\/\/0.0.0.0:26657\"/proxy_app = \"tcp:\/\/0.0.0.0:${port_prefix}6657\"/" ${NodeDic[$i]}/config/config.toml
    sed -i "s/pprof_laddr = \"localhost:6060\"/pprof_laddr = \"localhost:${port_prefix}6060\"/" ${NodeDic[$i]}/config/config.toml
    sed -i "s/laddr = \"tcp:\/\/0.0.0.0:26656\"/pprof_laddr = \"tcp:\/\/0.0.0.0:${port_prefix}6656\"/" ${NodeDic[$i]}/config/config.toml
    sed -i "s/prometheus_listen_addr = \":26660\"/prometheus_listen_addr = \":${port_prefix}6660\"/" ${NodeDic[$i]}/config/config.toml
done

# start node 0
# cosmos sdk no logger https://github.com/cosmos/cosmos-sdk/issues/5050
# node0 endPoints
# Tendermint config
# gRPC server port 26657
# pprof server port 6060
# p2p port 26656
#-----------------------------------------
# cosmos sdk config
# REST API server port 1317
# gRPC server port 9090
# gRPC web port 9091
# JSON-RPC server port 8545 / JSON-RPC ws port 8546
if [ "$DockerFlag" == "docker" ]; then
   docker run -d -p26657:26657 -p26656:26656 --mount type=bind,source=$PWD/testnet,target=/home --mount type=bind,source=$HomeUserPath/.metaos,target=/root/.metaos --name ${NodeNames[0]} ${DockerImageName} metaos start --pruning=nothing --home=/home/${NodeNames[0]}
   echo "container node0 started"
else
   # start node 0
   # cosmos sdk no logger https://github.com/cosmos/cosmos-sdk/issues/5050
   metaos start  --pruning=nothing --home ${NodeDic[0]} > ${NodeDic[0]}/node.log  2>&1 &
   echo "node0 started"
fi
sleep 10

# Join validators from node 1 - 3
sequence=0
for i in {1..3}; do
   echo -e "processing join validator name is ${Validators[$i]}\n"
   address=$(bash -c "echo ${Password} | ${ChainCMD} keys show ${Validators[$i]} --home=${NodeDic[0]} --keyring-backend $KeyRingBackEndType | grep address" | awk '{print $2}');
   echo -e "validator addr is ${address}\n"
   bash -c "echo -e \"${Password}\n${Password}\" | ${ChainCMD} tx bank send validator0 \$(echo $address  | sed 's/\\^M\\$//') ${SendStake} --chain-id $ChainID -y --home=${NodeDic[0]} --keyring-backend $KeyRingBackEndType -s ${sequence}";
   sequence=$((sequence+1))
   sleep 2
   bash -c "${ChainCMD} q bank balances \$(echo $address | sed 's/\\^M\\$//') --chain-id $ChainID --home=${NodeDic[0]}";
   bash -c "echo -e \"${Password}\n${Password}\" | ${ChainCMD} tx perm assign-roles --from validator0 \$(echo $address | sed 's/\\^M\\$//') NODE_ADMIN --chain-id $ChainID -y --home=${NodeDic[0]} --keyring-backend $KeyRingBackEndType -s ${sequence}";
   sequence=$((sequence+1))
   sleep 2
   bash -c "${ChainCMD} q perm roles \$(echo $address  | sed 's/\\^M\\$//') --chain-id $ChainID --home=${NodeDic[0]}";
   bash -c "echo -e \"${Password}\n${Password}\" | ${ChainCMD} tx node grant --name \"${NodeNames[$i]}\" --cert ${NodeDic[$i]}/node.crt --from validator0 --chain-id $ChainID -b block -y --home=${NodeDic[0]} --keyring-backend $KeyRingBackEndType -s ${sequence}";
   sequence=$((sequence+1))
   sleep 2
   bash -c "echo ${Password} | ${ChainCMD} keys show ${Validators[$i]} --home=${NodeDic[0]} --keyring-backend $KeyRingBackEndType"
   bash -c "echo -e \"${Password}\n${Password}\" | ${ChainCMD} tx node create-validator --name \"${NodeNames[$i]}\" --from validator0 --cert ${NodeDic[$i]}/validator.crt --power 100 --chain-id $ChainID --node=${IpPorts[0]} -y --home=${NodeDic[0]} --keyring-backend $KeyRingBackEndType -s ${sequence}";
   sequence=$((sequence+1))
   sleep 2
done

if [ "$GenConfigFlag" == "genconfig" ]; then
   sudo pkill -f metaos
   c=$(docker ps -q) && [[ $c ]] && docker kill $c
   echo "all config of four validators generate finished"
fi


# node1 endPoints
# Tendermint config
# gRPC server port 36657
# pprof server port 36060
# p2p port 36656
#-----------------------------------------
# cosmos sdk config
# REST API server port 31317
# gRPC server port 39090
# gRPC web port 39091
# JSON-RPC server port 38545 / JSON-RPC ws port 38546

# node2 endPoints
# Tendermint config
# gRPC server port 46657
# pprof server port 46060
# p2p port 46656
#-----------------------------------------
# cosmos sdk config
# REST API server port 41317
# gRPC server port 49090
# gRPC web port 49091
# JSON-RPC server port 48545 / JSON-RPC ws port 48546

# node3 endPoints
# Tendermint config
# gRPC server port 56657
# pprof server port 56060
# p2p port 56656
#-----------------------------------------
# cosmos sdk config
# REST API server port 51317
# gRPC server port 59090
# gRPC web port 59091
# JSON-RPC server port 58545 / JSON-RPC ws port 58546
# start node 1 - 3
if [ "$GenConfigFlag" != "genconfig" ]; then
   for i in {1..3}; do
      port_prefix=$(($i + 2))
      if [ "$DockerFlag" == "docker" ]; then
         docker run -d -p${port_prefix}6657:26657 -p${port_prefix}6656:26656 --mount type=bind,source=$PWD/testnet,target=/home --mount type=bind,source=$HomeUserPath/.metaos,target=/root/.metaos --name ${NodeNames[$i]} ${DockerImageName} metaos start --pruning=nothing --home=/home/${NodeNames[$i]} --rpc.laddr=tcp://0.0.0.0:26657 --p2p.laddr=tcp://0.0.0.0:26656
         echo "container ${NodeNames[$i]} started"
      else
         metaos start  --pruning=nothing --home=${NodeDic[$i]} --rpc.laddr="tcp://0.0.0.0:${port_prefix}6657" --p2p.laddr="tcp://0.0.0.0:${port_prefix}6656" > ${NodeDic[$i]}/node.log 2>&1 &
         echo "${NodeNames[$i]} started"
      fi
   done
   echo "All started Finished"
fi
