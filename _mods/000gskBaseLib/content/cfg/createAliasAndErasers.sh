#!/bin/bash

#we cant ex.: alias gskHurtMeFUNC hurtme, then use gskHurtMeFUNC 3, it wont work
for((i=1;i<=100;i++));do
	echo "alias gskHurtme$(printf %03d $i) \"hurtme $i\""
done

# line limit is 1024 chars
function FUNCerasers() {
	local lstrEraser="alias gskHMHurtmeEraser1of3 \""
	for((i=$1;i<=$2;i++));do
		lstrEraser+="alias gskHurtme$(printf %03d $i);"
	done
	lstrEraser+="\""
	echo "$lstrEraser"
}
FUNCerasers 1 33
FUNCerasers 34 66
FUNCerasers 67 100
