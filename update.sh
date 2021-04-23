!/usr/bin/bash
read -p "input password:" passwd
echo "system updateing..."
echo $passwd | sudo apt-get update && sudo apt upgrade >>/dev/null
echo "installing dependency packges... "
sudo apt-get -f install >>/dev/null
echo "done."