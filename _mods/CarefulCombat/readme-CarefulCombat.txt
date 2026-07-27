Harder:
	Be careful what doors you forget opened.
	Tuffer enemies.
	Less arrows in quiver.
	You shall not be able to quickly kill most enemies thru simple combat, the idea is for all combat to be thematic like to have to throw them on water, on spikes, on fire, sneaky fiery arrow headshots etc.
	Tho it will have more powerful sneaky fiery arrow shots.
	Stronger kick tho consumes more stamina.

Add More Foes Yourself without preparing a backup: (or see createNpcSpawnSwitches.sh below)
	Use f7 and f8 (see my keybinds mod to remap if you want) to place more 5 to 15 coherent enemies on current sector (before opening a gate or entering a tower, then repeat when you go thru), read more on cfg file.
	Tip, first time in a map sector play it normally, reload, add 10-15 foes, replay hardcore.
	Foe placement tips: add about 3 near fireplaces, add foes looking at other foes to when you defeat one the other comes, add them in shadows and corners, add them looking at doors, add above in anywhere they can stand. Add inside: bathroom, small rooms, behind doors.
	You can still farm bowman arrows (that drop no quiver) if you use a shield and make them miss you and hit on wood.
	(TODO: edit map files to place a lot more of foes).

createNpcSpawnSwitches.sh -m: (or use the files I prepared see Using Pre-made files below)
	Slow: To 95% precisely add foes, move over the place, aim straight down hit F8.
	Fast: To 75% precisely add foes, aim anywhere that has enough area around hit F8. Is just to place a bunch of foes, because `getpos` will output a look at angle that is not precisely restored with `setang`.
	Before placing foes, type `clear;status;status` on console.
	To place foes use 'n' key for `+gskHelpPlaceNPCsToggleH`.
	IMPORTANT!!! fly around carefully to not trigger any events (the yellow boxes)!!!
	Then F7 and F8 (tip: if you do a mistake send a command like "rm1" (or rm2 etc rm2s1 (skip last 1 and remove the 2 above)) or a more specific message beggining with "rm", it is not a recognized command by the engine but the script will detect it. For now you can just edit the condump.txt with your hints before running `createNpcSpawnSwitches.sh -m`).
	After finishing placing foes type `condump`.
	Running `./createNpcSpawnSwitches.sh -m` will read the newest condump.txt file and prepare a config file like "_mods/CarefulCombat/content/cfg/gskmap_L00.cfg" that can be applied hitting 'x' key.
	Load that file in console like: exec gskmap_L00
	With gskHelpPlaceNPCsToggleHelper disabled, place each foe using 'x' key (on last one it stops placing them).

Using Pre-made files: (MoreFoes keys)
	Open console and type `status`, it will show the map name like "l02_b1".
	Now type: exec gskmap_l02_b1_01_GuestHouse_OK
	Obs.: Be careful to be in normal game mode, to have +gskHelpPlaceNPCsToggleHelper disabled, or it will mess the toggles (as we cant set them to ON or OFF, it is just the toggle of: buddha, noclip, notarget, ai_disable; so you can check if they are all normal by toggling again and that may get quite confusing requiring game app restart...)
	Now, in normal game mode press "MoreFoes: Create Next NPC" (gskCCnpcSpawn_next) to place each foe to fill that map area. Dont do it too fast, you will see the screen changing when you teleport, then press again.
	When done you will be teleported back to initial location as configured in that file.
	PS.: I was careful to fly around without triggering anything.

More power:
	Every spell with adrenaline is very powerful now to match enemies huge HP.

This tweak is only for hard mode, I won't balance it for easy mode.

ISSUE: during the combat at the dock with the ship, some necroguards are spawning with 35HP that is based in what? Seems hardcoded? like leanna with 900000hp first encounter... From console (developer 1; ent_text) they spawn with correct HP*HardDifficultyNPCLifeMul. There are also others spawning with correct HP there tho. just use F7 F8.
ISSUE: the necromancer above the bathroom is because it is impossibe to restore and auto place him inside it, the angle bug.

SelfNote: Vanilla total skill points to magic: 54 #strVFl="Dark Messiah Might and Magic Single Player.layer005.VanillaExtractedTextFiles.IGNORE_LAYER/mm/scripts/mm_skills_infos.txt";bc <<< "$(cat "${strVFl}" |egrep "magic|cost" |egrep -v "module|require|^//|\"(magic_2|magic_10)\"" |grep magic -A 1|grep cost |awk '{print $2}' |tr -d '"\r' |tr '\n' '+')0" #"
