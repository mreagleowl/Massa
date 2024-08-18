#!/bin/bash
cd $HOME

read -p "Choose your password: " massapwd

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
echo '-------------Creating passfile----------------'
echo ''

sudo tee $HOME/massapasswd > /dev/null <<EOF
$massapwd
EOF

mkdir /root/massa_backup

sleep 2

echo ''
echo '------------ Downloading new Massa -----------'
echo ''
wget https://github.com/massalabs/massa/releases/download/MAIN.2.3/massa_MAIN.2.3_release_linux.tar.gz

sleep 2

echo ''
echo '------------ Unzipping new Massa -------------'
echo ''
tar zxvf massa_MAIN.2.3_release_linux.tar.gz
sleep 2
rm /root/massa_MAIN.*.tar.gz
sleep 2 
echo ''
echo '-------------- Get ip -----------------'
echo ''
curl icanhazip.com
echo ''
sudo tee <<EOF >/dev/null $HOME/massa/massa-node/config/config.toml
[protocol]
routable_ip = "`curl icanhazip.com`"
EOF
sleep 2


cd $HOME/massa/massa-node/
./massa-node -p $massapwd

sleep 2
echo ''
echo '--------------- Reconfig daemon --------------' 
echo ''
sleep 2
sudo systemctl daemon-reload && sudo systemctl enable massad && sudo systemctl restart massad && sudo journalctl -f -n 100 -u massad
