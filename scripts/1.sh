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

address=$(bash -c "echo 12345678 | ${ChainCMD} keys show ${Validators[0]} | grep address" | awk '{print $2}');
echo $address
bash -c "echo -e \"12345678\n12345678\" | ${ChainCMD} tx bank send ${Validators[0]} \$(echo $address  | sed 's/\\^M\\$//') ${SendStake} --chain-id $ChainID -y --home=${NodeDic[0]}";
sleep 1
bash -c "${ChainCMD} q bank balances \$(echo $address | sed 's/\\^M\\$//') --chain-id $ChainID --home=${NodeDic[0]}";
bash -c "echo -e \"12345678\n12345678\" | ${ChainCMD} tx perm assign-roles --from ${Validators[0]} \$(echo $address | sed 's/\\^M\\$//') NODE_ADMIN --chain-id $ChainID -y --home=${NodeDic[0]}";
sleep 1
bash -c "${ChainCMD} q perm roles \$(echo $address  | sed 's/\\^M\\$//') --chain-id $ChainID --home=${NodeDic[0]}";
bash -c "echo -e \"12345678\n12345678\" | ${ChainCMD} tx node grant --name \"${NodeNames[0]}\" --cert ${NodeDic[0]}/node.crt --from ${Validators[0]} --chain-id $ChainID -b block -y --home=${NodeDic[0]}";
bash -c "echo -e \"12345678\n12345678\" | ${ChainCMD} tx node create-validator --name \"${NodeNames[0]}\" --from ${Validators[0]} --cert ${NodeDic[0]}/validator.crt --power 100 --chain-id $ChainID --node=tcp://127.0.0.1:26657 -y --home=${NodeDic[0]}";
