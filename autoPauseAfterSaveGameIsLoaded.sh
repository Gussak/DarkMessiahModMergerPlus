#!/bin/bash

#	BSD 3-Clause License
#
#	Copyright (c) 2026, Gussak<https://github.com/Gussak>
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

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

: ${bVerbose:=false};export bVerbose #help

: ${strTextHint:="hltv_fov"};export strTextHint #help this shows up on the last writing to that file, after that you only need to wait for 5s! "maxplayers|player_death" hints may happen before the real last file writing tho, so better not use them. # this happens later "hltv_status" # these happen at the very end "46:|hltv_fov|target2"

: ${strFlHint:="${strGameInstallMainFolder}/${strGameSubRelatFolderWriteAllHere}/demoheader.tmp"};export strFlHint #help the hint file is never recreated. It stays there, it seems to be emptied and receive new fresh data, so it's creation time is useless.

: ${nIgnoreTinyStringsSize:=1};export nIgnoreTinyStringsSize #help these tiny strings are probably useless here TODO: just filter out if not: [0-9a-zA-Z_]*

function FUNCdetectPidToPause() { # the one that has no focus
	#set -x
	nWFocId="$(xdotool getwindowfocus)"&&:
	nWFocNm="$(xdotool getwindowname $nWFocId)"&&:
	nWFocPid="$(xdotool getwindowpid $nWFocId)"&&: # some windows may have no pid thru xdotool!!! :O
	
	declare -gx bPauseAll=false
	# not a window with pid or has not env WINEPREFIX #TODO could test other things like checking for wine executable
	if [[ -z "$nWFocPid" ]] || ! strWineprefixWFocus="$(strings /proc/$nWFocPid/environ |grep WINEPREFIX)";then
		bPauseAll=true;
	fi
	
	# multidimentional array simulated: [PidGM] = PidFM WindowID WINEPREFIX (the link between them is WINEPREFIX)
	declare -gx anPidGm=($(pgrep -f "Dark Messiah.*mm.exe|mm.exe ")) # as wine cant decide if will run it with or without windows full path naming :(
	declare -gx aPidGm_PidFM=() # the PidFM is from explorer.exe (filemanager FM) and not from the game as wine is running in desktop single window mode
	declare -gx aPidGm_WindowID=()
	declare -gx aPidGm_WINEPREFIX=()
	declare -gx aPidGm_bFocus=()
	# arrays dont export in bash, see in the end they filled up and exported
	
	
	for nPidGm in "${anPidGm[@]}";do
		strWineprefixGm="$(strings /proc/$nPidGm/environ |grep WINEPREFIX)"
		aPidGm_WINEPREFIX[$nPidGm]="$strWineprefixGm"
	done
	
	mapfile -t astrLn < <(wmctrl -l -p |grep "Wine Desktop" |awk '{print "_nW=" $1 ";_nPidFM=" $3 ";"}')
	for strLn in "${astrLn[@]}";do eval "${strLn}";
		strWineprefixFm="$(strings /proc/$_nPidFM/environ |grep WINEPREFIX)"
		#for((i=0;i<${#aPidGm_WINEPREFIX[@]};i++));do
		#echo "DEBUG:${!aPidGm_WINEPREFIX[@]}"
		#declare -p _nPidFM _nW
		for nPidGm in ${!aPidGm_WINEPREFIX[@]};do
			#echo "if [[ \"$strWineprefixFm\" == \"${aPidGm_WINEPREFIX[$nPidGm]}\" ]];then"
			if [[ "$strWineprefixFm" == "${aPidGm_WINEPREFIX[$nPidGm]}" ]];then
				aPidGm_PidFM[$nPidGm]="$_nPidFM"
				aPidGm_WindowID[$nPidGm]="$(printf %d $_nW)"
				if((nWFocId==${aPidGm_WindowID[$nPidGm]}));then aPidGm_bFocus[$nPidGm]=true; else aPidGm_bFocus[$nPidGm]=false; fi
			fi
		done
		#declare -p aPidGm_PidFM
	done
	
	#declare -p nWFocId nWNm nWPid anPidGm nPidGmExecFocus >&2
	if $bVerbose;then
		declare -p anPidGm aPidGm_PidFM aPidGm_WindowID aPidGm_WINEPREFIX aPidGm_bFocus bVerbose
	fi
	
	export strExportArrays="$(declare -p anPidGm aPidGm_PidFM aPidGm_WindowID aPidGm_WINEPREFIX aPidGm_bFocus)"
};export -f FUNCdetectPidToPause

function FUNCtest() {
	FUNCdetectPidToPause
}
if [[ "${1-}" == --test ]];then FUNCtest;exit;fi

function FUNCstringsDump() { #help <index> use this to dump demoheader.tmp strings for clues
	local lstrFlSnapshot="${1}"; #help the backup index generated by ... . must be like ex.: 000000007 (fixed 9 decimal places with zeros on the left)
	strings "${lstrFlSnapshot}" \
		|tr -d ' \t\r' \
		|sed -r -e 's@^.{1,'${nIgnoreTinyStringsSize}'}$@@g' \
		|sort -u >"${lstrFlSnapshot}.Strings.txt"
};export -f FUNCstringsDump
function FUNCmonitorChanges() {
	local lfLoopDelay
	: ${lfLoopDelay:=0.33};export lfLoopDelay #help_FUNCmonitorChanges
	
	local lstrFlNewest="$(ls -1tr "${strFlHint}.SnapShot_ID_"*".bkp" |tail -n 1)"&&:
	#local lstrFlNewest="$(ls -1 "${strFlHint}.SnapShot_ID_"*".bkp" |sort |tail -n 1)"&&:
	declare -p lstrFlNewest
	
	# init with newest file
	local lnID=0
	if [[ -n "$lstrFlNewest" ]];then
		#local lnID="${lstrFlNewest#${strFlHint}.}"
		lnID="$(echo "$lstrFlNewest" |sed -r -e 's@.*[.]SnapShot_ID_([0-9]*)[.].*@\1@')"
		declare -p lnID
		lnID=$((10#$lnID))
		((lnID++))&&: #next
		declare -p lnID
	fi
	
	local lnSz=0;
	local lnIndex=0
	local lstrFlSnapshotPrev=""
	while true;do 
		local lnSzNew=$(stat -c %s "$strFlHint");
		#local lnDtTm=$(stat -c %W "$strFlHint"); # creation time
		local lnDtTmNew=$(stat -c %Y "$strFlHint"); # modification time
		if(( lnSz != lnSzNew || lnDtTm != lnDtTmNew));then
			# loop control
			lnSz=$lnSzNew;
			lnDtTm=$lnDtTmNew
			
			echo
			
			local lstrID="$(printf %09d $lnID)"
			local lstrIndex="$(printf %09d $lnIndex)"
			local lstrFlSnapshot="${strFlHint}.SnapShot_ID_${lstrID}.Index_${lstrIndex}.bkp"
			cp -vf "$strFlHint" "$lstrFlSnapshot";
			
			FUNCstringsDump "${lstrFlSnapshot}"
			
			((lnIndex++))&&:;
			#ls --time-style=full-iso -l "$strFlHint"*"${lstrIndex}"*;
			ls --time-style=full-iso -l "${lstrFlSnapshotPrev}.Strings.txt" "${lstrFlSnapshot}.Strings.txt" &&:
			
			#clear;mapfile -t aFl < <(ls -1tr "${strFlHint}.SnapShot_ID_1777875194.Index_"*".bkp.Strings.txt");for strFl in "${aFl[@]}";do echo; ls --time-style=full-iso -l "$strFl"; comm -13 "$strFlPrev" "$strFl"; strFlPrev="$strFl"; done
			if [[ -f "$lstrFlSnapshotPrev" ]];then set -x; comm -13 "${lstrFlSnapshotPrev}.Strings.txt" "${lstrFlSnapshot}.Strings.txt" &&:; set +x; fi
			
			# prepare next
			if egrep "${strTextHint}" "$strFlHint";then
				echo "HINT DETECTED! prepare next detection (BUT on next ID, if the file is still modified and increase, there may have hints there!)"
				((lnID++))&&: # begin next hint detection
				lnIndex=0
				declare -p lnID lnIndex
			fi
			
			lstrFlSnapshotPrev="$lstrFlSnapshot"
		fi;
		
		sleep ${lfLoopDelay};
	done
};export -f FUNCmonitorChanges

iMonCh=0
if [[ "${1-}" == "-m" ]];then shift;iMonCh=1;fi #help monitor changes and dump strings xterm
if [[ "${1-}" == "-M" ]];then shift;iMonCh=2;fi #help monitor changes and dump strings
case $iMonCh in
	1)
		if ! pgrep -fa DarkMessiah_FUNCmonitorChanges;then
			(xterm -maximized -title DarkMessiah_FUNCmonitorChanges -e FUNCmonitorChanges & disown)
		fi
		;;
	2) FUNCmonitorChanges;exit;;
	*);;
esac

export nScrWhalf=$(($(xdotool getdisplaygeometry |awk '{print $1}') / 2 ))

function FUNCCHILDminimizePopup() {
	set -x
	while true;do
		if nWIdPopup="$(wmctrl -l |grep "$strTitle" |awk '{print $1}')";then
#					if nWIdPopup="$(wmctrl -l |grep "$1" |awk '{print $1}')";then
			#sleep 2 # or the window will not be read to be minized and may bug and vanish! could be 1s? other tests like thru xwininfo may help to know it will be reaally reeady and not bug out?
			if xdotool windowminimize --sync $(printf %d $nWIdPopup);then
				break
			fi
		fi
		sleep 0.33
	done
	set +x
	read -t 60 -p "press a key to exit"
};export -f FUNCCHILDminimizePopup

function FUNCpauseAndResumeAtom() {
	local lnPidGm="$1";shift
	if [[ -z "$lnPidGm" ]];then
		pstree -psl $$&&:
		FUNCechoInfo "INVALID!!! lnPidGm='$lnPidGm'"
		FUNCwait
		return 1
	fi
	
	if FUNCisPidStopped $lnPidGm;then return 0;fi #already stopped
	
	if [[ -z "${anPidGm[@]-}" ]];then eval "$strExportArrays";fi #could be a mktemp file thru source but is equivalent...
	
	set -x;kill -SIGSTOP $lnPidGm;set +x
	if which ScriptEchoColor;then echoc --say "Game Loaded";fi
	#while ! yad --title="DarkMessiah:helper" --text="Dark Messiah of MM\n Game Finished Loading\n SigStopped\n Continue NOW?" --geometry=1x1+$nScrWhalf+0 --undecorated;do :;done; # not --on-top because it cant be too small :(
	#while ! yad --geometry=1x1+$nScrWhalf+0 --title="DarkMessiah:helper" --center --no-buttons;do :;done; # not --on-top because it cant be too small :(
	
	export strTitle="DarkMessiah:FinishedLoading:${lnPidGm}"
	declare -p aPidGm_PidFM aPidGm_WindowID aPidGm_WINEPREFIX aPidGm_bFocus strTitle
	#KEEPinfo this gets the focus and break the gameplay: #(xterm -geometry 1x1+1+1 -e FUNCCHILDminimizePopup & disown) #this gets the focus and break the gameplay
#				FUNCCHILDminimizePopup "$strTitle"& #TODO why export strTitle didnt work?
	FUNCCHILDminimizePopup&
	
	# popup
	yad --geometry=500x1+$nScrWhalf+0 --title="$strTitle" --on-top --no-buttons --no-focus &&: #unable to popup below :(, it should not receive imediate focus but should be focusable!!! unable to prevent it starting --on-top, so keep it there; no buttons, just hold the flow here
	kill -SIGCONT $lnPidGm
	
	set -x
	xdotool windowactivate ${aPidGm_WindowID[$lnPidGm]}
	xdotool windowfocus    ${aPidGm_WindowID[$lnPidGm]}
	set +x
};export -f FUNCpauseAndResumeAtom

function FUNCpauseAfterLoad() {
	: ${bPauseOnlyNoFocusInstance:=true};export bPauseOnlyNoFocusInstance #help if false will pause all instance
	while true;do
		nThisRunTime=$(date +%s)
		while true;do
			echo -ne "=============================== $(date) ================================\r"
			sleep 1
			
			if [[ ! -f "$strFlHint" ]];then FUNCechoInfo "'$strFlHint' not found"; continue;fi
			
			FUNCdetectPidToPause
			#anPidGm=($(pgrep -f "C:[\].*[\]mm.exe"))
			
			: ${bExitIfGameExits:=false};export bExitIfGameExits #help
			if $bExitIfGameExits;then
				if ! ps -p ${anPidGm[@]};then exit;fi
			fi
			
			: ${bTestFoundHint:=false};export bTestFoundHint #help fake a hint was found, for DEBUG only
			if ! $bTestFoundHint;then
				if(( $(stat -c %Y "$strFlHint") < nThisRunTime ));then
					continue
				fi
				
				if ! egrep --quiet "${strTextHint}" "$strFlHint";then
					continue
				fi
			fi
			
			: ${fSleepAfterHintFound:=3.0};export fSleepAfterHintFound #help
			read -n 1 -t $fSleepAfterHintFound -p "hit a key to SIGSTOP game"&&:
			
			#FUNCdetectPidToPause
			
			#use case for 2 instances only
			nPidGmFocus=0
			for nPidGm in "${anPidGm[@]}";do 
				if ${aPidGm_bFocus[$nPidGm]};then
					nPidGmFocus=$nPidGm
				fi
			done
			
			if((nPidGmFocus==0)) || ! $bPauseOnlyNoFocusInstance || $bPauseAll;then #none has focus, force pause all
				for nPidGm in "${anPidGm[@]}";do #use case for 2 instances only
					if FUNCisPidStopped $nPidGm;then continue;fi
					# this is good to let it stop both instances, being run as child process
					(xterm -title "DarkMessiah_FUNCpauseAndResumeAtom" -geometry 100x10+1+1 -e bash -c "FUNCpauseAndResumeAtom $nPidGm;FUNCwait60s" &) #no "& disown" to grant it cascade kills with this script. this thru xterm gets the focus and break the gameplay if focused, there is no way to auto minimize xterm? only thru title match like with the popup.. but that brief miliseconds may still break the gameplay... why it hasnt just a -minimize???
				done
			else
				if $bPauseOnlyNoFocusInstance;then
					for nPidGm in "${anPidGm[@]}";do 
						if FUNCisPidStopped $nPidGm;then continue;fi
						#if $bPauseOnlyNoFocusInstance && ((FUNCdetectPidToPause_nPidNoFocus != 0 && nPidGm != FUNCdetectPidToPause_nPidNoFocus));then continue;fi
						#if $bPauseOnlyNoFocusInstance && ${aPidGm_bFocus[$nPidGm]};then continue;fi # ignores focused window
						if ! ${aPidGm_bFocus[$nPidGm]};then
							FUNCpauseAndResumeAtom $nPidGm #this holds the execution of this script and grants gameplay wont lose keyboard focus and mess up
							break
						fi
					done
				fi
			fi
			
			break # to update nThisRunTime for the next game load
		done
	done
};export -f FUNCpauseAfterLoad;

#set -x
if ! pgrep -fa DMMM_pauseAfterLoad;then
	: ${bXterm:=true};export bXterm
	if $bXterm;then
		(xterm -maximized -title DMMM_pauseAfterLoad -e bash -c "FUNCpauseAfterLoad" & disown);
	else
		FUNCpauseAfterLoad
	fi
else
	echo "already running"
fi
