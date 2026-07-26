#!/bin/bash

if [[ "${1-}" == "--help" ]];then #help ok
	: #egrep "[#]help" "$0"
fi

pwd
strSelfBN="$(basename "$0")"
declare -p strSelfBN
if [[ ! -f "./${strSelfBN}" ]];then
	cd "$(dirname "$0")"
fi
pwd
strMainModFolder="$(pwd)"

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

: ${bXtermAlready:=false} # self internal use only
if ! $bXtermAlready;then
	: ${bXterm:=true} #help
	if $bXterm;then
		if pgrep -fa DMMM_Helpers;then exit 0;fi
		(xterm -title DMMM_Helpers -e bash -c "while true;do ./${strSelfBN} --help; read -p PressEnterToRunHelpers&&:; bXtermAlready=true ./${strSelfBN};done" & disown)
		exit 0
	fi
fi

#set -x

if which ScriptEchoColor;then
	cd ..;pwd
	if [[ -f "Dark Messiah Might and Magic Single Player/mm.exe" ]];then
		echo "Merged game folder already mounted..."
	else
		declare -p strMainModFolder;echo "[IMPORTANT:] is the above correct? (otherwise hit Ctrl+c)";read -t 15 -n 1&&: # strResp&&:;if [[ "$strResp" != [yY] ]];then exit 1;fi
		bSudoWithScript=true strUnionFSID=overlayfs secOverrideMultiLayerMountPoint.sh "Dark Messiah Might and Magic Single Player" #help @InfoID="secOverrideMultiLayerMountPoint.sh:MOUNT" Helper Script, depends on ScriptEchoColor
	fi
fi

cd "${strMainModFolder}/"
bPauseOnlyNoFocusInstance=true ./autoPauseAfterSaveGameIsLoaded.sh -m #help @InfoID="autoPauseAfterSaveGameIsLoaded.sh" Helper Script, endless loop

cd "${strMainModFolder}/"
(xterm -e ./createFunctionalBkp.sh & disown) #help @InfoID="createFunctionalBkp.sh" Helper Script, run once, create configs small backup

#cd "${strMainModFolder}/"
#./gitgui.sh #run once

cd "${strMainModFolder}/"
./quickBkp.sh #help @InfoID="quickBkp.sh" Helper Script, endless loop to backup quick.sav

: ${bRunBothInstances:=true} #help
if $bRunBothInstances;then
	#: ${bFixW:=false} #help runs fixWindowAndDontStop.sh
	#if $bFixW;then
		#cd "${strMainModFolder}/"
		#./fixWindowAndDontStop.sh #help @InfoID="fixWindowAndDontStop.sh" Helper Script, waits game start
	#fi
	strWarnMsg="WAIT@{-n} THE other INSTANCE FINISH LOADING THE SAVEGAME OR BOTH may CRASH/FREEZE!!!"
	#cd '${strPathMainModFolder}';
	#if which guakeAutoEnv.sh;then # using ScriptEchoColor project
		#guakeAutoEnv.sh \
			#-ID_CMD game cd "${strGameInstallMainFolder}" \
			#-ID_CMD game bash -c "bBashAutoCmdOnStart=false secEnvDev.sh --clean bash -c 'while true;do echoc --alert \"$strWarnMsg\"; echoc -w \"hit Enter to run DarkMessiahMM\"; pwd; ./fixWindowAndDontStop.sh; ./runDarkMessiahOMM_Launcher.sh -1; done'" \
			#\
			#-ID_CMD game2 cd "${strGameInstallMainFolder}" \
			#-ID_CMD game2 echoc --alert "Run a 2nd instance for quick resume playing after death, as load game is super slow." \
			#-ID_CMD game2 bash -c "bBashAutoCmdOnStart=false secEnvDev.sh --clean bash -c 'while true;do echoc --alert \"$strWarnMsg\"; pwd; echoc -w \"hit Enter to run DarkMessiahMM @{nul}2nd Instance@{-n-u-l}\"; pwd; ./fixWindowAndDontStop.sh; ./runDarkMessiahOMM_Launcher.sh -2; done'"
	#else
		#for((i=1;i<=2;i++));do
			#if ! pgrep -fa DMMM_Run${i};then (xterm -title DMMM_Run${i} -e bash -c "while true;do echo '$strWarnMsg'; read -p 'hit Enter to run DarkMessiahMM instance ${i}'&&:; pwd; ./fixWindowAndDontStop.sh; ./runDarkMessiahOMM_Launcher.sh -${i}; done" && disown);fi
		#done
	#fi
	function FUNCrunInstance() {
		local liInstanceIndex=$1
		export bBashAutoCmdOnStart=false
		astrSECdevEnv=();if which secEnvDev.sh;then astrSECdevEnv=(secEnvDev.sh --clean);fi
		strEchoAlert="echo";if which echoc;then strEchoAlert="echoc --alert";fi
		strEchoWait="read -p";if which echoc;then strEchoAlert="echoc -w";fi
		acmd=("${astrSECdevEnv[@]}" bash -c "cd '${strGameInstallMainFolder}'; while true;do ${strEchoAlert} '$strWarnMsg'; ${strEchoWait} 'hit Enter to run DarkMessiahMM @{nul}Instance (${liInstanceIndex})@{-n-u-l}'&&:; pwd; ./fixWindowAndDontStop.sh; ./runDarkMessiahOMM_Launcher.sh -${liInstanceIndex}; done")
		set -x;"${acmd[@]}";set +x;
	};export -f FUNCrunInstance
	strFlFuncExec="$(mktemp)"
	type FUNCrunInstance |tail -n +2 >"$strFlFuncExec"
	for((i=1;i<=2;i++));do
		iInstanceIndex=$i
		if ! pgrep -fa DMMM_Run${iInstanceIndex};then
			#help @InfoID="[Run2instances]" Helper Script, will run 2 instances of the game for easy/quickly reloading a savegame, see bRunBothInstances
			if false;then #which guakeAutoEnv.sh;then
				set -x;(xterm -title DMMM_Run${iInstanceIndex} -e bash -c "source '$strFlFuncExec'; guakeAutoEnv.sh -ID_CMD game${iInstanceIndex} bash -c FUNCrunInstance ${iInstanceIndex};echoc -w -t 60 'Instance${iInstanceIndex}';" & disown);set +x
			else
				set -x;(xterm -title DMMM_Run${iInstanceIndex} -e bash -c "source '$strFlFuncExec'; FUNCrunInstance ${iInstanceIndex}; read -p PressEnterToEndInstance${iInstanceIndex} -t 60&&:;" & disown);set +x
			fi
		fi
	done
	FUNCtrash "$strFlFuncExec"
fi

##################

if which ScriptEchoColor;then
	echo "you may try to just drop_caches or remount, secOverrideMultiLayerMountPoint.sh helps on it too"
	read -n 1 -p "Umount?(y/...)" strResp;
	if [[ "${strResp}" == y ]];then
		cd "${strMainModFolder}/../"
		bSudoWithScript=true strUnionFSID=overlayfs secOverrideMultiLayerMountPoint.sh -u "Dark Messiah Might and Magic Single Player" #help @InfoID="secOverrideMultiLayerMountPoint.sh:UMOUNT" Helper Script, depends on ScriptEchoColor
	fi
fi
