#!/bin/bash

cd "$(dirname "$0")"
pwd
strGitProj="$(basename "$(realpath .)")"
declare -p strGitProj
nWid="$(xdotool search "Git Gui.*${strGitProj}")"
declare -p nWid
if [[ -n "$nWid" ]];then
	if which xdotool;then
		xdotool windowraise $nWid
	fi
else
	(xterm -e bash -c "sleep 1;(nohup git gui & disown);sleep 1"&disown) #it is important to be this way to force gitgui open a gui to ask for password (instead of requesting the password to be input on the terminal)
fi
#set -x
#read -t 60 -n 1 -p PressAKeyToExit
