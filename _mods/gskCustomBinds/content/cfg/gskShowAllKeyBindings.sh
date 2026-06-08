#!/bin/bash

#LINUX_BASH_SCRIPT_HELPER: 
echo {a..z} {0..9} "- = [ ] \ ' , . / ;" |tr ' ' '\n' |while read str;do echo -n "bind $str; ";done
#ISSUE: bind ";" cant be placed in an alias as there is no escape for ", so this fails: alias gskTmp "bind \";\""
