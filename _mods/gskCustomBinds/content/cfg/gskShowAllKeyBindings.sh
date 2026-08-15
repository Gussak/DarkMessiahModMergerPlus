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
	cat "${strFlCondump}" |awk '{print $1}' |sed -r -e 's@.*@bind &; @g' # |tr -d '\n'
	#echo {a..z} {0..9} "- = [ ] \ ' , . / ;" |tr ' ' '\n' |while read str;do echo "bind \"$str\"; ";done
	echo {a..z} {1..9} 0 "- = [ ] \ ' , . / ;" |tr ' ' '\n' |egrep -v "^$" |while read str;do if [[ -n "$str" ]];then echo "bind \"$str\"; ";fi; done
)
nTot="$(
for str in "${aBindList[@]}";do echo "$str";done |egrep -v "bind \"\"; " |sort -u |wc -l)"
for str in "${aBindList[@]}";do echo "$str";done |egrep -v "bind \"\"; " |sort -u |tr -d '\n' |sed -r -e "s@.*@&; echo \"Total=${nTot} AUTO GENERATED WITH $(basename "$0")\"@g"
