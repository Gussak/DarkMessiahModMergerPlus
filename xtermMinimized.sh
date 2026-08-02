#!/bin/bash

echo "see 'allMergerScriptsGenericConfig.sh/FUNCxterm/launchappminimized' instead"
exit

strTitle="$1";shift
aParams=("$@")

if pgrep -fa "$strTitle";then
	echo "[ERROR] strTitle='$strTitle' must be unique but it is already running..."
	exit 1
fi

pkill -SIGKILL -fe "$strTitle"
(xterm -title "$strTitle" "${aParams[@]}" & disown)
while true;do
	pkill -SIGSTOP -fe "$strTitle";
	if wmctrl -l |grep "$strTitle";then
		echo "[INFO] window is ready"
		xdotool windowminimize "$(wmctrl -l |grep "$strTitle" |awk '{print $1}')"
		pkill -SIGCONT -fe "$strTitle";
	else
		pkill -SIGCONT -fe "$strTitle";
	fi
done
