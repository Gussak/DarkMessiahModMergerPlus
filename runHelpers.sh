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
		if pgrep -fa "DMMM_Helpers";then exit 0;fi
		(FUNCxterm -title DMMM_Helpers -e bash -c "while true;do ./${strSelfBN} --help; read -p PressEnterToRunHelpers&&:; bXtermAlready=true ./${strSelfBN};done" & disown)
		exit 0
	fi
fi

#set -x

if which ScriptEchoColor >/dev/null;then
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
(FUNCxterm -e ./createFunctionalBkp.sh & disown) #help @InfoID="createFunctionalBkp.sh" Helper Script, run once, create configs small backup

#cd "${strMainModFolder}/"
#./gitgui.sh #run once

cd "${strMainModFolder}/"
./quickBkp.sh #help @InfoID="quickBkp.sh" Helper Script, endless loop to backup quick.sav

cd "${strMainModFolder}/_mods/BloodySummoner/content/cfg/"
./createTeleportMarkers.sh #help @InfoID="createTeleportMarkers.sh" Helper Script, endless loop to create teleport markers

cd "${strGameInstallMainFolder}"
if FUNCfindBrokenSymlinks;then echo "${FUNCNAME[@]}:Ln$LINENO";exit 1;fi

cd "${strPathParent}"
if FUNCfindBrokenSymlinks;then
	echo "${FUNCNAME[@]}:Ln$LINENO"
	if ! FUNCaskYesNo "these may not cause trouble to run the game, continue anyway?";then
		exit 1
	fi
fi

cd "${strMainModFolder}/" # just to be sure...

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
			: ${bRunStartCrashWorkaroundLoop:=false} #help allows a quick retry start loop (sometimes it is better others it is worse...)
			: ${bAutoClickRun=true};export bAutoClickRun #help on ModLauncher run button, this is recognized by ./fixWindowAndDontStop.sh
			export bMMAutoConfigFlag=false
			while true;do
				bBreakQuestion=false
				FUNCecho --info "Run a 2nd instance for quick resume playing after death, as load game is super slow."
				FUNCecho --alert "[WAIT@{-n} THE other INSTANCE FINISH LOADING THE SAVEGAME OR BOTH may CRASH/FREEZE!!!]"
				FUNCecho -w -t 0.1 "[Instance $liInstanceIndex] press
	'Enter' to RUN,
	'a' auto click RUN (bAutoClickRun=$bAutoClickRun)
	'c' use once: mm.exe -autoconfig
	'l' for quick loop
	'p' restart pulseaudio (this breaks running instance audio)
	'r' refresh merged folder mount point (to grant changes will sync)
	't' trash files that may cause problems and can be recreated like user shader caches
"
				read -n 1 strResp&&:
				case "$strResp" in
					[aA])
						bAutoClickRun=false #help drop caches may help better tho
						;;
					[cC])
						bMMAutoConfigFlag=true #help mm.exe -autoconfig
						;;
					#[dD])
						#set -x;bash -c sync && sudo dd if=/proc/3/stat of=/proc/sys/vm/drop_caches bs=1 count=1;set +x;
						#FUNCecho --say 'drop caches';
						#;;
					[rR])
						FUNCrefreshMount # if it did not update, means OverlayFS needs refresing to sync with modified files.
						;;
					[lL])
						bRunStartCrashWorkaroundLoop=true #help drop caches may help better tho
						bBreakQuestion=true
						;;
					[pP])
						set -x;
						if ! systemctl --user restart pipewire pipewire-pulse;then
							pulseaudio -k && pulseaudio --start
						fi
						set +x;
						;;
					[tT])
						trash -v \
							~/.cache/mesa_shader_cache \
							~/.nv/ComputeCache/ \
							~/.nv/GLCache \
							~/.cache/nvidia/GLCache \
							"${strGameInstallMainFolder}/mm.dxvk-cache" \
							&&:
						;;
					"") # Enter key
						bBreakQuestion=true
						;;
					*)
						echo "not recognized option: strResp='$strResp'"
						;;
				esac
				if $bBreakQuestion;then break;fi
			done
			
			if $bRunStartCrashWorkaroundLoop;then
				if FUNCaskYesNo "Startup crashing too much? try the quick loop?";then
					while true;do
						#./fixWindowAndDontStop.sh too slow just click normally
						strAutoLoad=forceIgnore ./runDarkMessiahOMM_Launcher.sh -${liInstanceIndex}
						echo "press 'b' to break this mini quick loop";read -t 1 -n 1 strResp&&:;if [[ "$strResp" == [bB] ]];then break;fi
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
			(FUNCxterm -title DMMM_Run${iInstanceIndex} -e bash -c "FUNCrunInstance ${iInstanceIndex}" & disown)
		fi
	done
fi

##################

if which ScriptEchoColor >/dev/null;then
	echo "you may try to just drop_caches or remount, secOverrideMultiLayerMountPoint.sh helps on it too"
	read -n 1 -p "Umount?(y/...)" strResp;
	if [[ "${strResp}" == y ]];then
		cd "${strMainModFolder}/../"
		bSudoWithScript=true strUnionFSID=overlayfs secOverrideMultiLayerMountPoint.sh -u "Dark Messiah Might and Magic Single Player" #help @InfoID="secOverrideMultiLayerMountPoint.sh:UMOUNT" Helper Script, depends on ScriptEchoColor
	fi
fi
