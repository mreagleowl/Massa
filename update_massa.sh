#!/bin/bash
cd $HOME

catt=/usr/bin/cat
massapwd=$($catt /etc/systemd/system/massad.service | grep 'ExecStart'| awk '{print $3}')

echo ''
echo '------------Cleaning up logfile---------------'
echo ''
sudo tee $HOME/rolls.log > /dev/null <<EOF
Лог файл создан удачно.
EOF
sleep 2

echo ''
echo '-------Backup keys, wallet and whitelist------'
echo ''
cp /root/massa/massa-client/wallet.dat /root/massa_backup
cp /root/massa/massa-node/config/node_privkey.key /root/massa_backup
cp /root/massa/massa-node/base_config/bootstrap_whitelist.json /root/massa_backup
sleep 2
echo ''
echo '------------Removing old Massa----------------'
echo ''
rm -rf $HOME/massa
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
echo '--------Restoring old key and wallet----------'
echo ''
cp /root/massa_backup/wallet.dat /root/massa/massa-client/
cp /root/massa_backup/node_privkey.key /root/massa/massa-node/config/ 
cp /root/massa_backup/bootstrap_whitelist.json /root/massa/massa-node/base_config/ 
sleep 2

cd $HOME/massa/massa-node/
./massa-node -p $massapwd

sleep 2
echo ''
echo '--------------- Reconfig daemon --------------' 
echo ''
sleep 2
sudo systemctl daemon-reload
sudo systemctl enable massad
rm /root/up_massa.sh
#sudo systemctl restart massad
#sudo journalctl -f -n 100 -u massad