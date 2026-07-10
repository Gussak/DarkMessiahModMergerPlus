#!/bin/bash

astr=(
	#mm_npc_create_aratrok
	#mm_npc_create_cyclope
	#mm_npc_create_death_knight
	mm_npc_create_death_knight_shield
	mm_npc_create_ghoul
	mm_npc_create_goblin
	#mm_npc_create_human_guard
	#mm_npc_create_human_guard_bow
	#mm_npc_create_human_guard_shield
	#mm_npc_create_lich
	#mm_npc_create_lich_king
	#mm_npc_create_necro_guard
	mm_npc_create_necro_guard_bow # good because they wont drop arrows and wont make it easier
	#mm_npc_create_necro_guard_shield # this would drop the shield I guess
	mm_npc_create_necromancer
	#mm_npc_create_necromancer_lord
	#mm_npc_create_orc_sword
	mm_npc_create_orc_sword_bow
	#mm_npc_create_orc_sword_shield
	#mm_npc_create_servant_specter
	mm_npc_create_spider
	#mm_npc_create_spider_mini
	#mm_npc_create_undead
	#mm_npc_create_villager_undead
	#mm_npc_create_wizard
)

echo "${#astr[@]}"

function FUNCalias() {
	echo "alias gskCCnpcSwitch_${i} \"developer 1; echo CREATE:${str#mm_npc_create_}; alias gskCCnpcSpawn ${str}; alias +gskCCnpcSwitch gskCCnpcSwitch_${iNext}\""
}

for((i=0;i<${#astr[@]};i++));do
	str=${astr[$i]}
	iNext=$((i+1))&&:
	if(( i == (${#astr[@]}-1) ));then
		iNext=0
	fi
	FUNCalias
done
