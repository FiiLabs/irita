#!/bin/sh
Home=./testnet
ChainID=testnet # chain-id
ChainCMD=./build/irita
NodeName=irita-node # node name
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
Stake=uirita
TotalStake=10000000000000000${Stake} # total stake in genesis
SendStake=10000000000000${Stake}
DataPath=/tmp

Point=upoint
PointOwner=iaa1g6gqr3s58dhw3jq5hm95qrng0sa9um7gavevjc # replace with actual address
PointToken=`echo {\"symbol\": \"point\", \"name\": \"Irita point native token\", \"scale\": 6, \"min_unit\": \"upoint\", \"initial_supply\": \"1000000000\", \"max_supply\": \"1000000000000\", \"mintable\": true, \"owner\": \"${PointOwner}\"}`

$ChainCMD keys delete admin -y

for i in `seq 0 $[ ${#Validators[*]} -1 ]`; do $ChainCMD keys delete ${Validators[$i]} -y; done

bash -c "echo -e \"${Mnemonics[4]}\n12345678\n12345678\" | ${ChainCMD} keys add admin --recover --home=$Home"

for i in `seq 0 $[ ${#Validators[*]} -1 ]`; do bash -c "echo -e \"${Mnemonics[$i]}\n12345678\n12345678\" | ${ChainCMD} keys add ${Validators[$i]} --recover --home=${NodeDic[$i]}"; done

#for i in `seq 0 $[ ${#Validators[*]} -1 ]`; do mkdir ${NodeDic[$i]}; done
$ChainCMD init moniker --chain-id $ChainID --home=$Home
for i in `seq 0 $[ ${#Validators[*]} -1 ]`; do $ChainCMD init moniker --chain-id $ChainID --home=${NodeDic[$i]}; done
for i in `seq 0 $[ ${#Validators[*]} -1 ]`; do $ChainCMD genkey --out-file ${NodeDic[$i]}/priv_validator.pem --home=${NodeDic[$i]}; done
for i in `seq 0 $[ ${#Validators[*]} -1 ]`; do $ChainCMD genkey --type node --out-file ${NodeDic[$i]}/priv_node.pem --home=${NodeDic[$i]}; done


sed -i 's/127.0.0.1:26657/0.0.0.0:26657/g' $Home/config/config.toml

sed -i 's/addr_book_strict = true/addr_book_strict = false/' $Home/config/config.toml

sed -i 's/timeout_commit = "5s"/timeout_commit = "2s"/' $Home/config/config.toml

sed -i 's/minimum-gas-prices = ""/minimum-gas-prices = "1uirita"/' $Home/config/app.toml

sed -i 's/filter_peers = false/filter_peers = true/' $Home/config/config.toml

sed -i "s/stake/$Stake/g" $Home/config/genesis.json

sed -i "s/\"point_token_denom\": \"$Stake\"/\"point_token_denom\": \"$Point\"/g" $Home/config/genesis.json

sed -i "s/node0token/$Point/g" $Home/config/genesis.json

sed -i "s/\"base_denom\": \"$Stake\"/\"base_denom\": \"$Point\"/g" $Home/config/genesis.json

sed -i "s/\"restricted_service_fee_denom\": false/\"restricted_service_fee_denom\": true/g" $Home/config/genesis.json

cat $Home/config/genesis.json | jq ".app_state.service.params.min_deposit[0].denom = \"$Point\"" > $Home/temp; cat $Home/temp; cp -f $Home/temp $Home/config/genesis.json

cat $Home/config/genesis.json | jq ".app_state.token.tokens |= . + [$PointToken]" > $Home/temp; cat $Home/temp; cp -f $Home/temp $Home/config/genesis.json

sed -i "s/\"base_token_manager\": \"\"/\"base_token_manager\": \"$(echo 12345678 | $ChainCMD keys show validator0 | grep address | cut -b 12-)\"/" $Home/config/genesis.json

sed -i "s/\"token_tax_rate\": \"0.400000000000000000\"/\"token_tax_rate\": \"1\"/g" $Home/config/genesis.json

sed -i "s/\"denom\": \"irita\"/\"denom\": \"point\"/g" $Home/config/genesis.json

sed -i "s/\"amount\": \"60000000000\"/\"amount\": \"60000\"/g" $Home/config/genesis.json

sed -i "s/\"amount\": \"1000000000\"/\"amount\": \"1000000000000000\"/g" $Home/config/genesis.json

sed -i "s/\"amount\": \"500000000\"/\"amount\": \"1000000000000000\"/g" $Home/config/genesis.json

sed -i "s/\"amount\": \"1000\"/\"amount\": \"1000000000\"/g" $Home/config/genesis.json

sed -i "s/\"amount\": \"5000\"/\"amount\": \"5000000000\"/g" $Home/config/genesis.json

sed -i "s/nodes\": \[/nodes\": \[{\"id\": \"$($ChainCMD tendermint show-node-id --home=$Home)\", \"name\": \"$NodeName\"}/" $Home/config/genesis.json

bash -c "$ChainCMD add-genesis-account \$(echo 12345678 | $ChainCMD keys show validator0 -a --home=$Home) ${TotalStake} --root-admin --home=$Home"

bash -c "$ChainCMD add-genesis-account ${PointOwner} 1000000000000000${Point} --home=$Home"

openssl ecparam -genkey -name SM2 -out $Home/root.key

echo -e "CN\nSH\nSH\nIT\nDEV\n'${NodeNames[0]}'\n\n" | openssl req -new -x509 -sm3 -sigopt "distid:1234567812345678" -key $Home/root.key -out $Home/root.crt -days 3650

$ChainCMD set-root-cert $Home/root.crt --home=$Home


for i in `seq 0 $[ ${#Validators[*]} -1 ]`; do echo -e "CN\nSH\nSH\nIT\nDEV\n'${NodeNames[$i]}'\n\n\n\n" | openssl req -new -key ${NodeDic[$i]}/priv_validator.pem -out ${NodeDic[$i]}/validator_req.csr -sm3 -sigopt "distid:1234567812345678"; done

for i in `seq 0 $[ ${#Validators[*]} -1 ]`; do openssl x509 -req -in ${NodeDic[$i]}/validator_req.csr -out ${NodeDic[$i]}/validator.crt -sm3 -sigopt "distid:1234567812345678" -vfyopt "distid:1234567812345678" -CA $Home/root.crt -CAkey $Home/root.key -CAcreateserial; done

for i in `seq 0 $[ ${#Validators[*]} -1 ]`; do echo -e "CN\nSH\nSH\nIT\nDEV\n'${NodeNames[$i]}'\n\n\n\n" | openssl req -new -key ${NodeDic[$i]}/priv_node.pem -out ${NodeDic[$i]}/node_req.csr -sm3 -sigopt "distid:1234567812345678"; done

for i in `seq 0 $[ ${#Validators[*]} -1 ]`; do openssl x509 -req -in ${NodeDic[$i]}/node_req.csr -out ${NodeDic[$i]}/node.crt -sm3 -sigopt "distid:1234567812345678" -vfyopt "distid:1234567812345678" -CA $Home/root.crt -CAkey $Home/root.key -CAcreateserial; done

bash -c "echo 12345678 | $ChainCMD add-genesis-validator --name ${NodeNames[0]} --cert ${NodeDic[0]}/validator.crt --power 10000 --from validator0 --home=$Home"
#bash -c "echo 12345678 | $ChainCMD add-genesis-validator --name ${NodeNames[1]} --cert ${NodeDic[1]}/validator.crt --power 10000 --from validator1 --home=$Home"
#bash -c "echo 12345678 | $ChainCMD add-genesis-validator --name ${NodeNames[2]} --cert ${NodeDic[2]}/validator.crt --power 10000 --from validator2 --home=$Home"
#bash -c "echo 12345678 | $ChainCMD add-genesis-validator --name ${NodeNames[3]} --cert ${NodeDic[3]}/validator.crt --power 10000 --from validator3 --home=$Home"

#sed -i "s/persistent_peers = \"\"/persistent_peers = \"$($ChainCMD tendermint show-node-id --home=${NodeDic[0]} | sed 's/\^M\$//')@`echo ${NodeIP[0]} | awk -F // '{print $2}'`:26656,$($ChainCMD tendermint show-node-id --home=${NodeDic[1]} | sed 's/\^M\$//')@`echo ${NodeIP[0]} | awk -F // '{print $2}'`:36656,$($ChainCMD tendermint show-node-id --home=${NodeDic[2]} | sed 's/\^M\$//')@`echo ${NodeIP[0]} | awk -F // '{print $2}'`:46656,$($ChainCMD tendermint show-node-id --home=${NodeDic[3]} | sed 's/\^M\$//')@`echo ${NodeIP[0]} | awk -F // '{print $2}'`:56656\"/" $Home/config/config.toml
sed -i "s/persistent_peers = \"\"/persistent_peers = \"$($ChainCMD tendermint show-node-id --home=${NodeDic[0]} | sed 's/\^M\$//')@`echo ${NodeIP[0]} | awk -F // '{print $2}'`:26656\"/" $Home/config/config.toml

echo $($ChainCMD tendermint show-node-id --home=${NodeDic[0]} | sed 's/\^M\$//')
echo $($ChainCMD tendermint show-node-id --home=${NodeDic[1]} | sed 's/\^M\$//')
echo $($ChainCMD tendermint show-node-id --home=${NodeDic[2]} | sed 's/\^M\$//')
echo $($ChainCMD tendermint show-node-id --home=${NodeDic[3]} | sed 's/\^M\$//')

for i in `seq 0 $[ ${#Validators[*]} -1 ]`; do cp $Home/config/config.toml ${NodeDic[$i]}/config; done
for i in `seq 0 $[ ${#Validators[*]} -1 ]`; do cp $Home/config/genesis.json ${NodeDic[$i]}/config; done
for i in `seq 0 $[ ${#Validators[*]} -1 ]`; do cp $Home/config/app.toml ${NodeDic[$i]}/config; done

#docker  run -itd -p26656:26656 -p26657:26657 -p9090:9090 --mount type=bind,source=./testnet,destination=./testnet --name node0 bianjie/irita $ChainCMD start --pruning=nothing --home=./testnet/node0
