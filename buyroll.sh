#!/bin/sh
#Ver. 1.0 mainnet
#Thanks for Merlin
cd /root/massa/massa-client
#Set variables
catt=/usr/bin/cat
passwd=YOUR_PASSWORD_HERE
candidat=$(./massa-client wallet_info -p "$passwd"|grep 'Rolls'|awk '{print $4}'| sed 's/=/ /'|awk '{print $2}')
massa_wallet_address=$(./massa-client -p "$passwd" wallet_info |grep 'Address'|awk '{print $2}')
tmp_final_balans=$(./massa-client -p "$passwd" wallet_info |grep 'Balance'|awk '{print $3}'| sed 's/=/ /'|sed 's/,/ /'|awk '{print $2}')
final_balans=${tmp_final_balans%%.*}
buy_amount=$(echo "scale=2; $final_balans / 100" | bc)
buy_amount=$(echo "$buy_amount" | cut -f1 -d.)
averagetmp=$($catt /proc/loadavg | awk '{print $1}')
node=$(./massa-client -p "$passwd" get_status |grep 'Error'|awk '{print $1}')
if [ -z "$node" ]&&[ -z "$candidat" ];then
echo `/bin/date +"%b %d %H:%M"` "(rollsup) Node is currently offline" >> /root/rolls.log
elif [ $final_balans -gt "100" ]; then
echo `/bin/date +"%b %d %H:%M"` "(rollsup) Checking free MAS coins, and trying to buy ROLL" >> /root/rolls.log
resp=$(./massa-client -p "$passwd" buy_rolls $massa_wallet_address $buy_amount 0.01)
else
echo `/bin/date +"%b %d %H:%M"` "(rollsup) Not enough MAS to buy a ROLL, you have - $final_balans, minimum 100" >> /root/rolls.log
fi
