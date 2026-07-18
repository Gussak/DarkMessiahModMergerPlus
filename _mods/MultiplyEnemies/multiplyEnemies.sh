#!/bin/bash

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

: ${strPathSDK:="${strPathParent}/Might and Magic Dark Messiah SDK"} #help 
: ${nMultiply:=10} #help hardcore

: ${strMultToken:="DupMultHC"} #help used to detect if already multiplied

strMapList="l02_b1,l02_b2" #help comma separated
mapfile -t -d ',' astrMapList < <(echo "$strMapList") 

for strMap in "${astrMapList[@]}";do
	strVmf="${strPathSDK}/mm_content/mapsrc/${strMap}.vmf"
	cp -v "$strVmf" "${strVmf}.$(date +'%Y_%m_%d-%H_%M_%S').bkp"
done
