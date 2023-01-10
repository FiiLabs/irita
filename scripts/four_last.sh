#!/bin/sh
Home=./testnet
ChainID=testnet # chain-id
ChainCMD=./build/metaosd
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
IpPorts=(tcp://127.0.0.1:26657 tcp://127.0.0.1:36657 tcp://127.0.0.1:46657 tcp://127.0.0.1:56657)
Stake=uirita
TotalStake=10000000000000000${Stake} # total stake in genesis
SendStake=10000000000000${Stake}
DataPath=/tmp

Point=upoint
PointOwner=metaos1g6gqr3s58dhw3jq5hm95qrng0sa9um7g2e2fcx # replace with actual address
PointToken=`echo {\"symbol\": \"point\", \"name\": \"Irita point native token\", \"scale\": 6, \"min_unit\": \"upoint\", \"initial_supply\": \"1000000000\", \"max_supply\": \"1000000000000\", \"mintable\": true, \"owner\": \"${PointOwner}\"}`

for i in `seq 1 $[ ${#Validators[*]} -1 ]`; do
address=$(bash -c "echo 12345678 | ${ChainCMD} keys show ${Validators[$i]} --home=${NodeDic[0]}| grep address" | awk '{print $2}');
echo $address
bash -c "echo -e \"12345678\n12345678\" | ${ChainCMD} tx bank send validator0 \$(echo $address  | sed 's/\\^M\\$//') ${SendStake} --chain-id $ChainID -y --home=${NodeDic[0]}";
sleep 2
bash -c "${ChainCMD} q bank balances \$(echo $address | sed 's/\\^M\\$//') --chain-id $ChainID --home=${NodeDic[0]}";
bash -c "echo -e \"12345678\n12345678\" | ${ChainCMD} tx perm assign-roles --from validator0 \$(echo $address | sed 's/\\^M\\$//') NODE_ADMIN --chain-id $ChainID -y --home=${NodeDic[0]}";
sleep 2
bash -c "${ChainCMD} q perm roles \$(echo $address  | sed 's/\\^M\\$//') --chain-id $ChainID --home=${NodeDic[0]}";
bash -c "echo -e \"12345678\n12345678\" | ${ChainCMD} tx node grant --name \"${NodeNames[$i]}\" --cert ${NodeDic[$i]}/node.crt --from validator0 --chain-id $ChainID -b block -y --home=${NodeDic[0]}";
sleep 2
bash -c "echo 12345678 | ${ChainCMD} keys show ${Validators[$i]} --home=${NodeDic[0]}"
bash -c "echo -e \"12345678\n12345678\" | ${ChainCMD} tx node create-validator --name \"${NodeNames[$i]}\" --from validator0 --cert ${NodeDic[$i]}/validator.crt --power 100 --chain-id $ChainID --node=${IpPorts[0]} -y --home=${NodeDic[0]}";
sleep 2
done
