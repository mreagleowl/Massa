#!/bin/bash
cd $HOME

read -p "Choose your password: " massapwd

echo ''
echo '-------------Creating RollsDaemon-------------'
echo ''
printf "SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/3 * * * * root /bin/bash /root/rollsup.sh > /dev/null 2>&1
" > /etc/cron.d/massarolls
sleep 2

echo ''
echo '-----------Creating MassaNODEDaemon-----------'
echo ''
sleep 2

printf "[Unit]
Description=Massa Node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/massa/massa-node
ExecStart=$HOME/massa/massa-node/massa-node -p $massapwd
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/massad.service
sleep 2

echo ''
echo '-----------Creating AutoBuyRollsScript----------'
echo ''

sudo tee /root/rollsup.sh > /dev/null <<EOF
#!/bin/sh
#V 0.14  ! Thanks for Merlin !
cd /root/massa/massa-client
#Set variables
catt=/usr/bin/cat
passwd=\$(\$catt \$HOME/massapasswd)
candidat=\$(./massa-client wallet_info -p "\$passwd"|grep 'Rolls'|awk '{print \$4}'| sed 's/=/ /'|awk '{print \$2}')
massa_wallet_address=\$(./massa-client -p "\$passwd" wallet_info |grep 'Address'|awk '{print \$2}')
tmp_final_balans=\$(./massa-client -p "\$passwd" wallet_info |grep 'Balance'|awk '{print \$3}'| sed 's/=/ /'|sed 's/,/ /'|awk '{print \$2}')
final_balans=\${tmp_final_balans%%.*}
averagetmp=\$(\$catt /proc/loadavg | awk '{print \$1}')
node=\$(./massa-client -p "\$passwd" get_status |grep 'Error'|awk '{print \$1}')
if [ -z "\$node" ]&&[ -z "\$candidat" ];then
echo \`/bin/date +"%b %d %H:%M"\` "(rollsup) Node is currently offline" >> /root/rolls.log
elif [ \$candidat -gt "0" ];then
echo "Ok" > /dev/null
elif [ \$final_balans -gt "99" ]; then
echo \`/bin/date +"%b %d %H:%M"\` "(rollsup) The roll flew off, we check the number of coins and try to buy" >> /root/rolls.log
resp=\$(./massa-client -p "\$passwd" buy_rolls \$massa_wallet_address 1 0)
else
echo \`/bin/date +"%b %d %H:%M"\` "(rollsup) Not enough coins to buy a roll from you \$final_balans, minimum 100" >> /root/rolls.log
fi
EOF
sleep 2

echo ''
echo '------------Creating logfile---------------'
echo ''

sudo tee $HOME/rolls.log > /dev/null <<EOF
Ok!.
EOF
sleep 2

echo '-'
echo '-------------Creating passfile----------------'
echo ''

sudo tee $HOME/massapasswd > /dev/null <<EOF
$massapwd
EOF
sleep 2
mkdir /root/massa_backup
sleep 2

echo ''
echo '------------ Downloading new Massa -----------'
echo ''
wget https://github.com/massalabs/massa/releases/download/TEST.18.0/massa_TEST.18.0_release_linux.tar.gz

sleep 2

echo ''
echo '------------ Unzipping new Massa -------------'
echo ''
tar zxvf massa_TEST.18.0_release_linux.tar.gz
sleep 2
rm /root/massa_TEST.*.tar.gz
sleep 2 
echo ''
echo '-------------- Gettin our ip -----------------'
echo ''
wget -qO- ifconfig.co
echo ''
sleep 2
sudo tee <<EOF >/dev/null $HOME/massa/massa-node/config/config.toml
[network]
routable_ip = "`wget -qO- ifconfig.co`"
EOF
sleep 2

echo ''
echo '---------- Adding bootstrap nodes ------------'
echo ''
function bootstrap {
	config_path="$HOME/massa/massa-node/base_config/config.toml"
	bootstrap_list=`wget -qO- https://raw.githubusercontent.com/mreagleowl/Massa/master/bootstraplist/bootstrap_list.txt | shuf -n50 | awk '{ print "        "$0"," }'`
	len=`wc -l < "$config_path"`
	start=`grep -n bootstrap_list "$config_path" | cut -d: -f1`
	end=`grep -n "\[optionnal\] port on which to listen" "$config_path" | cut -d: -f1`
	end=$((end-1))
	first_part=`sed "${start},${len}d" "$config_path"`
	second_part="
    bootstrap_list = [
${bootstrap_list}
    ]
"
	third_part=`sed "1,${end}d" "$config_path"`
	echo "${first_part}${second_part}${third_part}" > "$config_path"
	sed -i -e "s%retry_delay *=.*%retry_delay = 10000%; " "$config_path"
	#grep bootstrap_whitelist_file $config_path || sed -i "/\[bootstrap\]/a  bootstrap_whitelist_file = \"base_config/bootstrap_whitelist.json\"" "$config_path"
	#grep bootstrap_blacklist_file $config_path || sed -i "/\[bootstrap\]/a  bootstrap_blacklist_file = \"base_config/bootstrap_blacklist.json\"" "$config_path"
  #sudo systemctl restart massa
  wget -P $HOME/massa/massa-node/base_config/ https://raw.githubusercontent.com/mreagleowl/Massa/master/whitelist/bootstrap_whitelist.json
  echo '....done'
}

bootstrap

cd $HOME/massa/massa-node/
./massa-node -p $massapwd

sleep 2
echo ''
echo '--------------- Reconfig daemon --------------' 
echo ''
sleep 2
sudo systemctl daemon-reload && sudo systemctl enable massad && sudo systemctl restart massad && sudo journalctl -f -n 100 -u massad