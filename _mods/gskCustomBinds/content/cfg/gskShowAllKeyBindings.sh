#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

strFlCondump=""
while true;do
	sleep 1
	
	if ! strFlCondump="$(FUNCgetNewestCondump)";then
		echo -ne "$(date) Waiting first condump.\r"
		continue
	fi
	declare -p strFlCondump
	
	if ! egrep "KP_RIGHTARROW" "$strFlCondump";then
		echo "$(date) Waiting valid condump, use this on console: clear;key_listboundkeys;condump"
		continue
	fi
	
	break
done

#if false;then
	##LINUX_BASH_SCRIPT_HELPER: 
	#echo {a..z} {1..9} 0 "- = [ ] \ ' , . / ;" |tr ' ' '\n' |egrep -v "^$" |while read str;do if [[ -n "$str" ]];then echo "bind \"$str\"; ";fi; done
	##ISSUE: bind ";" cant be placed in an alias as there is no escape for ", so this fails: alias gskTmp "bind \";\""
#fi

#to generate the full list check: console: 
# clear;key_listboundkeys;condump
mapfile -t aBindList < <(
	echo '"MWHEELDOWN"'
	echo '"MWHEELUP"'
	echo '"PGUP"'
	echo '"PGDN"'
	echo '"HOME"'
	echo '"END"'
	echo '"INS"'
	echo '"DEL"'
	cat "${strFlCondump}" |awk '{print $1}'
	echo {1..12} |tr ' ' '\n' |sed -r -e 's@.*@"F&"@g'
	#echo {a..z} {0..9} "- = [ ] \ ' , . / ;" |tr ' ' '\n' |while read str;do echo "bind \"$str\"; ";done
	echo {a..z} {1..9} 0 "- = [ ] \ ' , . / ;" |tr ' ' '\n' |egrep -v "^$" |while read str;do if [[ -n "$str" ]];then echo "\"$str\"";fi; done
)
nTot="$(
for str in "${aBindList[@]}";do echo "bind $str; ";done |egrep -v "bind \"\"; " |sort -u |wc -l)"
for str in "${aBindList[@]}";do echo "bind $str; ";done |egrep -v "bind \"\"; " |sort -u |tr -d '\n' |sed -r -e "s@.*@&; echo \"Total=${nTot} AUTO GENERATED WITH $(basename "$0")\"@g"
echo

FUNCrefreshMount
