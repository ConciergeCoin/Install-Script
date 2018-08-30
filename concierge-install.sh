#!/bin/bash

HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=6
BACKTITLE="Concierge Masternode Setup Wizard"
TITLE="Concierge VPS Setup"
MENU="Choose one of the following options:"

OPTIONS=(1 "Install New VPS Server"
         2 "Update to new version VPS Server"
         3 "Start Concierge Masternode"
	 4 "Stop Concierge Masternode"
	 5 "Concierge Server Status"
	 6 "Rebuild Concierge Masternode Index")


CHOICE=$(whiptail --clear\
		--backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
        1)
            echo Starting the install process.
echo Checking and installing VPS server prerequisites. Please wait.
echo -e "Checking if swap space is needed."
PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
SWAP=$(swapon -s)
if [[ "$PHYMEM" -lt "2" && -z "$SWAP" ]];
  then
    echo -e "${GREEN}Server is running with less than 2G of RAM, creating 2G swap file.${NC}"
    dd if=/dev/zero of=/swapfile bs=1024 count=2M
    chmod 600 /swapfile
    mkswap /swapfile
    swapon -a /swapfile
else
  echo -e "${GREEN}The server running with at least 2G of RAM, or SWAP exists.${NC}"
fi
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi
clear
sudo apt update
sudo apt-get -y upgrade
sudo apt-get install git -y
sudo apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils -y
sudo apt-get install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev -y
sudo apt-get install libboost-all-dev -y
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
sudo apt-get install libminiupnpc-dev -y
sudo apt-get install libzmq3-dev -y
sudo apt-get install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler -y
sudo apt-get install libqt4-dev libprotobuf-dev protobuf-compiler -y
clear
echo VPS Server prerequisites installed.


echo Configuring server firewall.
sudo apt-get install -y ufw
sudo ufw allow 51470
sudo ufw allow ssh/tcp
sudo ufw limit ssh/tcp
sudo ufw logging on
echo "y" | sudo ufw enable
sudo ufw status
echo Server firewall configuration completed.

echo Downloading AquilaX install files.
wget https://github.com/ConciergeCoin/Concierge/releases/download/V1.0.0.1/Concierge-linux.tar.gz
echo Download complete.

echo Installing Concierge.
tar -xvf Concierge-linux.tar.gz
chmod 775 ./concierged
chmod 775 ./concierge-cli
echo Concierge install complete. 
sudo rm -rf Concierge-linux.tar.gz
clear

echo Now ready to setup Concierge configuration file.

RPCUSER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
RPCPASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
EXTIP=`curl -s4 icanhazip.com`
echo Please input your private key.
read GENKEY

mkdir -p /root/.concierge && touch /root/.concierge/concierge.conf

cat << EOF > /root/.concierge/concierge.conf
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1
server=1
listen=1
daemon=1
staking=1
rpcallowip=127.0.0.1
rpcport=51471
port=51470
logtimestamps=1
maxconnections=256
masternode=1
externalip=$EXTIP
masternodeprivkey=$GENKEY

EOF
clear
./concierged -daemon
./concierge-cli stop
./concierged -daemon
clear
echo Concierge configuration file created successfully. 
echo Concierge Server Started Successfully using the command ./concierged -daemon
echo If you get a message asking to rebuild the database, please hit Ctr + C and run ./concierged -daemon -reindex
echo If you still have further issues please reach out to support in our Discord channel. 
echo Please use the following Private Key when setting up your wallet: $GENKEY
            ;;
	    
    
        2)
sudo ./concierge-cli -daemon stop
echo "! Stopping Concierge Daemon !"

echo Configuring server firewall.
sudo apt-get install -y ufw
sudo ufw allow 51470
sudo ufw allow ssh/tcp
sudo ufw limit ssh/tcp
sudo ufw logging on
echo "y" | sudo ufw enable
sudo ufw status
echo Server firewall configuration completed.

echo "! Removing Concierge !"
sudo rm -rf concierge-install.sh*
sudo rm -rf ubuntu.zip*
sudo rm -rf concierged
sudo rm -rf concierge-cli
sudo rm -rf concierge-qt



wget https://github.com/ConciergeCoin/Concierge/releases/download/V1.0.0.0/Concierge-linux.tar.gz
echo Download complete.
echo Installing Concierge.
tar -xvf Concierge-linux.tar.gz
chmod 775 ./concierged
chmod 775 ./concierge-cli
echo Concierge install complete. 
sudo rm -rf Concierge-linux.tar.gz

            ;;
        3)
            ./concierged -daemon
		echo "If you get a message asking to rebuild the database, please hit Ctr + C and rebuild Concierge Index. (Option 6)"
            ;;
	4)
            ./concierge-cli stop
            ;;
	5)
	    ./concierge-cli getinfo
	    ;;
        6)
	     ./concierged -daemon -reindex
            ;;
esac
