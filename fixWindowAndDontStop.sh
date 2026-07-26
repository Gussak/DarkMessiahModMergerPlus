#!/bin/bash

#	BSD 3-Clause License
#
#	Copyright (c) 2026, Gussak
#
#	Redistribution and use in source and binary forms, with or without
#	modification, are permitted provided that the following conditions are met:
#
#	1. Redistributions of source code must retain the above copyright notice, this
#		 list of conditions and the following disclaimer.
#
#	2. Redistributions in binary form must reproduce the above copyright notice,
#		 this list of conditions and the following disclaimer in the documentation
#		 and/or other materials provided with the distribution.
#
#	3. Neither the name of the copyright holder nor the names of its
#		 contributors may be used to endorse or promote products derived from
#		 this software without specific prior written permission.
#
#	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
#	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#	DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#	OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

echo "RUN THIS BEFORE RUNNING THE GAME!!! it will look ONLY for new windows!"

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

export strSelfName="$(basename "$0")"

function FUNCwindowHelper() { #will look for one or more newly created windows, fix them and exit
	strFlCfg=".${strSelfName}.cfg"
	declare -p strFlCfg
	if [[ -f "$strFlCfg" ]];then source "$strFlCfg";fi

	mapfile -t alnWIdOLD < <(xdotool search "${strWindowName}")
	
	#set -x
	local lnWId=-1
	: ${cmdRemoveWindowDecorations:="windowtweaks"} #help https://gist.github.com/AquariusPower/113f4559a4ac8ccb0225a89b9c74c0ea
	: ${strWindowName:="Wine Desktop"} #help when set to emulate desktop on winecfg it is: "Wine Desktop"
	: ${bAutoClickRun:=true} #help this is not really necessary and may cause trouble if you try to use the mouse or button is not where it wants
	while true;do
		echo -n .
		sleep 1
		
		mapfile -t alnWId < <(xdotool search "${strWindowName}")
		iFound=0
		for lnWId in "${alnWId[@]}";do
			if [[ -z "$lnWId" ]];then continue;fi
			for lnWIdOld in "${alnWIdOLD[@]}";do
				if [[ "$lnWIdOld" == "${lnWId}" ]];then continue;fi
			done
			
			if which "$cmdRemoveWindowDecorations";then
				set -x;"${cmdRemoveWindowDecorations}" -d $lnWId;set +x
				echo "decorations OFF for WindowID=$lnWId"
			fi
			
			if $bAutoClickRun;then
				: ${strXYclick:=""} #help "X,Y" ex.: "500,600"; where the mouse shall be placed to click on the ModLauncher continue button
				while [[ -z "$strXYclick" ]];do
					if ! FUNCaskYesNo "hit 'y', and position your mouse over the button in 3 seconds.";then exit 1;fi
					sleep 3
					eval "$(xdotool getmouselocation --shell)"
					strXYclick="$X,$Y"
					declare -p strXYclick
					if FUNCaskYesNo "is the above correct?";then
						declare -p strXYclick >"$strFlCfg"
						break;
					else
						strXYclick="" # to retry
					fi
				done
				nX=$(echo "$strXYclick" |cut -d, -f1)
				nY=$(echo "$strXYclick" |cut -d, -f2)
				
				if which ScriptEchoColor;then echoc --say "don't touch your mouse nor keyboard please";fi
				read -p "[blind wait the ModLauncher window show up]" -t 5 #TODO try `perceptualdiff` to check if the button is showing there
				
				xdotool mousemove $nX $nY;
				xdotool click --window $lnWId 1
				
				# for keys (Tab space), Wine needs windows tools like AutoHotkey
				#FAIL: set -x;xdotool key --window $lnWId Tab space;set +x #this focus the first button and activate it
				#FAIL: xset -r r on; wmctrl -a "Wine Desktop"; xdotool windowactivate 165675017; xdotool windowfocus 165675017; xdotool keydown --clearmodifiers --window 165675017 Tab && sleep 0.1 && xdotool keyup --clearmodifiers --window 165675017 Tab
				#FAIL: xset -r r off; wmctrl -a "Wine Desktop"; xdotool windowactivate 165675017; xdotool windowfocus 165675017; xdotool keydown --clearmodifiers --window 165675017 Tab && sleep 1 && xdotool keyup --clearmodifiers --window 165675017 Tab
				#FAIL: xset -r r off; wmctrl -a "Wine Desktop"; xdotool windowactivate 165675017; xdotool windowfocus 165675017; xdotool key --delay 1000 --clearmodifiers --window 165675017 Tab space
			fi
			
			((iFound++))&&:
		done
		
		if((iFound==0));then continue;fi
		
		break
	done
	
	read -p "[hit a key to exit(5s)]" -t 5
};export -f FUNCwindowHelper;

#if ! pgrep -fa DMMM_windowHelper;then
	(xterm -title DMMM_windowHelper -e bash -c "FUNCwindowHelper" & disown)
#fi
