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

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do pwd;cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

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
	function FUNCrunInstance() {
		local liInstanceIndex=$1
		declare -p liInstanceIndex
		FUNCecho() {
			if which ScriptEchoColor >/dev/null;then
				echoc "$@"
			else
				while [[ $# -gt 0 && ${1:0:1} == "-" ]];do shift;done # just ignore all params (bad trick..)
				echo "$1"
			fi
		}
		while true;do
			pwd
			FUNCecho --info "Run a 2nd instance for quick resume playing after death, as load game is super slow."
			FUNCecho --alert "[WAIT@{-n} THE other INSTANCE FINISH LOADING THE SAVEGAME OR BOTH may CRASH/FREEZE!!!]"
			FUNCecho -w -t 0.1 "[run Instance $liInstanceIndex] press Enter ('l' for quick loop, 'd' to drop caches)";read -n 1 strResp&&:
			: ${bRunStartCrashWorkaroundLoop:=false} #help allows a quick retry start loop (sometimes it is better others it is worse...)
			if [[ "$strResp" == [lL] ]];then bRunStartCrashWorkaroundLoop=true;fi
			if [[ "$strResp" == [dD] ]];then bash -c sync && sudo dd if=/proc/3/stat of=/proc/sys/vm/drop_caches bs=1 count=1; FUNCecho --say 'drop caches';fi
			if $bRunStartCrashWorkaroundLoop;then
				if FUNCaskYesNo "Startup crashing too much? try the quick loop?";then
					while true;do
						#./fixWindowAndDontStop.sh too slow just click normally
						strAutoLoad=forceIgnore ./runDarkMessiahOMM_Launcher.sh -${liInstanceIndex}
					done
				fi
			else
				./fixWindowAndDontStop.sh
				./runDarkMessiahOMM_Launcher.sh -${liInstanceIndex}
			fi
		done
	};export -f FUNCrunInstance
	for((i=1;i<=2;i++));do
		iInstanceIndex=$i
		if pgrep -fa DMMM_Run${iInstanceIndex};then continue;fi
		if which guakeAutoEnv.sh >/dev/null;then
			strFlExec="$(mktemp)";declare -p strFlExec
			echo "#!/bin/bash" >>"$strFlExec"
			echo "cd '${strGameInstallMainFolder}';" >>"$strFlExec"
			type FUNCaskYesNo |tail -n +2 >>"$strFlExec";echo >>"$strFlExec"
			type FUNCrunInstance |tail -n +2 >>"$strFlExec";echo >>"$strFlExec"
			echo "FUNCrunInstance ${iInstanceIndex};" >>"$strFlExec"
			echo "trash -v $strFlExec;" >>"$strFlExec"
			
			guakeAutoEnv.sh -ID_CMD game${iInstanceIndex} bash -c "chmod +x '${strFlExec}'; ls -l '${strFlExec}'; cat '${strFlExec}'; bBashAutoCmdOnStart=false secEnvDev.sh --clean bash -c '${strFlExec}'"
		else
			(xterm -title DMMM_Run${iInstanceIndex} -e bash -c "FUNCrunInstance ${iInstanceIndex}" & disown)
		fi
	done

	#function FUNCrunInstance() {
		#local liInstanceIndex=$1
		#if pgrep -fa DMMM_Run${iInstanceIndex};then return 0;fi
		
		#export bBashAutoCmdOnStart=false
		#astrSECdevEnv=();if which secEnvDev.sh;then astrSECdevEnv=(secEnvDev.sh --clean);fi
		#FUNCrunLoop() {
			#strWarnMsg="WAIT@{-n} THE other INSTANCE FINISH LOADING THE SAVEGAME OR BOTH may CRASH/FREEZE!!!"
			#astrEchoAlert=(echo   );if which echoc;then astrEchoAlert=(echoc --alert);fi
			#astrEchoWait=( read -p);if which echoc;then astrEchoWait=( echoc -w     );fi
			#while true;do
				#${astrEchoAlert[@]} "$strWarnMsg";
				#${astrEchoWait[@]}  "hit Enter to run DarkMessiahMM @{nul}Instance (${liInstanceIndex})@{-n-u-l}" && :
				#pwd
				#cd "${strGameInstallMainFolder}"
				#./fixWindowAndDontStop.sh
				#./runDarkMessiahOMM_Launcher.sh -${liInstanceIndex}
			#done
		#};export -f FUNCrunLoop
		#acmd=(
			#"${astrSECdevEnv[@]}" 
			#bash -c "FUNCrunLoop"
		#)
		#set -x;"${acmd[@]}";set +x;
	#};export -f FUNCrunInstance
	
	#astrFlFuncExec=()
	#astrFlFuncExec+=("$(mktemp)")
	#astrFlFuncExec+=("$(mktemp)")
	#type FUNCrunInstance |tail -n +2 >"${astrFlFuncExec[0]}"
	#type FUNCrunInstance |tail -n +2 >"${astrFlFuncExec[1]}"
	##help @InfoID="[Run2instances]" Helper Script, will run 2 instances of the game for easy/quickly reloading a savegame, see bRunBothInstances
	#for((i=1;i<=2;i++));do
		#FUNCrunInstance $i
	
		#iInstanceIndex=$i
			#strFlSrc="${astrFlFuncExec[$((iInstanceIndex-1))]}"
			#strBashScript="echo \"Loading Source: ${strFlSrc}\"; cat \"${strFlSrc}\"; source \"${strFlSrc}\"; trash -v \"${strFlSrc}\"; FUNCrunInstance ${iInstanceIndex}"
			#if which guakeAutoEnv.sh;then
				#set -x;(xterm -title DMMM_Run${iInstanceIndex} -e bash -c "guakeAutoEnv.sh -ID_CMD game${iInstanceIndex} bash -c \"${strBashScript}; echoc -w -t 60 Instance${iInstanceIndex}\"" & disown);set +x
				##set -x;guakeAutoEnv.sh -ID_CMD game${iInstanceIndex} bash -c "${strBashScript}; echoc -w -t 60 \"Instance${iInstanceIndex}\"";set +x
			#else
				#set -x;(xterm -title DMMM_Run${iInstanceIndex} -e bash -c "${strBashScript}; read -p \"PressEnterToEnd(Instance${iInstanceIndex})\" -t 60&&:" & disown);set +x
			#fi
		#fi
	#done
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
