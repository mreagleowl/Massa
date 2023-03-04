#!/bin/bash
cd $HOME

systemctl stop massad

catt=/usr/bin/cat
massapwd=$($catt /etc/systemd/system/massad.service | grep 'ExecStart'| awk '{print $3}')

echo ''
echo '------------Cleaning up logfile---------------'
echo ''
sudo tee $HOME/rolls.log > /dev/null <<EOF
Cleaning up!.
EOF
sleep 2

echo ''
echo '------------Backup key and wallet ------------'
echo ''
#cp /root/massa/massa-client/wallet.dat /root/massa_backup
#cp /root/massa/massa-node/config/node_privkey.key /root/massa_backup
sleep 2
echo ''
echo '------------Removing old Massa----------------'
echo ''
rm -rf $HOME/massa
sleep 2
echo ''
echo '------------ Downloading new Massa -----------'
echo ''
wget https://github.com/massalabs/massa/releases/download/TEST.20.0/massa_TEST.20.0_release_linux.tar.gz
sleep 2
echo ''
echo '------------ Unzipping new Massa -------------'
echo ''
tar zxvf massa_TEST.20.0_release_linux.tar.gz
sleep 2
rm /root/massa_TEST.*.tar.gz
sleep 2 
echo ''
echo '-------------- Gettin our ip -----------------'
echo ''
curl icanhazip.com
echo ''
sudo tee <<EOF >/dev/null $HOME/massa/massa-node/config/config.toml
[network]
routable_ip = "`curl icanhazip.com`"
EOF
sleep 2
echo ''
echo '--------Restoring old key and wallet----------'
echo ''
cp /root/massa_backup/wallet.dat /root/massa/massa-client/
cp /root/massa_backup/node_privkey.key /root/massa/massa-node/config/ 
sleep 2

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
	grep bootstrap_whitelist_file $config_path || sed -i "/\[bootstrap\]/a  bootstrap_whitelist_path = \"base_config/bootstrap_whitelist.json\"" "$config_path"
	grep bootstrap_blacklist_file $config_path || sed -i "/\[bootstrap\]/a  bootstrap_blacklist_path = \"base_config/bootstrap_blacklist.json\"" "$config_path"
  rm $HOME/massa/massa-node/base_config/bootstrap_whitelist.json
  wget -P $HOME/massa/massa-node/base_config/ https://raw.githubusercontent.com/mreagleowl/Massa/master/whitelist/bootstrap_whitelist.json
  echo '....done'
}

# bootstrap
  wget -P $HOME/ https://raw.githubusercontent.com/mreagleowl/Massa/master/bootstraplist/bootstrap_list.txt
  sed -i '199r /root/bootstrap_list.txt' /root/massa/massa-node/base_config/config.toml
  rm /root/massa/massa-node/base_config/bootstrap_whitelist.json
  rm /root/bootstrap_list.txt
  wget -P $HOME/massa/massa-node/base_config/ https://raw.githubusercontent.com/mreagleowl/Massa/master/whitelist/bootstrap_whitelist.json



cd $HOME/massa/massa-node/
./massa-node -p $massapwd

sleep 2
echo ''
echo '--------------- Reconfig daemon --------------' 
echo ''
sleep 2
sudo systemctl daemon-reload && sudo systemctl enable massad && sudo systemctl restart massad
#rm /root/up_massa.sh
#sudo journalctl -f -n 100 -u massad
