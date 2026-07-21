Harder:
	Be careful what doors you forget opened.
	Tuffer enemies.
	Less arrows in quiver.
	You shall not be able to quickly kill most enemies thru simple combat, the idea is for all combat to be thematic like to have to throw them on water, on spikes, on fire, sneaky fiery arrow headshots etc.
	Tho it will have more powerful sneaky fiery arrow shots.
	Stronger kick tho consumes more stamina.

More Foes: (see createNpcSpawnSwitches.sh)
	Use f7 and f8 (see my keybinds mod to remap if you want) to place more 5 to 15 coherent enemies on current sector (before opening a gate or entering a tower, then repeat when you go thru), read more on cfg file.
	Tip, first time o map sector play it normally, reload, add 10-15 foes, replay hardcore.
	Foe placement tips: add about 3 near fireplaces, add foes looking at other foes to when you defeat one the other comes, add them in shadows and corners, add them looking at doors, add above in anywhere they can stand. Add inside: bathroom, small rooms, behind doors.
	You can still farm bowman arrows (that drop no quiver) if you use a shield and make them miss you and hit on wood.
	(TODO: edit map files to place a lot more of foes).

createNpcSpawnSwitches.sh -m:
	Slow: To 95% precisely add foes, move over the place, aim straight down hit F8.
	Fast: To 75% precisely add foes, aim anywhere that has enough area around hit F8. Is just to place a bunch of foes, because `getpos` will output a look at angle that is not precisely restored with `setang`.
	Before placing foes, type `clear;status;status` on console.
	To place foes use 'n' key for `+gskHelpPlaceNPCsToggleHelper` then F7 and F8 (tip: if no do a mistake send a command like "echo RemoveAbove2Foes" or a more specific message, then you can edit the condump.txt before running `createNpcSpawnSwitches.sh -m`).
	After finishing placing foes type `condump`.
	Running `./createNpcSpawnSwitches.sh -m` will read the newest condump.txt file and prepare a config file like "_mods/CarefulCombat/content/cfg/gskmap_L00.cfg" that can be applied hitting 'x' key.
	Load that file in console like: exec gskmap_L00
	Place each foe using 'x' key (on last one it stops placing them) (ISSUE: this may trigger area events..., how to prevent that??? spawn an undead at L00 to fix quest progression).

More power:
	Every spell with adrenaline is very powerful now to match enemies huge HP.

This tweak is only for hard mode, I won't balance it for easy mode.

ISSUE: during the combat at the dock with the ship, some necroguards are spawning with 35HP that is based in what? Seems hardcoded? like leanna with 900000hp first encounter... From console (developer 1; ent_text) they spawn with correct HP*HardDifficultyNPCLifeMul. There are also others spawning with correct HP there tho. just use F7 F8.
