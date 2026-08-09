#!/bin/bash

if false;then
	#LINUX_BASH_SCRIPT_HELPER: 
	echo {a..z} {0..9} "- = [ ] \ ' , . / ;" |tr ' ' '\n' |egrep -v "^$" |while read str;do if [[ -n "$str" ]];then echo "bind \"$str\"; ";fi; done
	#ISSUE: bind ";" cant be placed in an alias as there is no escape for ", so this fails: alias gskTmp "bind \";\""
fi

#to generate the full list check: console: 
# clear;key_listboundkeys;condump
mapfile -t aBindList < <(
	cat "${1-condump.txt}" |awk '{print $1}' |sed -r -e 's@.*@bind &; @g' # |tr -d '\n'
	#echo {a..z} {0..9} "- = [ ] \ ' , . / ;" |tr ' ' '\n' |while read str;do echo "bind \"$str\"; ";done
	echo {a..z} {0..9} "- = [ ] \ ' , . / ;" |tr ' ' '\n' |egrep -v "^$" |while read str;do if [[ -n "$str" ]];then echo "bind \"$str\"; ";fi; done
)
nTot="$(
for str in "${aBindList[@]}";do echo "$str";done |egrep -v "bind \"\"; " |sort -u |wc -l)"
for str in "${aBindList[@]}";do echo "$str";done |egrep -v "bind \"\"; " |sort -u |tr -d '\n' |sed -r -e "s@.*@& // Total=${nTot}@g"
