#!/bin/bash

#we cant ex.: alias gskHurtMeFUNC hurtme, then use gskHurtMeFUNC 3, it wont work

# line limit is 1024 chars
function FUNCerasers() {
	local lstrMainEraser="$1";shift
	local lstrToEraseBN="$1";shift
	local lnFrom="$1";shift
	local lnTo="$1";shift
	
	local lstrEraser="alias ${lstrMainEraser} \""
	for((i=lnFrom;i<=lnTo;i++));do
		lstrEraser+="alias ${lstrToEraseBN}$(printf %03d $i);"
	done
	lstrEraser+="\""
	echo "$lstrEraser"
}

echo
for((i=1;i<=100;i++));do
	echo "alias gskHurtme$(printf %03d $i) \"hurtme $i\""
done
FUNCerasers "gskHMHurtmeEraser1of3" "gskHurtme" 1  33
FUNCerasers "gskHMHurtmeEraser2of3" "gskHurtme" 34  66
FUNCerasers "gskHMHurtmeEraser3of3" "gskHurtme" 67 100

################
echo
for((i=1;i<=10;i++));do
	echo "alias gskManaReg$(printf %03d $i) \"mm_player_time_to_add_mana 0.$(printf %02d $i)\""
done
FUNCerasers "gskManaRegEraser" "gskManaReg" 1 10
