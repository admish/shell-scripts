#!/bin/bash
## Update script for a MagicMirror running on an RPi

## Set installation path for MagicMirror
varToday=`date +%Y-%m-%d`
mmPath="/home/pi/MagicMirror"
mmLogs="/home/pi/.logs"

## Update Rasbian
sudo apt update
sudo apt -y upgrade
sudo apt -y dist-upgrade
sudo apt -y autoremove
sudo apt -y clean

## Temporarily disable HDMI during update
tvservice -o

## Shutdown MagicMirror application
pm2 stop /home/pi/mm.sh

## Fix possible "Missing write access" permission error on NPM
sudo chown -R $USER:$USER /usr/lib/node_modules

## NPM gives permissions errors after using sudo one time.
## These commands will install all the modules in the home folder.
if [ ! -d /home/pi/.npm-global ]; then
  mkdir -p /home/pi/.npm-global;
fi
npm config set prefix '/home/pi/.npm-global'
export PATH=/home/pi/.npm-global/bin:$PATH

## Update MagicMirror
cd $mmPath
git pull
npm install -g npm
npm audit fix


## Update Modules
for i in $(find $mmPath/modules -maxdepth 2 -type d -name .git); do
	cd $i/..
	git pull
	npm install -g npm
	npm audit fix

	if [ -n "$(git status --porcelain)" ];
	then
		endpath=$(basename $(pwd))
		echo -e "\033[32m"$endpath" up to date. \033[0m"
	else
		endpath=$(basename $(pwd))
		echo -e "\033[33m"$endpath" has issues? \033[0m\r"
		git status --porcelain >> $mmLogs/$varToday.log
		echo "----------------------------------------------------"
	fi

done

## Start MagicMirror application
pm2 start /home/pi/mm.sh

## Give MagicMirror 10 seconds to get loaded
sleep 10

## Re-enable the HDMI
tvservice -p
xset -display :0 dpms force on

## Enable restarting of the MagicMirror script
pm2 save
